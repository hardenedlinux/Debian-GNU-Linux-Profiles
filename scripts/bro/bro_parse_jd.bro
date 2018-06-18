@load base/frameworks/software

export {
    redef enum Software::Type += {
        SSL::JD_APP,
        HTTP::JD_MOBILE,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=2
{
	local jd1: Software::Info;

	if ( is_orig )
    {
   	 	if ( name == "USER-AGENT" )
        {
			# Get weibo app's version  
			# example: value = MX6_6.0_weibo_8.6.0_android_wifi
			if (/jdapp/ in value && /network\/wifi/ in value)
			{
                		Software::found(c$id, [$unparsed_version="", $host=c$id$resp_h, $host_p=c$id$resp_p, $software_type=HTTP::JD_MOBILE]);
			}
        }
    }
}

event ssl_extension(c: connection, is_orig: bool, code: count, val: string) &priority=3
{
    local jd:Software::Info;
    if (code == 0 && /jd.com/ in val)
    {
        jd = [$host=c$id$orig_h, $software_type = SSL::JD_APP, $unparsed_version = ""];
        Software::found(c$id, jd);
    }
}

