module DynamicDNS;

@load base/frameworks/input/

# This module is used to look for dynamic dns domains that are present in various kinds of
# network traffic. For HTTP, the HOST header value is checked, for DNS the query request value
# is checked, and for SSL the server value is checked. Since dynamic DNS domains often take
# the format of <user defined>.domain.tld the value in the host header is stripped of everything 
# to the left of domain.tld, in the event that doesn't match the check is expanded to 
# something.domain.tld.
#
# A good place to get started is malware-domains dyndns list, the following will put it in the 
# right format for this script:
# wget "http://www.malware-domains.com/files/dynamic_dns.zip" && unzip -c dynamic_dns.zip | tail -n +4 | grep -v ^# | grep -v ^$ | cut -f 1 > tmp.txt && echo -e "#fields\tdomain" > dynamic_dns.txt && cat tmp.txt | cut -d '#' -f 1 >> dynamic_dns.txt && rm tmp.txt dynamic_dns.zip
#
# In additon to looking for the presence of dynamic DNS domains it will keep track (for 1 day)
# all IPs that resolve to a dynamic DNS domain, and flag any traffic destined to those IP addresses
#
# Requires Bro 2.1
# Mike (sooshie@gmail.com)

##JP Bourget 10/29/13
##Updated for Bro 2.2 - byte_len is depricated and replaced with | | (2 pipes)

## Brian Kellogg 12/2/2014
## Updated for Bro 2.3 - DNS::do_reply is now a hook not an event, 
## Added logic to check for conn$dns field before looking for conn$dns$query field - if ((c?$dns) && (c$dns?$query))

## Mike 8/17/2015
## It apparently doesn't crash in Bro 2.4, and it still works

# To ignore specific hostnames just add them to ignore_dyndns_fqdns
# Set the name/location of the txt file that contains the domains via redef of dyndns_filename
export {
    redef enum Notice::Type += { DynDNS::HTTP, DynDNS::DNS, DynDNS::Traffic, DynDNS::SSL };
    const ignore_dyndns_fqdns: set[string] = { } &redef;
    const dyndns_filename = "static_data/dynamic_dns.txt" &redef;
}

type Idx: record {
    domain: string;
};

global dyndns_domains: set[string] = set();
global dyndns_resolved_ips: table[addr] of string = table() &create_expire=1days;
global dyndnslist_ready: bool = F;

function get_domain_2level(domain: string): string
    {
    local result = find_last(domain, /\.[^\.]+\.[^\.]+$/);
    if ( result == "" )
        return domain;
    return sub_bytes(result, 2, |result|); #updated for bro 2.2
    }

function get_domain_3level(domain: string): string
    {
    local result = find_last(domain, /\.[^\.]+\.[^\.]+\.[^\.]+$/);
    if ( result == "" )
        return domain;
    return sub_bytes(result, 2, |result|); #updated for bro 2.2
    }

event bro_init()
    {
    Input::add_table([$source=dyndns_filename, $mode=Input::REREAD,
                      $name="dynlist", $idx=Idx, $destination=dyndns_domains]);
    }

# for bro 2.1

event Input::update_finished(name: string, source: string)
    {
    if ( name == "dynlist" )
        dyndnslist_ready = T;
    }

# fwd compat to 2.2
event Input::end_of_data(name: string, source: string)
    {
    if ( name == "dynlist" )
        dyndnslist_ready = T;
    }

event http_header(c: connection, is_orig: bool, name: string, value: string)
    {
    if ( ! is_orig )
        return;
    if ( ! dyndnslist_ready)
        return;
    if ( name == "HOST" )
        {
        if ( value in ignore_dyndns_fqdns )
            return;
        local domain = get_domain_2level(value);
        if ( domain in dyndns_domains )
            {
            NOTICE([$note=DynDNS::HTTP, $msg="Found Dynamic DNS Hostname",
                    $sub=value, $conn=c, $suppress_for=30mins, 
                    $identifier=cat(c$id$resp_h,c$id$resp_p,c$id$orig_h,value)]);
            return;
            }
        domain = get_domain_3level(value);
        if ( domain in dyndns_domains )
            {
            NOTICE([$note=DynDNS::HTTP, $msg="Found Dynamic DNS Hostname", 
                    $sub=value, $conn=c, $suppress_for=30mins, 
                    $identifier=cat(c$id$resp_h,c$id$resp_p,c$id$orig_h,value)]);
            }
        }
    }

hook DNS::do_reply(c: connection, msg: dns_msg, ans: dns_answer, reply: string)
    {
    if ( ! dyndnslist_ready)
        return;

    local dyn = F;
    local value: string;
    if ((c?$dns) && (c$dns?$query))
        { 
        value = c$dns$query;
        if ( value in ignore_dyndns_fqdns )
            return;
        local domain = get_domain_2level(value);
        if ( domain in dyndns_domains )
            {
            NOTICE([$note=DynDNS::DNS, $msg="Found Dynamic DNS Hostname", 
                    $sub=value, $conn=c, $suppress_for=30mins, 
                    $identifier=cat(c$id$resp_h,c$id$resp_p,c$id$orig_h,value)]);
            dyn = T;
            }
        domain = get_domain_3level(value);
        if ( domain in dyndns_domains )
            {
            NOTICE([$note=DynDNS::DNS, $msg="Found Dynamic DNS Hostname", 
                    $sub=value, $conn=c, $suppress_for=30mins, 
                    $identifier=cat(c$id$resp_h,c$id$resp_p,c$id$orig_h,value)]);
            dyn = T;
            }
        }
    if ( dyn )
        {
        if ( c$dns?$answers )
            {
            for ( a in c$dns$answers )
                {
                if ( /[a-zA-z]/ in c$dns$answers[a] )
                    return;
                local ip = to_addr(c$dns$answers[a]);
                if ( ip in 0.0.0.0/0 )
                    dyndns_resolved_ips[ip] = value;
                }
            }
        }
    }

event ssl_established(c: connection)
{
    if ( ! dyndnslist_ready)
        return;

    if(c$ssl?$server_name) 
        {
        local value = c$ssl$server_name;
        if ( value in ignore_dyndns_fqdns )
            return;
        local domain = get_domain_2level(value);
        if ( domain in dyndns_domains )
            NOTICE([$note=DynDNS::SSL, $msg="Found Dynamic DNS Hostname", 
                    $sub=value, $conn=c, $suppress_for=30mins,
                    $identifier=cat(c$id$resp_h,c$id$resp_p,c$id$orig_h,value)]);
        domain = get_domain_3level(value);
        if ( domain in dyndns_domains )
            NOTICE([$note=DynDNS::SSL, $msg="Found Dynamic DNS Hostname", 
                    $sub=value, $conn=c, $suppress_for=30mins,
                    $identifier=cat(c$id$resp_h,c$id$resp_p,c$id$orig_h,value)]);
        }
}

event Conn::log_conn(rec: Conn::Info)
    {
    if ( ! dyndnslist_ready)
        return;
    
    local ip = rec$id$resp_h;
    local c: connection;
    local cid: conn_id;
    c$id = cid;
    c$uid = rec$uid;
    c$id$orig_h = rec$id$orig_h;
    c$id$resp_h = rec$id$resp_h;
    c$id$resp_p = rec$id$resp_p;
    c$id$orig_p = rec$id$orig_p;
    if ( ip in dyndns_resolved_ips )
        NOTICE([$note=DynDNS::Traffic, $msg="Traffic to a DynDNS resolved IP", 
                $sub=dyndns_resolved_ips[ip], $conn=c, $suppress_for=30mins,
                $identifier=cat(c$id$orig_h,c$id$resp_h,c$id$resp_p)]);
    }
