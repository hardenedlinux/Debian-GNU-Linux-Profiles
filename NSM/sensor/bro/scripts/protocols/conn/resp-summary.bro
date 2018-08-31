# Written by Bob Rotsted
# Copyright Reservoir Labs, 2015.
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

module RespTrafficSummary;

export {
  
  global epoch: interval = 60min &redef;
  redef enum Log::ID += { LOG };

  type Info: record {
    start_time: string &log;
    traffic_breakdown: string &log;
    } &redef;

    global log_resp_traffic_summary: event(rec: Info);
    global bytes_per_proto: table[string] of double = table();

    
    }

  event bro_init()
{

local rec: RespTrafficSummary::Info;
Log::create_stream(RespTrafficSummary::LOG, [$columns=Info, $ev=log_resp_traffic_summary]);

local r1 = SumStats::Reducer($stream="resp.traffic.summary", $apply=set(SumStats::SUM));
SumStats::create([$name="resp.traffic.summary",
$epoch=epoch,
$reducers=set(r1),
$epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result) =
{
local r = result["resp.traffic.summary"];

bytes_per_proto[key$str] = r$sum;

},
  $epoch_finished(ts: time) = 
{

local sum: double = 0.0;
local breakdown: string = "";

for ( proto in bytes_per_proto )
  sum += bytes_per_proto[proto];
  
  for ( proto in bytes_per_proto ) { 
    local percentage: double = ( bytes_per_proto[proto] / sum ) * 100;
    breakdown = fmt("%s %s: %s%s, ", breakdown, to_upper(proto), percentage,"%");
    }
  
  rec = [$start_time= strftime("%c", ts - epoch ), $traffic_breakdown=breakdown];
  Log::write(RespTrafficSummary::LOG, rec);
  bytes_per_proto = table();
  }
]);
}

event connection_state_remove(c: connection)
  {
  if ( ! c$conn?$service )
    return;

    SumStats::observe("resp.traffic.summary", [$str=c$conn$service], [$num=c$resp$size]);
    }