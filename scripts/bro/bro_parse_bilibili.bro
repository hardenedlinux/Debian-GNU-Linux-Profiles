@load base/frameworks/software


export {
    redef enum Software::Type += {
        SSL::BILIBILI_APP,
        HTTP::BILIBILI_APP,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local bilibili: Software::Info;  

	if ( is_orig )
    {
   	 	if ( name == "USER-AGENT" )
        {
			if (/Bilibili/ in value)
			{
				bilibili=[$software_type = HTTP::BILIBILI_APP, $host=c$id$orig_h, $unparsed_version=value];
                Software::found(c$id, bilibili);
		    }
        }
    }
}


event ssl_extension(c: connection, is_orig: bool, code: count, val: string) &priority=2
{
    local bilibili:Software::Info;
    if (code == 0 && /bilibili.com/ in val)
    {
        bilibili = [$host=c$id$orig_h, $software_type = SSL::BILIBILI_APP, $unparsed_version = "bilibili"];
        Software::found(c$id, bilibili);
    }
}

