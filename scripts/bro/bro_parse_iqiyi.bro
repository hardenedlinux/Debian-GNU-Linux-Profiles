@load base/frameworks/software


export {
    redef enum Software::Type += {
        SSL::IQIYI_APP,
        HTTP::IQIYI_APP,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local iqiyi: Software::Info;  

	if ( is_orig )
    {
   	 	if ( name == "HOST")
        {
			if (/iqiyi.com/ in value)
			{
				iqiyi=[$software_type = HTTP::IQIYI_APP, $host=c$id$orig_h, $unparsed_version="iqiyi-app"];
				Software::found(c$id, iqiyi);
		    }
        }
    }
}


event ssl_extension(c: connection, is_orig: bool, code: count, val: string) &priority=2
{
    local iqiyi:Software::Info;
    if (code == 0 && /iqiyi.com/ in val )
    {
        iqiyi = [$host=c$id$orig_h, $software_type = SSL::IQIYI_APP, $unparsed_version="iqiyi-app"];
        Software::found(c$id, iqiyi);
    }
}

