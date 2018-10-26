#! Logs mounts activity.

module osquery::mounts;

export {
	redef enum Log::ID += { LOG };

	type Info: record {
		t: time &log;
		host: string &log;
		device: string &log;
		device_alias: string &log;
		path: string &log;
		typ: string &log;
		blocks_size: int &log;
		blocks: int &log;
		flags: string &log;
	};
}

event host_mounts(resultInfo: osquery::ResultInfo,
		device: string, device_alias: string, path: string, typ: string,
		blocks_size: int, blocks: int, flags: string)
	{
	if ( resultInfo$utype != osquery::ADD )
		# Just want to log new mount existance.
		return;
	
	local info: Info = [
			 $t=network_time(),
			 $host=resultInfo$host,
                      $device = device,
                      $device_alias = device_alias,
                      $path = path,
                      $typ = typ,
                      $blocks_size = blocks_size,
                      $blocks = blocks,
                      $flags = flags
			               ];
	
	Log::write(LOG, info);
	}

event bro_init()
	{
	Log::create_stream(LOG, [$columns=Info, $path="osq-mounts"]);

	local ev = [$ev=host_mounts,$query="SELECT device,device_alias,path,type,blocks_size,blocks,flags FROM mounts"];
	osquery::subscribe(ev);
	}
