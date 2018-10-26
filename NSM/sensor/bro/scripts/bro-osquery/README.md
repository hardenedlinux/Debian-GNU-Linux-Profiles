# The Bro-Osquery Project #
This extension adds a Bro interface to the host monitor [osquery](https://osquery.io), enabling the network monitor [Bro](https://www.bro.org) to subscribe to changes from hosts as a continous stream of events. The extension is controlled from Bro scripts, which sends SQL-style queries to the hosts and then begins listening for any updates coming back. Host events are handled by Bro scripts the same way as network events.

Here, you see an example script to be loaded by Bro, using osquery and our bro-osuqery framework to make hosts report about server applications as soon as it starts.
```
event host_server_apps(resultInfo: osquery::ResultInfo,
	        username: string, name: string, port_number: int)
{
  print fmt("[Host %s] User '%s' is running server application '%s' on port %d", resultInfo$host, username, name, port_number);
}

event bro_init()
{
  Broker::enable();

  local query = [$ev=host_server_apps, $query="SELECT u.username, p.name, l.port from listening_ports l, users u, processes p WHERE l.pid=p.pid AND p.uid=u.uid and l.address NOT IN ('127.0.0.1', '::1')"];
  osquery::subscribe(query);
}
```

## Overview ##
Bro-Osquery is a platform for infrastructure monitoring, combining network and host monitoring. Bro is used to capture, log and analyze network packets. To retrieve information of hosts in the network, there is the osquery agent running on hosts. Osquery can be instrumented by Bro to send information about software and hardware changes.

Both types of events, from network and hosts, are transparently handled with Bro scripts. We provide an easy to use interface in Bro to manage groups of hosts and to subscribe to host status changes.

## Installation ##
For the Bro-Osquery Project to run, you need to deploy **Osquery** on respective hosts to be monitored. Additionally, **Bro** has to be loaded with the **osquery framework script** to enable the communication with the hosts.

**Bro** needs to be installed from source to include development features required by bro-osquery.
Then, the **Bro Script Framework** needs to be installed.

**Osquery** is originally a standalone host monitor and does not include the Bro plugins yet. Hence, bro-osquery cannot currently be used with the official osquery binaries. Use our customized osquery instead.

For detailed installation instructions please refer to the [installation guide](https://github.com/bro/bro-osquery/blob/master/install_guide.md).

## Deployment ##

Once you installed Bro and placed the osquery framework, start Bro with the scripts, e.g.:

	bro -i <interface_name> osquery

or run Bro in background (after enabling the osquery framework):

    broctl deploy


Once you installed the bro-featured osquery, you can start daemon and the bro plugins:

	sudo osqueryd --disable-distributed=false --distributed_interval=0 --distributed_plugin bro --bro-ip="<bro-ip>" --logger_plugin bro --log_result_events=0

Please make sure that the *bro-ip* matches the Bro installation running the osquery framework.

Additional command line flags in osquery that might be useful when running bro-osquery:

      --verbose                Verbose osquery output
      --config_plugin update   Initial config from commandline only
      --disable_events=0       Enable event-based tables
      --disable_audit=0        Enable audit as event publisher (make sure auditd is not running)
      --audit_persist=1        Persistently controllig audit while running
      --audit_allow_config=1   More power to control audit
      --audit_allow_sockets=1  Include socket-related syscalls in audit

Osquery related logfiles are written to the Bro log directory. Depending on the enabled osquery scripts, you should be able to see Bro logfiles named osq-processes.log and osq-mounts.log.
