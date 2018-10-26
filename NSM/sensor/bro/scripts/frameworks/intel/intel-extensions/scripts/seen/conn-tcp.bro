##! This script adds <IP>:<Port> indicators for TCP connections.

@load base/frameworks/intel
@load policy/frameworks/intel/seen/where-locations

module Intel;

export {
	redef enum Intel::Type += {
		CONN_TCP
	};
}

event connection_established(c: connection)
	{
	if ( c$orig$state == TCP_ESTABLISHED &&
	     c$resp$state == TCP_ESTABLISHED )
		{
		Intel::seen([
			$indicator = cat(c$id$orig_h, ":", c$id$orig_p),
			$indicator_type = Intel::CONN_TCP,
			$where = Conn::IN_ORIG,
			$conn = c]);
		Intel::seen([
			$indicator = cat(c$id$resp_h, ":", c$id$resp_p),
			$indicator_type = Intel::CONN_TCP,
			$where = Conn::IN_RESP,
			$conn = c]);
		}
	}