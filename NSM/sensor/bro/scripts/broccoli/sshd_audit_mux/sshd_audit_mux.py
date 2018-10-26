#! /usr/bin/env python

"""
.. module:: sshd_audit_mux
   :synopsis: Replacement for ssllogmux script from
        https://code.google.com/p/auditing-sshd/.  The major difference being
        that instead of communicating to a Bro process via an intermediate
        log file, it can directly send events via Broccoli's Python bindings.
   :dependencies: OpenSSL, pyev: https://pypi.python.org/pypi/pyev,
        libev: http://software.schmorp.de/pkg/libev.html,
        Broccoli w/ Python bindings: http://bro.org,
        Python 2.7.x

.. moduleauthor:: Jon Siwek <jsiwek@illinois.edu>

"""
# TODO: Python 3 compat.  It first requires changes in Broccoli bindings.

import errno
import logging, logging.handlers
import Queue
import signal
import socket
import ssl
import sys
import threading
import time
import traceback
import urllib

import broccoli
import pyev

# Equivalent to NERSCMSGBUF in instrumented SSHD code.
MAX_MSG_SIZE = 4096

logger = logging.getLogger(__name__)

s_audit_type_map = {
    "addr":         lambda str: broccoli.addr(str),
    "count":        lambda str: broccoli.count(str),
    "double":       lambda str: float(str),
    "int":          lambda str: int(str),
    "port":         lambda str: broccoli.port(str),
    "uristring":    lambda str: urllib.unquote_plus(str),
    # Some instrumented SSHD versions may have a "string" type for (e.g.)
    # session_request_direct_tcpip_3, but it's still URI encoded.
    "string":       lambda str: urllib.unquote_plus(str),
    "subnet":       lambda str: broccoli.subnet(str),
    "time":         lambda str: broccoli.time(str),
}

def s_audit_to_bro(type_, val):
    """Convert a string value from an instrumented SSHD to a Broccoli value.

    :param type: The type indicated by the instrumented SSHD.
    :param val: The string value to be converted.
    :returns: Broccoli's representation of the value or the original value
        if there was no known conversion.

    """
    if type_ not in s_audit_type_map:
        logger.error("received unkown audit message type: {0}".format(type_))
        return val

    return s_audit_type_map[type_](val)

def parse_s_audit_arg(arg):
    """Convert "type=value" arg from instrumented SSHD to Broccoli value.

    :param arg: A string that may be in "type=value" format.
    :returns: The string if no "type=" is present or the type was unknown, or
        the Broccoli representation of the value.

    """
    arg = arg.split('=', 1)

    if len(arg) == 1:
        return arg[0];

    return s_audit_to_bro(arg[0], arg[1])

def _CBExceptionHandler(func):
    """ Return a function meant for wrapping an object's pyev callback method.

    :param func: An object's pyev.Watcher callback method.  The object must
        have a method named ``stop`` which will be called if there's an
        unhandled exception in the callback method.

    """
    def wrap(obj, watcher, revents):
        """ Catch any exceptions from a pyev.Watcher's callback method.

        Since pyev event loops would just print warnings when callbacks
        return with an unhandled exception, we make sure to handle them here
        by logging it and calling a cleanup/stop method of the object.

        :param obj: The object that registed one of its methods as a callback.
            It must also have a method named ``stop``.
        :param watcher: A pyev.Watcher.
        :param revents: Events that triggered the watcher's callback.

        """
        try:
            func(obj, watcher, revents)
        except Exception:
            logger.exception("{0}: exception".format(obj))
            obj.stop()
    return wrap


class Worker(threading.Thread):

    """A thread which can process tasks designated by some other thread."""

    def __init__(self, tasks, shutdown_event, hup_event):
        """Initialize the worker thread.

        :param tasks: A Queue.Queue instance in which new tasks are placed.
        :param shutdown_event: A threading.Event instance set by another thread
            to indicate that this thread needs to finish soon.
        :param hup_event: A threading.Event instance set by another thread to
            indicate that a SIGHUP signal was received.

        """
        super(Worker, self).__init__()
        self._tasks = tasks
        self._shutdown_event = shutdown_event
        self._hup_event = hup_event
        # Daemon mode set just in case there's a way the main/server thread's
        # shutdown event can fail, which would leave this thread spinning.
        self.daemon = True

    def run(self):
        """Process tasks designated by another thread until shutdown event."""
        while not self._shutdown_event.is_set():
            task = self.next_task(True, 0.5)
            self.process_task(task)
            if task is not None:
                self._tasks.task_done()
            if self._hup_event.is_set():
                self.handle_hangup()
                self._hup_event.clear()

        logger.debug("'{0}' got thread shutdown event".format(self.name))

        while not self._tasks.empty():
            task = self.next_task()
            self.process_task(task, True)
            if task is not None:
                self._tasks.task_done()

        self.finish()

        logger.debug("'{0}' thread exiting".format(self.name))

    def handle_hangup(self):
        """Handle a SIGHUP signal reported by the main thread.

        Subclasses may override this to perform specific actions on receiving
        a SIGHUP signal.  E.g. truncate a log file.

        """
        pass

    def next_task(self, block=False, timeout=None):
        """Retrieve next task to process.

        :param block: Whether the this method should block waiting for a task
            if there were none available.
        :param timeout: A floating point number giving the maximum number of
            seconds to wait if ``block`` is True.  A value of None blocks until
            a task is ready.
        :returns: The next task awaiting processing or None.

        """
        try:
            return self._tasks.get(block, timeout)
        except Queue.Empty:
            return None

    def process_task(self, task, terminating=False):
        """Process a single task.

        Subclasses should override this method to implement specific task
        processing routines.

        :param task: The task in need of processing.  Its value is either None
            or a string containing a complete message received by the server.
        :param terminating: Whether the thread is in the process of shutting
            down.  If True, this method should avoid expensive/long operations.

        """
        pass

    def finish(self):
        """Called immediately before the thread's ``run()`` routine returns.

        Subclasses may override to do any necessary cleanup.

        """
        pass


class BroccoliWorker(Worker):

    """Emits a Broccoli event per task and optionally logs it to a file."""

    def __init__(self, tasks, shutdown_event, hup_event,
                 bro_peer="localhost:47757", log_path=None):
        """Initialize the worker thread.

        Connects to a Bro peer process and optionally opens a log file.

        :param tasks: A Queue.Queue instance in which new tasks are placed.
        :param shutdown_event: A threading.Event instance set by another thread
            to indicate that this thread needs to finish soon.
        :param hup_event: A threading.Event instance set by another thread to
            indicate that a SIGHUP signal was received.
        :param bro_peer: A string in "host:port" format specifying how
            to connect to a Bro process.
        :param log_path: A string representing a path to a file which will
            log all complete messages from clients.
        :raises: IOError if a Broccoli connection cannot be established

        """
        super(BroccoliWorker, self).__init__(tasks, shutdown_event, hup_event)
        self._log_path = None
        self._log_file = None
        if log_path is not None:
            self._log_path = log_path
            self._log_file = open(log_path, "w")
            logger.info("opened log file: {0}".format(self._log_path))
        self._bc = broccoli.Connection(bro_peer)

    def _send_event(self, task):
        """Parse the task in to a Broccoli event and send it.

        :param task: A complete audit message string.

        """
        args = map(parse_s_audit_arg, filter(None, task.split(' ')))
        if args[0] == "channel_notty_analysis_disable_3" and len(args) == 7:
            # Older SSHDs may not include channel argument, add a dummy.
            args.insert(5, broccoli.count(0))
        self._bc.send(*args)

    def process_task(self, task, terminating=False):
        """Process a single task.

        Sends an Broccoli event related to the task to the Bro peer process
        and optionally logs it to a file.

        :param task: The task in need of processing.  Its value is either None
            or a string containing a complete message received by the server.
        :param terminating: Whether the thread is in the process of shutting
            down.  If True, this method should avoid expensive/long operations.

        """
        super(BroccoliWorker, self).process_task(task, terminating)
        if task is not None:
            if self._log_file is not None:
                self._log_file.write("{0}\n".format(task))
            self._send_event(task)
            logger.debug("processed task '{0}'".format(task))
        self._bc.processInput()

    def handle_hangup(self):
        """Closes the current log file and re-opens it.

        This can be used as a log rotation mechanism.  E.g. move/rename the
        log file and then send the Server process a SIGHUP.

        """
        if self._log_file is None:
            return
        logger.info("got SIGHUP, re-open log: {0}".format(self._log_path))
        self._log_file.close()
        self._log_file = open(self._log_path, "w")

    def finish(self):
        """Close connection with Bro peer and the log file."""
        if self._log_file is not None:
            self._log_file.close()
            logger.info("closed log file: {0}".format(self._log_path))
        start = time.time()
        while self._bc.processInput():
            # Try to flush any remaining events.
            if time.time() - start > 5.0:
                logger.warning("terminated before broccoli events flushed")
                break;


class Client(object):

    """A client connection using a non-blocking socket and optional SSL.

    As a base class, it can only receive data over the socket and does nothing
    with it.  Subclasses may implement more complex protocols.

    """

    def __init__(self, sock, address, ssl_config, loop, server):
        """Initialize the client socket.

        :param sock: A socket object returned from server's accept() call.
        :param address: Client's address as returned by server's accept() call.
        :param ssl_config: A dictionary containing keyword arguments for
            ssl.wrap_socket().  An empty dictionary will disable SSL.
        :param loop: A pyev.Loop object that will handle signals and I/O.
        :param server: The Server instance which created this client instance.
        :raises: ssl.SSLError when failing to SSL wrap the socket

        """
        self._sock = sock
        self._address = address
        self._server = server
        self._sock.setblocking(0)

        if ssl_config:
            try:
                self._sock = ssl.wrap_socket(self._sock, **ssl_config)
            except ssl.SSLError:
                logger.exception("refused {0}: SSL socket wrap error ".format(
                                                                self._address))
                self._sock.close()
                raise
            else:
                self._sock.setblocking(0)

        self._read_watcher = pyev.Io(self._sock, pyev.EV_READ, loop,
                                     self._read_handler)
        self._write_watcher = pyev.Io(self._sock, pyev.EV_WRITE, loop,
                                      self._write_handler)
        self._timeout_watcher = pyev.Timer(server.timeout, server.timeout,
                                           loop, self._timeout_handler)
        self._read_watcher.start()
        self._timeout_watcher.reset()

    def __str__(self):
        return "{0} {1}".format(self.__class__.__name__, self._address)

    def stop(self, msg="close active connection from {0}"):
        """Stop watching for data on socket and close it.

        :param msg: A template string to use for logging.  It may use ``{0}``
            for client address substitutions.

        """
        try:
            self._sock.close()
        except socket.error:
            logger.exception("client close error {0}".format(self._address))

        self._timeout_watcher.repeat = 0.0;
        self._timeout_watcher.reset()
        self._read_watcher.stop()
        self._write_watcher.stop()
        self._read_watcher = self._write_watcher = self._timeout_watcher = None;
        self._server.unregister(self._address)
        logger.info(msg.format(self._address))

    def _handle_ssl_exception(self, err):
        """Return whether an ssl.SSLError exception could not be handled.

        :param err: An ssl.SSLError exception.
        :returns bool: True if the exception could not be handled, else False.

        """
        if err.args[0] == ssl.SSL_ERROR_WANT_READ:
            logger.debug("SSL client {0} want read".format(self._address))
            return False
        elif err.args[0] == ssl.SSL_ERROR_WANT_WRITE:
            logger.debug("SSL client {0} want write".format(self._address))
            self._write_watcher.start()
            return False
        elif err.args[0] == ssl.SSL_ERROR_EOF:
            self.stop(msg="SSL EOF for peer {0}, connection closed")
            return False
        else:
            return True

    def _read(self):
        """Read data on the socket.

        :raises: ssl.SSLError, socket.error

        """
        try:
            buf = self._sock.recv(MAX_MSG_SIZE)
        except ssl.SSLError as err:
            if self._handle_ssl_exception(err):
                raise
        except socket.error as err:
            if err.args[0] not in (errno.EAGAIN, errno.EWOULDBLOCK):
                raise
        else:
            if buf:
                self._timeout_watcher.reset()
                self._deliver_stream(buf)
            else:
                self.stop(msg="connection closed by peer {0}")

    @_CBExceptionHandler
    def _read_handler(self, watcher, revents):
        """Handles incoming data on the socket.

        :param watcher: The pyev.Watcher that triggered this callback.
        :param revents: The event(s) that triggered the callback.
        :raises: ssl.SSLError, socket.error

        """
        assert (revents & pyev.EV_READ) and not (revents & pyev.EV_ERROR)
        self._read()

    @_CBExceptionHandler
    def _write_handler(self, watcher, revents):
        """Handles outgoing data on the socket.

        This should only ever happen if a read operation raised
        ssl.SSL_ERROR_WANT_WRITE.  In that case, just retry the read.

        :param watcher: The pyev.Watcher that triggered this callback.
        :param revents: The event(s) that triggered the callback.
        :raises: ssl.SSLError, socket.error

        """
        self._write_watcher.stop()
        self._read()

    @_CBExceptionHandler
    def _timeout_handler(self, watcher, revents):
        """Handles timeouts of stale sockets.

        :param watcher: The pyev.Watcher that triggered this callback.
        :param revents: The event(s) that triggered the callback.

        """
        self.stop(msg="drop stale connection {0}")

    def _deliver_stream(self, buf):
        """Children may override this to handle data received over socket.

        :param buf: string of data read from socket.

        """
        pass


class SSHDAuditMuxClient(Client):

    """Client that handles data received from an instrumented SSHD."""

    def __init__(self, sock, address, ssl_config, loop, server):
        """Initialize the client socket.

        :param sock: A socket object returned from server's accept() call.
        :param address: Client's address as returned by server's accept() call.
        :param ssl_config: A dictionary containing keyword arguments for
            ssl.wrap_socket().  An empty dictionary will disable SSL.
        :param loop: A pyev.Loop object that will handle signals and I/O.
        :param server: The Server instance which created this client instance.

        """
        super(SSHDAuditMuxClient, self).__init__(sock, address, ssl_config,
                                                 loop, server)
        self._data = ""

    def stop(self, msg="close active connection from {0}"):
        """Stop watching for data on socket and close it.

        :param msg: A template string to use for logging.  It may use ``{0}``
            for client address substitutions.

        """
        super(SSHDAuditMuxClient, self).stop(msg)
        if self._data:
            logger.debug("audit client {0} stop w/ partial msg: {1}".format(
                                                    self._address, self._data))

    def _deliver_stream(self, buf):
        """Handle any complete messages and buffer any partial ones.

        :param buf: A string of received data.

        """
        self._data += buf
        if ( len(self._data) >= MAX_MSG_SIZE and
             self._data[:MAX_MSG_SIZE-1].rfind('\n') == -1 ):
            truncated_msg = self._data[:MAX_MSG_SIZE-1]
            logger.warning("recv'd truncated msg: '{0}'".format(truncated_msg))
            self._handle_msg(truncated_msg)
            self._data = self._data[MAX_MSG_SIZE-1:]
        idx = self._data.rfind('\n')
        if idx == -1:
            return
        msg_list = filter(None, self._data[:idx+1].split('\n'))
        self._data = self._data[idx+1:]
        for m in msg_list:
            self._handle_msg(m)

    def _handle_msg(self, msg):
        """Create a new task for a worker thread to process.

        :param msg: A complete message on which a task can be based.

        """
        logger.debug("audit client {0} got msg '{1}'".format(self._address,
                                                             msg))
        self._server.add_task(msg)


class Server(object):

    """A non-blocking socket server with optional SSL support."""

    def __init__(self, client_class, thread_factory, ssl_config, loop, address,
                 timeout):
        """Initialize the socket server.

        :param client_class: Type of client which handles accepted connections.
        :param thread_factory: A callable which returns an instance of a Worker
            a subclass.  The arguments to the callable are a Queue.Queue
            instance for sharing tasks, a threading.Event instance for shutdown
            signals, and a threading.Event instance for SIGHUP signals
        :param ssl_config: A dictionary containing keyword arguments for
            ssl.wrap_socket().  An empty dictionary will disable SSL.
        :param loop: A pyev.Loop object that will handle signals and I/O.
        :param address: The address and port on which to bind and listen for
            connections.
        :type address: a ``(host, port)`` tuple for IPv4 and a
            ``(host, port, flowinfo, scopeid)`` tuple for IPv6 where ``host``
            is a string representing a host/domain name or a numeric address
            and ``port`` is an integer representing a TCP port.
        :param timeout: number of seconds after which a stale client connection
            is dropped.

        """
        self.timeout = timeout
        self._client_class = client_class
        self._thread_factory = thread_factory
        self._ssl_config = ssl_config
        self._loop = loop
        self._address = address
        self._sock = None
        self._clients = {}
        self._HANDLED_SIGNALS = (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)
        self._watchers = []
        self._worker_thread = None
        self._tasks = Queue.Queue()
        self._shutdown_event = threading.Event()
        self._hup_event = threading.Event()

    def __str__(self):
        return "{0} {1}".format(self.__class__.__name__, self._address)

    def _prepare(self):
        """Initialize server components which ``stop()`` may render invalid.

        :raises: socket.error on failure to create, or bind on socket.

        """
        self._sock = socket.socket()
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.setblocking(0)
        self._sock.bind(self._address)
        self._watchers = [pyev.Signal(sig, self._loop, self._signal_handler)
                          for sig in self._HANDLED_SIGNALS]
        self._watchers.append(pyev.Io(self._sock, pyev.EV_READ, self._loop,
                                      self._socket_handler))
        self._worker_thread = self._thread_factory(self._tasks,
                                                   self._shutdown_event,
                                                   self._hup_event)

    def start(self):
        """Start listening for client connections.

        :raises: socket.error on failure to create, bind, or listen on socket.

        """
        self._prepare()
        self._worker_thread.start()
        self._sock.listen(socket.SOMAXCONN)
        logger.info("start listening on {0} w/ SSL config: {1}".format(
                                            self._address, self._ssl_config))

        for w in self._watchers:
            w.start()

        self._loop.start()

    def stop(self):
        """Stop accepting connections and terminate existing ones.

        Drops any client messages that couldn't be timely processed.

        """
        self._loop.stop(pyev.EVBREAK_ALL)
        logger.info("stop listening on {0}".format(self._address))

        try:
            self._sock.close()
        except socket.error:
            logger.exception("server close error: {0}".format(self._address))

        while self._watchers:
            self._watchers.pop().stop()

        for c in self._clients.values():
            c.stop()

        self._clients.clear()

        self._shutdown_event.set()
        self._worker_thread.join()

        self._worker_thread = None
        self._shutdown_event.clear()
        self._hup_event.clear()

        while not self._tasks.empty():
            task = self._tasks.get()
            logger.error("dropped unprocessed task '{0}'".format(task))
            self._tasks.task_done()

        logger.info("server stopped")

    def unregister(self, address):
        """Unregister a client connection.

        :param address: An address to remove from table of current clients.

        """
        if address not in self._clients:
            logger.warning("unregister unknown client {0}".format(address))
        else:
            del self._clients[address]

    def add_task(self, task):
        """Make a new task ready for a thread to process.

        :param task: The task in need of processing.

        """
        try:
            self._tasks.put_nowait(task)
        except Queue.Full:
            # This shouldn't happen with an unbounded queue
            logger.exception("failed to queue task '{0}'".format(task))

    @_CBExceptionHandler
    def _signal_handler(self, watcher, revents):
        """Handle signals defined in self._HANDLED_SIGNALS.

        :param watcher: The pyev.Watcher that triggered this callback.
        :param revents: The event(s) that triggered the callback.

        """
        assert (revents & pyev.EV_SIGNAL) and not (revents & pyev.EV_ERROR)

        if watcher.signum == signal.SIGHUP:
            self._hup_event.set()
        else:
            self.stop()

    @_CBExceptionHandler
    def _socket_handler(self, watcher, revents):
        """Accept new client connections.

        :param watcher: The pyev.Watcher that triggered this callback.
        :param revents: The event(s) that triggered the callback.
        :raises: socket.error if there's an error accepting a connection.

        """
        assert (revents & pyev.EV_READ) and not (revents & pyev.EV_ERROR)

        # Try to accept as many connections as possible.
        while self._accept():
            pass

    def _accept(self):
        """Try to accept a new client connection.

        :returns bool: True if a connection was successfully accepted.
        :raises: socket.error if there's an error accepting a connection.

        """
        try:
            client_sock, client_address = self._sock.accept()
        except socket.error as err:
            if err.args[0] in (errno.EAGAIN, errno.EWOULDBLOCK):
                return False
            if err.args[0] in (errno.ENFILE, errno.EMFILE):
                logger.warning("refused connection due to fd overload")
                return False
            else:
                raise
        else:
            logger.info("accept concurrent connection #{0} from {1}".format(
                                        len(self._clients), client_address))
            try:
                client = self._client_class(client_sock, client_address,
                                            self._ssl_config, self._loop, self)
            except ssl.SSLError:
                # Client ctor does logging & socket cleanup.
                return False
            else:
                self._clients[client_address] = client

        return True


if __name__ == "__main__":
    from optparse import OptionParser
    p = OptionParser()
    p.add_option("-d", "--debug", action="store_true", default=False,
                 help="enable debug level logging")
    p.add_option("-a", "--addr", type="string", default="",
                 help=("listen on given address (numeric IP or host name), "
                       "an empty string (the default) means INADDR_ANY"))
    p.add_option("-p", "--port", type="int", default=7999,
                 help="listen on given TCP port number")
    p.add_option("-c", "--cert", type="string", metavar="FILE",
                 help="path to SSL certificate w/ optional private key")
    p.add_option("-k", "--key", type="string", metavar="FILE",
                 help="path to SSL private key")
    p.add_option("-o", "--out", type="string", default=None, metavar="FILE",
                 help="write all complete messages from clients to a file")
    p.add_option("-l", "--log", type="string", default=None, metavar="FILE",
                 help="send error/info/debug logs to a file")
    p.add_option("-b", "--bro", type="string", default="localhost:47757",
                 metavar="ADDR:PORT",
                 help="address and port of a listening Bro process")
    p.add_option("-t", "--timeout", type="int", default=3600,
                 help=("drop stale connections after given number of seconds, "
                       "with 0 meaning never drop connections"))
    options, args = p.parse_args()

    if options.debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)

    formatter = logging.Formatter("%(asctime)s %(levelname)-8s %(message)s")

    if options.log is not None:
        handler = logging.handlers.WatchedFileHandler(options.log)
    else:
        handler = logging.StreamHandler()

    handler.setFormatter(formatter)
    logger.addHandler(handler)

    logging.captureWarnings(True)

    def hook(*exc_info):
        traceback.print_exception(*exc_info)
        logger.critical("Unhandled exception", exc_info=exc_info)

    sys.excepthook = hook

    if ( (options.key is not None and options.cert is None) or
         (options.key is None and options.cert is None) ):
        logger.critical("An SSL certificate and private key must be provided")
        sys.exit(1)

    ssl_config = dict(
        keyfile=options.key,
        certfile=options.cert,
        server_side=True,
        cert_reqs=ssl.CERT_NONE,
        ssl_version=ssl.PROTOCOL_SSLv23, # Maximum compatibility.
        ca_certs=None,
        do_handshake_on_connect=False,
        suppress_ragged_eofs=False,
        ciphers=None
    )

    def thread_factory(tasks, shutdown_event, hup_event):
        return BroccoliWorker(tasks, shutdown_event, hup_event,
                              options.bro, options.out)

    server = Server(SSHDAuditMuxClient, thread_factory, ssl_config,
                    pyev.default_loop(), (options.addr, options.port),
                    options.timeout)
    p.destroy()
    server.start()
