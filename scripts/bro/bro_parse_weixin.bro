@load base/frameworks/software

export {
    redef enum Software::Type += {
        HTTP::WEIXIN,  
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local weixin: Software::Info;  

	if ( is_orig )
    {
   	 	if ( name == "USER-AGENT" )
        {
			if (/MicroMessenger Client/ in value)
			{
				weixin=[$software_type = HTTP::WEIXIN, $host=c$id$orig_h, $unparsed_version=value];
                Software::found(c$id, weixin);
		      	}
         }
        
    }
}

