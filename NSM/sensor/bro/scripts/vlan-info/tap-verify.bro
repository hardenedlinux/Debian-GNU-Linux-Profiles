##! Generates vlanlocation.log with periodic entries for all the expected VLANs in the network

# Reservoir Labs Inc. 2017 All Rights Reserved.

# An additional seen flag indicates if the VLAN was observed in monitored traffic
# Both the reporting interval and the VLAN activity monitoring interval are configurable

@load ./tap-data.bro
@load ./vlan-data.bro
@load ./vlan-location.bro

module VLANLocation;

export {
    ## The log ID
    redef enum Log::ID += { LOG };

    ## The periodicity with which VLAN information is written to the logs
    const vlan_report_interval = 5min &redef;

    ## If connections with a VLAN ID are not seen for this duration then the VLAN is considered not seen.
	const vlan_not_seen_interval = 5min &redef;

    ## The set of currently active VLANs
    global active_vlans: set[int] &write_expire = vlan_not_seen_interval;

    type Info: record {
        ## The timestamp of when the log was written
        ts: time &log;

        ## VLAN ID
        vid: int &log;

        ## Location and IP Subnet information matching the specified VLAN ID
        vlan: vlandata &log;

        ## Flag to indicate whether data from this VLAN was observed within the last vlan_not_seen_interval
        seen: bool &log &default=F;
    };
}

## Periodic event used to log VLAN information
event log_seen_vlans(){
    local vlan: int;
    local now = network_time();
    for (vlan in vlanlist){
        local seen = F;
        # Mark it seen if it is in the list of active vlans
        if (vlan in active_vlans) {
            seen = T;
        }
        Log::write(VLANLocation::LOG,[$ts=now, $vid=vlan, $vlan=vlanlist[vlan], $seen=seen]);
    }
    schedule vlan_report_interval { log_seen_vlans()};
}

event bro_init() &priority=5{
    Log::create_stream(LOG, [$columns=Info]);
    schedule vlan_report_interval { log_seen_vlans()};
}


event connection_state_remove(c: connection){

    if(c?$inner_vlan && c$inner_vlan in vlanlist){
        add active_vlans[c$inner_vlan];
    }

    if(c?$vlan && c$vlan in vlanlist){
        add active_vlans[c$vlan];
    }
}





