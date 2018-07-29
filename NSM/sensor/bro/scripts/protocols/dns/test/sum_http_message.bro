@load base/frameworks/sumstats

event bro_init() &priority=5
  {
  local r1=SumStats::Reducer($stream="http.queries",$apply=set(SumStats::SUM));
  SumStats::create([$name="http.excess.queries",
  $epoch = 5min,
  $reducers = set(r1),
  $threshold = 5.0,
  $threshold_val(key: SumStats::Key, result: SumStats::Result): double = {
return result["http.queries"]$sum;
},
$threshold_crossed(key: SumStats::Key, result: SumStats::Result) = {
print fmt("%s had too many quries", key$host);
}
]);
}

event http_message_done(c: connection, is_orig: bool, stat: http_message_stat) &priority=-10
  {
  if(! is_orig ){
    if( c$http?$uri ){
      SumStats::observe("http.queries", SumStats::Key($host=c$id$resp_h), SumStats::Observation($str=c$http$uri));
      }
    }
  }