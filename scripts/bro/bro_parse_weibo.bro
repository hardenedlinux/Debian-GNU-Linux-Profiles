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
			# Get weibo app's version  
			# example: value = MX6_6.0_weibo_8.6.0_android_wifi
			if (/weibo_/ in value)
			{
				#local verstr = split_string_all(value, /weibo_/);
                		#weibo = [$host=c$id$orig_h, $unparsed_version=verstr[2]];
                		weibo = [$host=c$id$orig_h, $unparsed_version=value];
				#if (/android/ in value && /wifi/ in value)
				#{
					weibo$software_type = HTTP::WEIBO;
				#}
                		Software::found(c$id, weibo);
			}
        }
    }
}

