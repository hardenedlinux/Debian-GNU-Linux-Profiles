module HTTP;

export {
	redef record Info += {
		body_length: count &log &default=0;
		body_data: string &log &default="";
		params_data: set[string] &log &optional;
	};
	global body_length_max: count = 1024;
}

function extract_params_data(uri: string): set[string]
{
	local p: set[string] = set();
	if (strstr(uri, "?")==0) return p;

	local query: string = split1(uri, /\?/)[2];
	local opv: table[count] of string = split(query, /&/);

	for (each in opv)
	{
		add p[split1(opv[each], /=/)[2]];
	}
	
	return p;
}

event http_entity_data(c: connection, is_orig: bool, length: count, data: string)
{
	if (is_orig) 
	{
		if (c$http$body_length < HTTP::body_length_max)
		{
			c$http$body_data = string_cat(c$http$body_data, data);
			c$http$body_length += length;
		}
	}
 }

event http_request(c: connection, method: string, original_URI: string, unescaped_URI: string, version: string)
{
        local ss: set[string] = extract_params_data(original_URI);

        if (! c$http?$params_data)
        {
                local tmp: set[string] = set();
                c$http$params_data = tmp;
        }
        for (each in ss)
        {
                add c$http$params_data[each];
        }
}
