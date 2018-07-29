@load base/frameworks/sumstats

event dns_request(c: connection, msg: dns_msg, query: string, qtype: count, qclass: count)
  {
  if ( c$id$resp_p == 53/udp && query != "" )
    SumStats::observe("dns.lookup", [$host=c$id$orig_h], [$str=query]);
    }


event bro_init (){

  local r1 = SumStats::Reducer($stream="dns.lookup", $apply=set(SumStats::UNIQUE));
  SumStats::create([$name="dns,requests.unique",
  $epoch=6hr,
  $reducers=set(r1),
  $epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result) = {
local r=result["dns.lookup"];
print fmt("%s did %s total and %d unique DNS requests in the last 6 hours.", key$host, r$sum, r$unique);
},
$epoch_finished(ts: time) ={
}]);    
}
