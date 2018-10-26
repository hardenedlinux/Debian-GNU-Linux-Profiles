module MemCD;
# sig file
redef signature_files += "memcached.sig";
export {
        redef enum Notice::Type += {
                MemCacheD_TCP_XCONN,
                MemCacheD_UDP_CONN,
                MemCacheD_UDP_DDOS
        };
    global mcd_state_timeout = 5sec &redef;
    global mcd_alarm_threshold = 10 &redef;
    global mcd_ports: set[port] = [11211/tcp, 11211/udp];
    global mem_cd_udp_server: table[addr] of count &write_expire=mcd_state_timeout &default=0;
    global mcd_udp_callback_e: event(local_serv: addr, ext_host: addr);
    global mcd_udp_init_e: event(a: addr);
    global mcd_udp_init: function(a:addr); 
    global mcd_udp_accounting: function(c: connection); 
    global mcd_udp_accounting_e: event(c: connection);

    redef Signatures::actions += {  ["tcp-mcd"] = Signatures::SIG_ALARM_PER_ORIG,
                                    ["udp-mcd"] = Signatures::SIG_ALARM_PER_ORIG,
                            } ; 

}


function mcd_udp_accounting(c: connection)
{
    local o_ip = c$id$orig_h;
    if ( ++mem_cd_udp_server[o_ip] == mcd_alarm_threshold ) {
        NOTICE([$note=MemCacheD_UDP_DDOS,
            $msg=fmt("Local Memcached DDOS addr %s outbound connections from %s", mcd_alarm_threshold, o_ip),
            $src=o_ip,
            $conn=c]);
    }
}
@if ( Cluster::is_enabled() )
# Cluster mode
@if ( type_name(Cluster::worker2manager_events) == "pattern")
   redef Cluster::worker2manager_events += /MemCD::mcd_udp_callback_e/;
   redef Cluster::worker2manager_events += /MemCD::mcd_udp_init_e/;
@else
   redef Cluster::worker2manager_events += { "MemCD::mcd_udp_callback" };
   redef Cluster::worker2manager_events += { "MemCD::mcd_udp_init_e" };
@endif
event signature_match(state: signature_state, msg: string, data: string)
{
    # For TCP, the act of an external address making contact with a 
    #   mcd server is a really bad thing.  Unlikely to be used with
    #   DDOS cause .. TCP.
    #
    if (/^tcp-mcd$/ in state$sig_id) {
        local to_ip:addr = state$conn$id$orig_h;
        local tr_ip:addr = state$conn$id$resp_h;
        if ( !Site::is_local_addr(to_ip) ) {
            NOTICE([$note=MemCacheD_TCP_XCONN,
                $msg=fmt("Local Memcached %s connected from %s", tr_ip, to_ip),
                $src=to_ip]);
            }
    } # end memcached_tcp_match
    
    local uo_ip : addr = state$conn$id$orig_h;
    local ur_ip : addr = state$conn$id$resp_h;

    # UDP is a mess.  We keep state ...
    if (/^udp-mcd$/ in state$sig_id) {
        uo_ip = state$conn$id$orig_h;
        ur_ip = state$conn$id$resp_h;
        if ( !Site::is_local_addr(uo_ip) ) {
            mcd_udp_init(uo_ip);
@if (Cluster::is_enabled())
            event mcd_udp_init_e(uo_ip);
@endif
        }
    } # end memcached_udp_match
}
event udp_reply(c: connection) 
{
    if ( (c$id$orig_h in mem_cd_udp_server) && (c$id$orig_p in mcd_ports))
    {
        local uo_ip = c$id$orig_h;
        mcd_udp_accounting(c);

@if (Cluster::is_enabled() )
        event mcd_udp_accounting_e(c);
@endif
    }
}
function mcd_udp_init(a:addr)
{
    if ( a !in mem_cd_udp_server )
        mem_cd_udp_server[a] = 1;
}
event mcd_udp_init_e(a: addr)
{
    mcd_udp_init(a);
}


event mcd_udp_accounting_e(c: connection)
{
    mcd_udp_accounting(c);
}

