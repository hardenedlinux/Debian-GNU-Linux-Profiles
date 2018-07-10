#
# Raises notices for odd or suspicious DNS traffic 
#   - Detects DNS on non-standard ports
#   - Attempts to detect DNS tunneling 
#       - intelligence for different query types --- TO DO
#       - statistical analysis' --- TO DO
#   - Detect DNS responses with interesting IPs --- TO DO
#   - Needs better inline documentation
#
# Author: Brian Kellogg
#
 
module DNS;
 
export {
        redef enum Notice::Type += {
#               DNS::NXDomain,
                DNS::Tunneling,
                DNS::Oversized_Answer,
                DNS::Oversized_Query,
                DNS::Not_p53,
        };
        # DNS names to not alert on
        const ignore_DNS_names = /wpad|isatap|autodiscover|gstatic\.com$|domains\._msdcs|mcafee\.com$/ &redef;
        # size at which dns query domain name is considered interesting
        const dns_query_oversize = 90 &redef;
        # query types to not alert on
        const ignore_qtypes = [12,32] &redef;
        # total DNS payload size over which to alert on
        const dns_plsize_alert = 512 &redef;
	# ports to ignore_DNS_names
	const dns_ports_ignore: set[port] = {137/udp, 137/tcp} &redef;
        }
 
 
#
# Raise notice for NXDOMAIN DNS replies
# I can find NX information via other means therefore I disable this.
#
#event DNS::log_dns(rec: DNS::Info)
#       {
        # do these fields exist?
#       if (rec?$rcode_name && rec?$qtype)
#               {
#               if (to_upper(rec$rcode_name) == "NXDOMAIN" && rec$qtype !in ignore_qtypes && to_upper(rec$qclass_name) == "C_INTERNET" && ignore_DNS_names !in to_lower(rec$query))
#                       {
#                       NOTICE([$note=DNS::NXDomain,
#                               $id=[$orig_h=rec$id$orig_h,$orig_p=rec$id$orig_p,$resp_h=rec$id$resp_h,$resp_p=rec$id$resp_p],
#                               $msg=fmt("Query: %s", rec$query),
#                               $sub=fmt("Query type: %s", rec$qtype_name),
#                               $identifier=cat(rec$id$orig_h,rec$query),
#                               $suppress_for=20min
#                               ]);
#                       }
#               }
#       }
 
 
event bro_init()
    {
    local r1 = SumStats::Reducer($stream="Detect.dnsTunneling", $apply=set(SumStats::SUM));
    SumStats::create([$name="Detect.dnsTunneling",
			$epoch=5min,
			$reducers=set(r1),
			$threshold = 5.0,
			$threshold_val(key: SumStats::Key, result: SumStats::Result) =
				{
				return result["Detect.dnsTunneling"]$sum;
				},
			$threshold_crossed(key: SumStats::Key, result: SumStats::Result) =
				{
				local parts = split_string(key$str, /,/);
				NOTICE([$note=DNS::Tunneling,
					$id=[$orig_h=key$host,$orig_p=to_port(parts[0]),
						$resp_h=to_addr(parts[1]),$resp_p=to_port(parts[2])],
					$uid=parts[5],
					$msg=fmt("%s", parts[3]),
					$sub=fmt("%s", parts[4]),
					$identifier=cat(key$host,parts[2]),
					$suppress_for=5min
					]);
					}]);
    }
 
 
event dns_request(c: connection, msg: dns_msg, query: string, qtype: count, qclass: count)
	{
	if (qtype !in ignore_qtypes && c$id$resp_p !in dns_ports_ignore)
		{
		if (c$id$resp_p != 53/udp && c$id$resp_p != 53/tcp)
			{
			NOTICE([$note=DNS::Not_p53,
				$conn=c,
				$msg=fmt("Query: %s", query),
				$sub=fmt("Query type: %s", qtype),
				$identifier=cat(c$id$orig_h,c$id$resp_h),
				$suppress_for=20min
				]);
			}

		if (|query| > dns_query_oversize && ignore_DNS_names !in query)
			{
			NOTICE([$note=DNS::Oversized_Query,
				$conn=c,
				$msg=fmt("Query: %s", query),
				$sub=fmt("Query type: %s", qtype),
				$identifier=cat(c$id$orig_h,c$id$resp_h),
				$suppress_for=20min
				]);

			SumStats::observe("Detect.dnsTunneling",
						[$host=c$id$orig_h, 
						$str=cat(c$id$orig_p,",",
							c$id$resp_h,",",
							c$id$resp_p,",",
							cat("Query: ",query),",",
							cat("Query type: ",qtype),",",
							c$uid)],
						[$num=1]);
			}
		}
	}
 
 
event dns_message(c: connection, is_orig: bool, msg: dns_msg, len: count)
	{
	if (len > dns_plsize_alert && c$id$orig_p !in dns_ports_ignore && c$id$resp_p !in dns_ports_ignore)
		{
		NOTICE([$note=DNS::Oversized_Answer,
			$conn=c,
			$msg=fmt("Payload length: %sB", len),
			$identifier=cat(c$id$orig_h,c$id$resp_h),
			$suppress_for=20min
			]);

		SumStats::observe("Detect.dnsTunneling",
				[$host=c$id$orig_h, 
				$str=cat(c$id$orig_p,",",
					c$id$resp_h,",",
					c$id$resp_p,",",
					cat("Payload length: ",len),",",
					" ",",",
					c$uid)],
				[$num=1]);
			}
	}
