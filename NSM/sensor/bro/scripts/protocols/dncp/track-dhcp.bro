# Copyright 2015 Reservoir Labs, Inc.
# All rights reserved.
# 
# Contributed by Bob Rotsted

module TrackDHCP;

export {
  global ip_to_mac: table[addr] of string &synchronized &write_expire=1day; 

redef record Conn::Info += {
  orig_mac: string &optional &log;
  resp_mac: string &optional &log;
  };
}

event DHCP::log_dhcp (rec: DHCP::Info) { 
  ip_to_mac[rec$assigned_ip] = rec$mac;
  }

event connection_state_remove (c: connection) { 
  if ( c$id$orig_h in TrackDHCP::ip_to_mac ) 
    c$conn$orig_mac = TrackDHCP::ip_to_mac[c$id$orig_h];
    
    if ( c$id$resp_h in TrackDHCP::ip_to_mac ) 
      c$conn$resp_mac = TrackDHCP::ip_to_mac[c$id$resp_h];
      }