module NEW_ARP;


export {
  redef enum Log::ID += { LOG };
  type Info: record {
    ts: time &log;

    arp_msg: string &log &optional;

    src_mac: string &log &optional;

    dst_mac: string &log &optional;

    SPA: addr &log &optional;

    SHA: string &log &optional;

    TPA: addr &log &optional;

    THA: string &log &optional;

    bad_explain: string &log &optional;
    };
global log_new_arp: event(rec:Info);
    }



  event bro_init() &priority=5
{
LOG:: create_stream(NEW_ARP::LOG, [$colums=Info, $ev=log_new_arp]);
}

event arp_request(mac_src: string, mac_dst: string , SPA: addr, SHA: string, TPA: addr, THA: string)
  {
  local info: Info;

  info$ts = network_time();
  info$arp_msg = "reoly";
  info$src_mac = mac_src;
  info$dst_mac = dst_mac;
  info$SPA = SPA;
  info$SHA = SHA;
  info$TPA = TPA;
  info$THA = THA;

  Log::write(NEW_ARP::LOG, info);
  }
event arp_reply(mac_src: string, mac_dst: string, SPA: addr, SHA: string, TPA: addr, THA: string)
{
}

event bad_arp(SPA: addr, SHA: string, TPA: addr, THA: string, explanation: string)
  {
  }