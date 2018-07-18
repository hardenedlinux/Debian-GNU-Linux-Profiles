@load base/frameworks/software

export {
    redef enum Software::Type += {
        SSL::ALIPAY_APP,
        HTTP::ALIPAY_APP,
    };
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=10
{
	local alipay: Software::Info;  

	if ( is_orig )
    {
   	 	if ( name == "HOST")
        {
			if (/alipay.com/ in value)
			{
				alipay=[$software_type = HTTP::ALIPAY_APP, $host=c$id$orig_h, $unparsed_version="alipay-app"];
				Software::found(c$id, alipay);
		    }
        }
    }
}


event ssl_extension(c: connection, is_orig: bool, code: count, val: string) &priority=2
{
    local alipay:Software::Info;
    if (code == 0 && /alipay.com/ in val )
    {
        alipay = [$host=c$id$orig_h, $software_type = SSL::ALIPAY_APP, $unparsed_version="alipay-app"];
        Software::found(c$id, alipay);
    }
}

