sshd_audit_mux
==============

Replacement for ``ssllogmux`` script from `auditing-sshd
<https://code.google.com/p/auditing-sshd/>`_.  The major difference
being that instead of communicating to a `Bro <http://bro.org>`_ process
via an intermediate log file, it can directly send events via `Broccoli
<http://bro.org/sphinx/components/broccoli/broccoli-manual.html>`_
Python `bindings
<http://bro.org/sphinx/components/broccoli-python/README.html>`_.
