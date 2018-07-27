export {


const blacklist_filename = "blacklist.file" &redef;

type Idx: record {
  ip: addr;
  };
type val: record {
  timestamp:time;
  reason: string:
#charact: string;

};
}

#global charact_list: set[string] = set();

# global check_val_list: bool = F;
global blacklist: table[addr] of Val = table();
#


event bro_init(){
  Input::add_table([$source=blacklist_filename, $name="blacklist",
$idx=Idx, $val=Val, $destination=blacklist]);
#$mode=Input::REREAD, $ev=entry]);
}


event http_replay(c: connection, version: string, code: count, reason: string){

  if (c$id$host in blacklist ){
    print fmt("%s found in blacklist - Reason %s", c$id$resp_h,blacklist[c$id$host]$reason);
    NOTICE([$note=DynDNS::SSL, $msg="Found Dynamic DNS Hostname", 
  $sub=value, $conn=c, $suppress_for=30mins,
    $identifier=cat(c$id$resp_h,blacklist[c$id$host]$reason)]);
}
}