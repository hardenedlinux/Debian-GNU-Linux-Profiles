
@load base/frameworks/software

export {
    redef enum Software::Type += {
        HTTP::QQ_CLIENT,
        HTTP::QQ_Mobile,
    };
    type Software::name_and_version: record {
        name   : string;
        version: Software::Version;
    };

}

redef record Software::Info  += {
    QQ_num: string &optional &log;
    o_host: addr &optional &log;
};

const dynamic_content_pattern = /\uin=|\/vuin=/ &redef;
const parse_subnet: subnet = 192.168.1.0/16;

function is_in_subnet(a: addr, b: subnet &default = parse_subnet): bool
{
    if (a in b)
        return T;
    return F;
}

event http_header(c: connection, is_orig: bool, name: string, value: string) &priority=2
{
	local qq: Software::Info;
	local result: Software::name_and_version;

    	if ( is_orig )
        {
       	 	if ( name == "USER-AGENT" )
            	{
			#Get Mobile QQ app's version  
			#value: [Mozilla/5.0 (Linux; Android 6.0; Redmi Pro Build/MRA58K; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/53.0.2785.49 Mobile MQQBrowser/6.2 TBS/043610 Safari/537.36 V1_AND_SQ_7.0.0_676_YYB_D PA QQ/7.0.0.3135 NetType/WIFI WebP/0.3.0 Pixel/1080]
			if (/PA QQ/ in value)
			{
				local paqqstr = split_string_all(value, /PA QQ\//);
				local qq_version = split_string_all(paqqstr[2],/NetType/);
				local version1 = strip(qq_version[0]);
				local ver_vec: vector of string = split_string(version1, /\./);
				result$version$major = to_count(ver_vec[0]);
                result$version$minor2 = to_count(ver_vec[2]);
                result$version$minor3 = to_count(ver_vec[3]);
                result$version$minor = to_count(ver_vec[1]);
                result$version$addl = qq_version[0];
                result$name="QQ_Client";
				if (/NetType\/WIFI/ in value)
				{
				Software::found(c$id,[$version=result$version,$name=result$name,$host=c$id$resp_h, $o_host=c$id$orig_h, $host_p=c$id$resp_p,$software_type=HTTP::QQ_Mobile,$unparsed_version=value]);

				}
				else
				{
                Software::found(c$id,[$version=result$version,$name=result$name,$host=c$id$resp_h, $o_host=c$id$orig_h, $host_p=c$id$resp_p,$software_type=HTTP::QQ_CLIENT,$unparsed_version=value]);
				}
				    
			}

              	if (dynamic_content_pattern in c$http$uri)
		        {
		        # local temp: vector of string;
                    local temp = split_string_all(c$http$uri,dynamic_content_pattern);
                    if ( 2 in temp)
                    {
                        temp=split_string_all(temp[2],/\&/);
                        qq = [$unparsed_version=value, $host=c$id$resp_h, $o_host=c$id$orig_h,$host_p=c$id$resp_p, $software_type=HTTP::QQ_CLIENT];
                        qq$QQ_num=temp[0];
                        Software::found(c$id, qq);
                    }
        	}
    
    	}
    }
}
