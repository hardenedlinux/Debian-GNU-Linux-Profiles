#! Logs processes activity.

module osquery::processes;

export {
        redef enum Log::ID += { LOG };

        type Info: record {
                t: time &log;
                host: string &log;
                pid: int &log;
                name: string &log;
		path: string &log;
		cmdline: string &log;
		cwd: string &log;
		root: string &log;
		uid: int &log;
		gid: int &log;
		on_disk: int &log;
		start_time: int &log;
		parent: int &log;
		pgroup: int &log;
        };
}

event host_processes(resultInfo: osquery::ResultInfo,
		pid: int, name: string, path: string, cmdline: string, cwd: string, root: string, uid: int, gid: int, on_disk: int, 
		start_time: int, parent: int, pgroup: int)
        {
        if ( resultInfo$utype != osquery::ADD )
                # Just want to log new process existance.
                return;

        local info: Info = [
		$t=network_time(),
		$host=resultInfo$host,
               	$pid = pid,
                $name = name,
                $path = path,
                $cmdline = cmdline,
                $cwd = cwd,
                $root = root,
                $uid = uid,
                $gid = gid,
                $on_disk = on_disk,
                $start_time = start_time,
                $parent = parent,
                $pgroup = pgroup
        ];

        Log::write(LOG, info);
        }

event bro_init()
        {
        Log::create_stream(LOG, [$columns=Info, $path="osq-processes"]);

        local query = [$ev=host_processes,$query="SELECT pid,name,path,cmdline,cwd,root,uid,gid,on_disk,start_time,parent,pgroup FROM processes"];
        osquery::subscribe(query);
        }
