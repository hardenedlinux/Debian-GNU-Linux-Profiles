##! Protocol stats summary (originator) 

# Contributed by Reservoir Labs, Inc.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##!
##! protocol-stats.bro is a script that reports the % of traffic
##! for each tracked protocol. 
##!
##! This script reports the following logs:
##!   - protocolstats_orig.log: protocol stats for outgoing traffic
##!   - protocolstats_resp.log: protocol stats for incoming traffic 
##!
##! Tips:
##!   - To add or remove new protocols to track, please redefine 
##!     ProtocolStats::tracked_protocols and ProtocolStats::Info. 
##!   - This analytic adds a new Weird::actions called
##!     'protocolstats_untracked' that is triggered every time
##!     there is traffic parsed by Bro that does not correpond
##!     to any of the tracked protocols.
##!   - The last column (UNTRACKED) in protocolstats_*.log
##!     reports % of traffic that Bro was able to understand
##!     but which is not in the list of tracked protocols.
##!   - To learn which protocols are part of UNTRACKED, search
##!     for 'protocolstats_untracked' entries in weird.log
##!   - Protocol compositions (i.e. when the list of protocol analyzers
##!     successfully attached to a flow is larger than 1), are 
##!     reported separately. E.g. 1000 bytes of traffic reported
##!     on protocol composition 'ssl,smtp' is reported as 1000 bytes on
##!     SSL and 1000 bytes on SMTP separately. 
##! 


module ProtocolStats;

export {
  
  ## The duration of the epoch, which defines the time between two consecutive reports
  global epoch: interval = 10sec &redef;

  ## The protocol analyzers will build composites based on traffic. For example, 
  ## SSL HTTP traffic will be denoted as SSL,HTTP (or HTTP,SSL). If composite_protocols
  ## is set, it will use the composites. If this is unset, it will attribute each 
  ## component of the composite to the underlying protocol.
  global composite_protocols: bool = T &redef;

  ## Supported (tracked) protocols. To add or remove new protocols, please redefine
  ## both ProtocolStats::tracked_protocols and ProtocolStats::Info.
  global tracked_protocols: vector of string = {"ARP", "AYIYA", 
"BackDoor", "BitTorrent", 
"ConnSize", 
"DCE_RPC", "DHCP", "DNP3", "DNS", 
"File", "Finger", "FTP", 
"Gnutella", "GTPv1", 
"HTTP", 
"ICMP", "Ident", "InterConn", "IRC", 
"Login", 
"MIME", "Modbus", 
"NCP", "NetBIOS", "NetFlow", "NTP", 
"PIA", "POP3", 
"RADIUS", "RPC", 
"SNMP", "SMB", "SMTP", "SOCKS", "SSH", "SSL", "SteppingStone", "Syslog", 
"TCP", "Teredo", 
"UDP", 
"ZIP",
"HTTP,SSL",
"SSL,HTTP"
} &redef;

## Protocols that get logged
type Info: record {
  start_time: time &log;
  ARP: double &log;
  AYIYA: double &log;
  BackDoor: double &log;
  BitTorrent: double &log;
  ConnSize: double &log;
  DCE_RPC: double &log;
  DHCP: double &log;
  DNP3: double &log;
  DNS: double &log;
  File: double &log;
  Finger: double &log;
  FTP: double &log;
  Gnutella: double &log;
  GTPv1: double &log;
  HTTP: double &log;
  ICMP: double &log;
  Ident: double &log;
  InterConn: double &log;
  IRC: double &log;
  Login: double &log;
  MIME: double &log;
  Modbus: double &log;
  NCP: double &log;
  NetBIOS: double &log;
  NetFlow: double &log;
  NTP: double &log;
  PIA: double &log;
  POP3: double &log;
  RADIUS: double &log;
  RPC: double &log;
  SNMP: double &log;
  SMB: double &log;
  SMTP: double &log;
  SOCKS: double &log;
  SSH: double &log;
  SSL: double &log;
  SteppingStone: double &log;
  Syslog: double &log;
  TCP: double &log;
  Teredo: double &log;
  UDP: double &log;
  ZIP: double &log;
  HTTP_SSL: double &log;
  SSL_HTTP: double &log;
  UNTRACKED: double &log; # Traffic that has been parsed but which is not tracked in tracked_protocols
} &redef;

# Logging info
redef enum Log::ID += { ORIG };
redef enum Log::ID += { RESP };

# Logging events to track the summary stats (incoming and outgoing traffic) 
global log_orig_proto_stats: event(rec: Info);
global log_resp_proto_stats: event(rec: Info);

# Table that takes as index a protocol name and as value the total number of bytes seen
global bytes_per_proto_orig: table[string] of double = table();
global bytes_per_proto_resp: table[string] of double = table();
}

## This weird action is triggered every time this analytic finds traffic on
## a protocol that is not in the list of tracked protocols.
redef Weird::actions += { ["protocolstats_untracked"] = Weird::ACTION_LOG };


#
# Generates a report based on the traffic direction
# This is called every 'epoch' interval.
#
function generate_protocol_stats(ts: time, direction: string)
  {
  local rec: ProtocolStats::Info;
  local sum: double = 0.0;
  local sum_untracked: double = 0.0;
  local breakdown: string = "";
  local proto_index: count; 
local proto: string;
local tracked_protocol_values: table[string] of double; 
local bytes_per_proto: table[string] of double = table(); 

if ( direction == "orig" )
  bytes_per_proto = bytes_per_proto_orig;
  else
    bytes_per_proto = bytes_per_proto_resp;
    
    # Compute total number of bytes seen from all protocols
    for ( proto in bytes_per_proto )
      sum += bytes_per_proto[proto];
      
      # Compute percentages and prepare the breakdown of all known protocols
      for ( proto_index in tracked_protocols ) { 
        local percentage: double;
        proto = to_lower(tracked_protocols[proto_index]); # protocol services in Bro are all lower case
      # If there's any data, calculate the percentage of total annd remove
      # the entry. At the end, all known protocols will be removed and all that
      # will be left are the unknowns. 
      if ( sum != 0 && proto in bytes_per_proto ) {
        percentage = ( bytes_per_proto[proto] / sum ) * 100;
        delete bytes_per_proto[proto];
        }
      else
        percentage = 0; 
      tracked_protocol_values[proto] = percentage;
      }

    # Any remaining items in bytes_per_proto are not tracked, report them as weird
    for (proto in bytes_per_proto) {
      local rec_weird: Weird::Info;
      rec_weird$ts = ts;
      rec_weird$name = "protocolstats_untracked";
      rec_weird$addl =  fmt("%s: %s%s", proto, (bytes_per_proto[proto]/sum)*100, "%");
      Log::write(Weird::LOG, rec_weird);
      sum_untracked += bytes_per_proto[proto];
      }


    # Log one entry 
    rec = [$start_time = ts - epoch, 
  $ARP=tracked_protocol_values["arp"],
    $AYIYA=tracked_protocol_values["ayiya"],
    $BackDoor=tracked_protocol_values["backdoor"],
    $BitTorrent=tracked_protocol_values["bittorrent"],
    $ConnSize=tracked_protocol_values["connsize"],
    $DCE_RPC=tracked_protocol_values["dce_rpc"],
    $DHCP=tracked_protocol_values["dhcp"],
    $DNP3=tracked_protocol_values["dnp3"],
    $DNS=tracked_protocol_values["dns"],
    $File=tracked_protocol_values["file"],
    $Finger=tracked_protocol_values["finger"],
    $FTP=tracked_protocol_values["ftp"],
    $Gnutella=tracked_protocol_values["gnutella"],
    $GTPv1=tracked_protocol_values["gtpv1"],
    $HTTP=tracked_protocol_values["http"],
    $ICMP=tracked_protocol_values["icmp"],
    $Ident=tracked_protocol_values["ident"],
    $InterConn=tracked_protocol_values["interconn"],
    $IRC=tracked_protocol_values["irc"],
    $Login=tracked_protocol_values["login"],
    $MIME=tracked_protocol_values["mime"],
    $Modbus=tracked_protocol_values["modbus"],
    $NCP=tracked_protocol_values["ncp"],
    $NetBIOS=tracked_protocol_values["netbios"],
    $NetFlow=tracked_protocol_values["netflow"],
    $NTP=tracked_protocol_values["ntp"],
    $PIA=tracked_protocol_values["pia"],
    $POP3=tracked_protocol_values["pop3"],
    $RADIUS=tracked_protocol_values["radius"],
    $RPC=tracked_protocol_values["rpc"],
    $SNMP=tracked_protocol_values["snmp"],
    $SMB=tracked_protocol_values["smb"],
    $SMTP=tracked_protocol_values["smtp"],
    $SOCKS=tracked_protocol_values["socks"],
    $SSH=tracked_protocol_values["ssh"],
    $SSL=tracked_protocol_values["ssl"],
    $SteppingStone=tracked_protocol_values["steppingstone"],
    $Syslog=tracked_protocol_values["syslog"],
    $TCP=tracked_protocol_values["tcp"],
    $Teredo=tracked_protocol_values["teredo"],
    $UDP=tracked_protocol_values["udp"],
    $ZIP=tracked_protocol_values["zip"],
    $HTTP_SSL=tracked_protocol_values["http,ssl"],
    $SSL_HTTP=tracked_protocol_values["ssl,http"],
    $UNTRACKED=100*sum_untracked/sum
  ];

  # Write out the record and re-initialize the global table
  if ( direction == "orig" ) {
    Log::write(ProtocolStats::ORIG, rec);
    bytes_per_proto_orig = table();
    }
  else {
    Log::write(ProtocolStats::RESP, rec);
    bytes_per_proto_resp = table();
    }

  return;
  }


#
# Records one observation 
#
function record_observation(key: SumStats::Key, r: SumStats::ResultVal, direction: string) { 
  local proto_index: count;
  local protocols:string_array;

  # use either composite protocols or break them up into their individual components
  if ( composite_protocols )  {
    protocols = string_array();
    protocols[0] = key$str;
    }
  else {
    protocols = split(key$str, /,/); 
  }

# populate a table index by protocol with the values of the observation
if ( direction == "orig" ) 
  for ( proto_index in protocols ) bytes_per_proto_orig[protocols[proto_index]] = r$sum;
    else
      for ( proto_index in protocols ) bytes_per_proto_resp[protocols[proto_index]] = r$sum;

        return;
        }


      event bro_init()
    {
    Log::create_stream(ProtocolStats::ORIG, [$columns=Info, $ev=log_orig_proto_stats]);
    Log::create_stream(ProtocolStats::RESP, [$columns=Info, $ev=log_resp_proto_stats]);

    # Define reducers
    local r1 = SumStats::Reducer($stream="orig.proto.stats", $apply=set(SumStats::SUM));
    local r2 = SumStats::Reducer($stream="resp.proto.stats", $apply=set(SumStats::SUM));

    # Define SumStats
    SumStats::create([$name="orig.proto.stats",
      $epoch=epoch,
      $reducers=set(r1),
      $epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result) = { record_observation(key, result["orig.proto.stats"], "orig"); },
      $epoch_finished(ts: time) = { generate_protocol_stats(ts, "orig"); } 
    ]);

    SumStats::create([$name="resp.proto.stats",
      $epoch=epoch,
      $reducers=set(r2),
      $epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result) = { record_observation(key, result["resp.proto.stats"], "resp"); },
      $epoch_finished(ts: time) = { generate_protocol_stats(ts, "resp"); } 
    ]);
    }


  event connection_state_remove(c: connection)
{
if ( ! c$conn?$service )
  return;

  # Log one tuple observation [protocol name, number of bytes seen] for each direction
  SumStats::observe("orig.proto.stats", [$str=c$conn$service], [$num=c$orig$size]);
  SumStats::observe("resp.proto.stats", [$str=c$conn$service], [$num=c$resp$size]);
  }
