#! Logs processes activity.

module osquery::process_events;

export {
        redef enum Log::ID += { LOG };

        type Info: record {
                t: time &log;
                host: string &log;
                pid: int &log;
		path: string &log;
		cmdline: string &log;
		cwd: string &log;
		uid: int &log;
		gid: int &log;
		start_time: int &log;
		parent: int &log;
        };
}

event host_process_event(resultInfo: osquery::ResultInfo,
		pid: int, path: string, cmdline: string, cwd: string, uid: int, gid: int,
		start_time: int, parent: int)
        {
        if ( resultInfo$utype != osquery::ADD )
                # Just want to log new process existance.
                return;

        local info: Info = [
		$t=network_time(),
		$host=resultInfo$host,
               	$pid = pid,
                $path = path,
                $cmdline = cmdline,
                $cwd = cwd,
                $uid = uid,
                $gid = gid,
                $start_time = start_time,
                $parent = parent
        ];

        Log::write(LOG, info);
        }

event bro_init()
        {
        Log::create_stream(LOG, [$columns=Info, $path="osq-process_events"]);

        local query = [$ev=host_process_event,$query="SELECT pid,path,cmdline,cwd,uid,gid,time,parent FROM process_events"];
        osquery::subscribe(query);
        }
