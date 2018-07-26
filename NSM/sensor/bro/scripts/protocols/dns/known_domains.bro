# Copyright (C) 2016, Missouri Cyber Team
# All Rights Reserved
# See the file "LICENSE" in the main distribution directory for details

# NOTE: On a busy network, this may consume a lot of memory. Revisit
# when Broker is efficient enough to handle this.

module MOCYBER;

export {
## The known-hosts logging stream identifier.
  redef enum Log::ID += { UNIQDNS_LOG };

  ## The record type which contains the column fields of the known-hosts log.
  type Info: record {
    ## The timestamp at which the host was detected.
    ts:      time &log;
    ## The address that was detected originating or responding to a
    ## TCP connection.
    domain:    string &log;
  };

  ## The set of all known addresses to store for preventing duplicate
  ## logging of addresses.  It can also be used from other scripts to
  ## inspect if an address has been seen in use.
  ## Maintain the list of known hosts for 24 hours so that the existence
  ## of each individual address is logged each day.
  global known_domains: set[string] &create_expire=1 day &synchronized &redef;

  ## An event that can be handled to access the :bro:type:`Known::HostsInfo`
  ## record as it is sent on to the logging framework.
  global log_known_domains: event(rec: Info);
}

event bro_init()
{
  Log::create_stream(MOCYBER::UNIQDNS_LOG, [$columns=Info, $ev=log_known_domains, $path="known_domains"]);
  local f = Log::get_filter(MOCYBER::UNIQDNS_LOG, "default");
  #f$interv = 15 min;
  Log::add_filter(CyberDev::UNIQDNS_LOG, f);
}

event dns_query_reply(c: connection, msg: dns_msg, query: string, qtype: count, qclass: count)
{
  if(!c?$dns)
    return;
  if(query !in known_domains)
  {
    add known_domains[query];
    Log::write( MOCYBER::UNIQDNS_LOG,[$ts=network_time(),$domain=query] );
  }
}
