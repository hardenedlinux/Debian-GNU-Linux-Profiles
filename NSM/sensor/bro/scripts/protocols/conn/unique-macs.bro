# Written by Bob Rotsted
# Copyright Reservoir Labs, 2014.
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

module UniqueMacs;

export {

  global watched_nets: set[subnet] = [ 10.0.0.0/8, 192.168.0.0/16 ] &redef;    
global epoch: interval = 1hr &redef;

# Logging info
redef enum Log::ID += { LOG };

type Info: record {
  start_time: string &log;
  epoch: interval &log;
  net: string &log;
  mac_cnt: count &log;
  };

global log_conn_count: event(rec: Info);

}

event bro_init()
  {
  local rec: UniqueMacs::Info;
  Log::create_stream(UniqueMacs::LOG, [$columns=Info, $ev=log_conn_count]);

  local r1 = SumStats::Reducer($stream="unique.macs", $apply=set(SumStats::UNIQUE));
  SumStats::create([$name="unique.macs",
  $epoch=epoch,
  $reducers=set(r1),
  $epoch_result(ts: time, key: SumStats::Key, result: SumStats::Result) =
{
local r = result["unique.macs"];
rec = [$start_time= strftime("%c", r$begin), $epoch=epoch, $net=key$str, $mac_cnt=r$unique];
Log::write(UniqueMacs::LOG, rec);

}
]);
}

event DHCP::log_dhcp(rec: DHCP::Info) {


  if ( rec$assigned_ip in watched_nets ) {

    local net: subnet;

    for ( net in watched_nets ) { 

      if ( rec$assigned_ip in net ) {
        SumStats::observe("unique.macs", [$str=fmt("%s",net)], [$str=rec$mac]);
        }
      
      }
    }

  }
