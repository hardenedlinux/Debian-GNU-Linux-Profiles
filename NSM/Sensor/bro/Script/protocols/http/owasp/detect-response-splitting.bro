@load base/frameworks/notice

module HTTP;

export {
	redef enum Notice::Type += {
		Response_Splitting_Body,
		Response_Splitting_Parameter,
	};

	global http_response_line: pattern = /.*?[[:digit:]]{3}[[:space:]]([[:alpha:]]+[[:space:]])+HTTP\/[0-9]/;
	global url_decode_tries: count = 3;
}

event connection_state_remove(c: connection)
{
	if (!c?$http) return;
	if (c$http$body_length > 6)
	{
		if (HTTP::http_response_line in HTTP::url_decode(c$http$body_data, HTTP::url_decode_tries))
		{
			NOTICE([$note=Response_Splitting_Body, $msg="Possible HTTP response splitting"]);			
		}
	}
}

event http_message_done(c: connection, is_orig: bool, stat: http_message_stat)
{
	if (! is_orig) return;

	for (p in c$http$params_data)
	{
		if (HTTP::http_response_line in HTTP::url_decode(p, HTTP::url_decode_tries))
		{
			NOTICE([$note=Response_Splitting_Parameter, $msg="Possible HTTP response splitting"]);
		}
	}
}
