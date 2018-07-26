@load base/frameworks/software

export {
    redef enum Software::Type += {
        HTTP::TENCENT_VIDEO,  
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local qqlive: Software::Info;  

	if ( is_orig )
    	{
   	 	if ( name == "USER-AGENT" )
        	{
			if (/qqlive/ in value)
			{
				qqlive=[$software_type = HTTP::TENCENT_VIDEO, $host=c$id$orig_h, $unparsed_version=value];
                		Software::found(c$id, qqlive);
		    	}
         	}
    	}
}


