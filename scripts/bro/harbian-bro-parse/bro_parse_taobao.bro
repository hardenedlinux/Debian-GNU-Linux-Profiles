@load base/frameworks/software

export {
    redef enum Software::Type += {
        HTTP::TAOBAO_APP,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local taobao: Software::Info;  

	if ( is_orig )
    {
   	 	if ( name == "HOST")
        {
			if (/taobao.com/ in value)
			{
				taobao=[$software_type = HTTP::TAOBAO_APP, $host=c$id$orig_h, $unparsed_version="taobao-app"];
				Software::found(c$id, taobao);
		    }
        }
    }
}

