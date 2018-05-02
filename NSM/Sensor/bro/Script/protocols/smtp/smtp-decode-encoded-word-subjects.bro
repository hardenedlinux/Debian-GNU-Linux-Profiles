
# Implements Encoded-word decoding (RFC2047)
function decode_encoded_word(a: string): string
	{
	local parts = split_all(a, /\=\?[^\?]*\?[bBqQ]\?[^\?]*\?\=/);
	for ( i in parts )
		{
		if ( /\?[bB]\?/ in parts[i] )
			{
			# base64
			local b_parts = split_all(parts[i], /(\?[bB]\?|\?\=$)/);
			parts[i] = decode_base64(b_parts[3]);
			}
		else if ( /\?[qQ]\?/ in parts[i] )
			{
			# quoted printable
			parts[i] = gsub(parts[i], /_/, " ");
			parts[i] = gsub(parts[i], /(^.*\?[qQ]\?|\?\=$)/, "");
			local q_parts = split_all(parts[i], /\=[a-fA-F0-9]{2}/);
			for ( f in q_parts )
				{
				if ( q_parts[f] == /\=[a-fA-F0-9]{2}/ )
					{
					q_parts[f] = sub(q_parts[f], /^=/, "%");
					q_parts[f] = unescape_URI(q_parts[f]);
					}
				}
			parts[i] = cat_string_array(q_parts);
			}
		}
	return cat_string_array(parts);
	}

redef record SMTP::Info  += {
	decoded_subject: string &optional &log;
};

event mime_one_header(c: connection, h: mime_header_rec) &priority=3
	{
	if ( c?$smtp && h$name == "SUBJECT" )
		{
		c$smtp$decoded_subject = decode_encoded_word(h$value);
		}
	}

