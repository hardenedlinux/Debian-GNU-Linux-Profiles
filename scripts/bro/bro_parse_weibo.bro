##! Implements function for weibo's client analysis. Write to the software.log file.

@load base/frameworks/software

export {
    redef enum Software::Type += {
        HTTP::WEIBO,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=2
{
	local weibo: Software::Info;

	if ( is_orig )
    {
   	 	if ( name == "USER-AGENT" )
        {
			if (/weibo/ in value)
			{
                		weibo = [$host=c$id$orig_h, $unparsed_version=value];
				weibo$software_type = HTTP::WEIBO;
                		Software::found(c$id, weibo);
			}
        }
    }
}

