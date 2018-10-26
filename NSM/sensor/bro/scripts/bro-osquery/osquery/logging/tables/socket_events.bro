#! Logs processes activity.

module osquery::socket_events;

export {
        redef enum Log::ID += { LOG };

        type Info: record {
                t: time &log;
                host: string &log;
                action: string &log;
                pid: int &log;
                path: string &log;
                family: int &log;
                protocol: int &log;
                local_address: addr &log;
                remote_address: addr &log;
                local_port: int &log;
                remote_port: int &log;
		start_time: int &log;
		success: int &log;
        };
}

event host_socket_event(resultInfo: osquery::ResultInfo,
		action: string, pid: int, path: string, family: int, protocol: int, local_address: string, remote_address: string, local_port: int, remote_port: int, start_time: int, success: int)
        {
        if ( resultInfo$utype != osquery::ADD )
                # Just want to log new process existance.
                return;

        if (action == "connect" || local_address == "") {
          local_address = "0.0.0.0";
        }
        if (action == "bind" || remote_address == "") {
          remote_address = "0.0.0.0";
        }

        local info: Info = [
		$t=network_time(),
		$host=resultInfo$host,
                $action = action,
               	$pid = pid,
                $path = path,
                $family = family,
                $protocol = protocol,
                $local_address = to_addr(local_address),
                $remote_address = to_addr(remote_address),
                $local_port = local_port,
                $remote_port = remote_port,
                $start_time = start_time,
                $success = success
        ];

        Log::write(LOG, info);
        }

event bro_init()
        {
        Log::create_stream(LOG, [$columns=Info, $path="osq-socket_events"]);

        local query = [$ev=host_socket_event,$query="SELECT action, pid, path, family, protocol, local_address, remote_address, local_port, remote_port, time, success FROM socket_events"];
        osquery::subscribe(query);
        }
