@load base/frameworks/software


export {
    redef enum Software::Type += {
        SSL::GAODEMAP_APP,
        HTTP::GAODEMAP_APP,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local amap: Software::Info;  

	if ( is_orig )
    {
   	 	if ( name == "HOST")
        {
			if (/amap.com/ in value)
			{
				amap=[$software_type = HTTP::GAODEMAP_APP, $host=c$id$orig_h, $unparsed_version="GaoDe-Map"];
				Software::found(c$id, amap);
		    }
        }
    }
}


event ssl_extension(c: connection, is_orig: bool, code: count, val: string) &priority=2
{
    local amap:Software::Info;
    if (code == 0 && /amap.com/ in val )
    {
        amap = [$host=c$id$orig_h, $software_type = SSL::GAODEMAP_APP, $unparsed_version="GaoDe-Map"];
        Software::found(c$id, amap);
    }
}

