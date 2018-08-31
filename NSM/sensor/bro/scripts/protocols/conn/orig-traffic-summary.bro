##! Protocol traffic summary (originator) 

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
##! orig-traffic-summary.bro is a script that reports the % of traffic
##! for each tracked protocol from origin to destination.
##!

module OrigTrafficSummary;

export {
  
  ## The duration of the epoch, which defines the time between two consecutive reports
  global epoch: interval = 10sec &redef;
  ## Supported (tracked) protocols
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
"ZIP"
} &redef;
# Loging info
redef enum Log::ID += { LOG };
type Info: record {
  start_time: string &log;
  traffic_summary: string &log;
  } &redef;

  # Logging event to track the summary stats 
  global log_orig_traffic_summary: event(rec: Info);
  # Table that takes as index a protocol name and as value the total number of bytes seen
  global bytes_per_proto: table[string] of double = table();
  
  }

event bro_init()
  {
  local rec: OrigTrafficSummary::Info;
  Log::create_stream(OrigTrafficSummary::LOG, [$columns=Info, $ev=log_orig_traffic_summary]);

  local r1 = SumStats::Reducer($stream="orig.traffic.summary", $apply=set(SumStats::SUM));
  SumStats::create([$name="orig.traffic.summary",
  $epoch=epoch,
  $reducers=set(r1),
  $epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result) =
{
local r = result["orig.traffic.summary"];
bytes_per_proto[key$str] = r$sum;
},
$epoch_finished(ts: time) = 
{
local sum: double = 0.0;
local breakdown: string = "";
local proto_index: count; 
local proto: string;

# Compute total number of bytes seen from all protocols
for ( proto in bytes_per_proto )
  sum += bytes_per_proto[proto];
  
  # Compute percentages and prepare the breakdown
  for ( proto_index in tracked_protocols ) { 
    local percentage: double;
    proto = to_lower(tracked_protocols[proto_index]); # protocol services in Bro are all lower case
  if ( proto in bytes_per_proto )
    percentage = ( bytes_per_proto[proto] / sum ) * 100;
    else
      percentage = 0; 
    breakdown = fmt("%s %s: %s%s, ", breakdown, to_upper(proto), percentage,"%");
    }
  
  # Log the breakdown
  rec = [$start_time= strftime("%c", ts - epoch ), $traffic_summary=breakdown];
  Log::write(OrigTrafficSummary::LOG, rec);
  bytes_per_proto = table();
  }
]);
}

event connection_state_remove(c: connection)
  {
  if ( ! c$conn?$service )
    return;
    # Log a tuple observation [protocol name, number of bytes seen]
    SumStats::observe("orig.traffic.summary", [$str=c$conn$service], [$num=c$orig$size]);
    }