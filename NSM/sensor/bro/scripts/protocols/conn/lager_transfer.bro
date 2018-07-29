@load base/protocols/conn/thresholds

export {
  const large_transfer = 100000 &redef;
  
  redef enum Notice::Type += {
    Large_Transfer,
  };
}

event ConnThreshold::bytes_threshold_coressed(c: connection, threshold: count, is_orig:bool) {
  NOTICE([$note=Large_Transfer,
$msg=fmt("Large transfer from %s:%d to %s: %d of threshold %d",
c$id$orig_h, c$id$orig_p,
c$id$resp_h, c$id$resp_p,
threshold),
$conn=c]);
}

event connection_established(c:connection){
  ConnThreshold::set_bytes_threshold(c, large_transfer, T);    
ConnThreshold::set_bytes_threshold(c, large_transfer, F);

}
