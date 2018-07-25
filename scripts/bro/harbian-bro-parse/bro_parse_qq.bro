@load base/frameworks/software


export {
    redef enum Software::Type += {
        SSL::QQ,
        HTTP::QQ,
        SSL::WORK_WEIXIN,
        HTTP::WORK_WEIXIN,
	HTTP::QQ_GAME_CIJIZHANCHANG,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local qq: Software::Info;  

	if ( is_orig )
    {
   	 	if ( name == "HOST")
        {
			if ( /qq.com/ in value )
			{
				if  ( /work.weixin.qq.com/ in value )
				{
					qq=[$software_type = HTTP::WORK_WEIXIN, $host=c$id$orig_h, $unparsed_version="WORK_WEIXIN"];
                                	Software::found(c$id, qq);
				}
				# http.host: pg.qq.com 
				# http.user_agent: game=ShadowTrackerExtra, engine=UE4, version=4.18.1-0+++UE4+Release-4.18, platform=Android, osver=6.0 
				else if ( /pg.qq.com/ in value )
				{
					qq=[$software_type = HTTP::QQ_GAME_CIJIZHANCHANG, $host=c$id$orig_h, $unparsed_version=value];
                                	Software::found(c$id, qq);
				}
				else
				{
					qq=[$software_type = HTTP::QQ, $host=c$id$orig_h, $unparsed_version="QQ"];
					Software::found(c$id, qq);
				}

		    	}
        }
    }
}


event ssl_extension(c: connection, is_orig: bool, code: count, val: string) &priority=2
{
    local qq:Software::Info;
    if (code == 0 && /qq.com/ in val )
    {
	if (/work.weixin.qq.com/ in val )
	{
        	qq = [$host=c$id$orig_h, $software_type = SSL::WORK_WEIXIN, $unparsed_version="WORK_WEIXIN"];
        	Software::found(c$id, qq);
	}
	else 
	{
        	qq = [$host=c$id$orig_h, $software_type = SSL::QQ, $unparsed_version="QQ"];
        	Software::found(c$id, qq);
	}	
    }
}

