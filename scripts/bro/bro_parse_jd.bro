@load base/frameworks/software


export {
    redef enum Software::Type += {
        SSL::JD_APP,
        HTTP::JD_MOBILE,
    };
    redef record Software::Info += {
        o_host: addr &optional &log;
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=2
{
	local jd1: Software::Info;

	if ( is_orig )
    {
   	 	if ( name == "USER-AGENT" )
        {
			if (/jdapp/ in value && /network\/wifi/ in value)
			{
                		Software::found(c$id, [$unparsed_version="", $host=c$id$resp_h, $o_host=c$id$orig_h, $host_p=c$id$resp_p, $software_type=HTTP::JD_MOBILE]);
			}
        }
    }
}

event ssl_extension(c: connection, is_orig: bool, code: count, val: string) &priority=2
{
    local jd:Software::Info;
    if (code == 0 && /jd.com/ in val)
    {
        jd = [$host=c$id$orig_h, $software_type = SSL::JD_APP, $unparsed_version = ""];
        Software::found(c$id, jd);
    }
}

