##! Augments conn.log and notice.log with VLAN and location information

# Reservoir Labs Inc. 2017 All Rights Reserved.

@load protocols/conn/vlan-logging
@load base/frameworks/input
@load base/frameworks/notice

@load misc/scan
@load misc/detect-traceroute
@load protocols/ssh/detect-bruteforcing

@load ./tap-data.bro
@load ./vlan-data.bro

module VLANLocation;

export {

   ## The set of notice types which should be augmented with VLAN information
    global Notice::sampled_notes: set[Notice::Type] = {
        Scan::Address_Scan,
        Scan::Port_Scan,
        SSH::Password_Guessing
    } &redef;

    ## Return type for VLAN based lookups
    type vlanresult: record{
        vaddr: addr;
        vlan: int;
        location: string;
    };

    ## Stores a mapping of the subnet to VLAN ID, used for augmenting notices
    ## where only IP Address is available but not connection info
    global net_to_vlan: table[subnet] of int = table();

    ## Lookup function that uses the net_to_vlan table to return the VLAN ID corresponding to an IP address
    global vlan_lookup: function(myaddr: addr): int;

    ## Lookup function to return the VLAN information corresponding to either the src or destination IP addresses
    global vlan_lookup_pair: function(mysrc: addr, mydst: addr): vlanresult;

    ## Lookup function to return VLAN information corresponding to the connection information
    global vlan_lookup_conn: function(c: connection): vlanresult;


    ## VLAN related fields added to the configured notices
    redef record Notice::Info += {
        vlan: int      &log &optional;
        location: string      &log &optional;
        sampled: bool     &log &default=F;
    };

    ## VLAN related fields added to each connection
    redef record Conn::Info += {
        location: string     &log &optional;
    };
}

event bro_init(){
    # once vlanlist is built we need to build the subnet lookup table
    # for when we don't have the full conn info in Notices
    for (vlan in vlanlist) {
        if (vlanlist[vlan]?$ipv4net) {
            net_to_vlan[vlanlist[vlan]$ipv4net] = vlan;
        }
        if (vlanlist[vlan]?$ipv6net) {
            net_to_vlan[vlanlist[vlan]$ipv6net] = vlan;
        }
    }    
}


event connection_state_remove(c: connection){

    # Add any VLAN information to the connection
    # Preference for inner_vlan followed by outer vlan
    if (c?$inner_vlan && c$inner_vlan in vlanlist) {
        c$conn$location = vlanlist[c$inner_vlan]$location;
    }

    if (c?$vlan && c$vlan in vlanlist) {
        c$conn$location = vlanlist[c$vlan]$location;
    }
}


# To be used only for rare/occasional lookups eg during notice generation
function vlan_lookup(myaddr: addr): int{
    for (mynet in net_to_vlan) {
        if (myaddr in mynet) {
            return net_to_vlan[mynet];
        }
    }
    return 0;
}

##  For external scripts
##  given a src/dst pair, try to find VLAN/location data for both of them.
##  and return which addr matched as well as the other results.
##  Preference is given to source ip address followed by destination ip address.

function vlan_lookup_pair(mysrc: addr, mydst: addr): vlanresult{
    local vr: vlanresult;

    vr$vlan = vlan_lookup(mysrc);
    if (vr$vlan == 0) {
        vr$vlan = vlan_lookup(mydst);
        vr$vaddr = mydst;
    } else {
        vr$vaddr = mysrc;
    }
    if (vr$vlan != 0) {
        vr$location = vlanlist[vr$vlan]$location;
    }
    return vr;
}

function vlan_lookup_conn(c: connection): vlanresult{
    local vr: vlanresult;

    if (c?$vlan) {
        vr$vlan = c$vlan;
    } else if (c?$inner_vlan) {
        vr$vlan = c$inner_vlan;
    } else {
        return vlan_lookup_pair(c$id$orig_h,c$id$resp_h);
    }

    vr$location=vlanlist[vr$vlan]$location;

    if (c$id$orig_h in Site::local_nets) {
        vr$vaddr = c$id$orig_h;
    } else {
        vr$vaddr = c$id$resp_h;
    }

    return vr;
}

hook Notice::policy(n: Notice::Info)
{
    local dst_addrs: vector of string;
    local sample_str: string;
    n$vlan = 0;
    n$location = "Unknown";
    # if the conn info exists, it already has the VLAN so use it
    if (n?$conn) {
        if (n$conn?$inner_vlan) {
            n$location = vlanlist[n$conn$inner_vlan]$location;
            n$vlan = n$conn$inner_vlan;    
        } else if (n$conn?$vlan) {
            n$location = vlanlist[n$conn$vlan]$location;
            n$vlan = n$conn$vlan;
        }
    }

    # Assume inner VLANs are more accurate for location information
    if (n?$src && n$vlan==0) {
        # if the src matches a VLAN, we'll prefer that over the dst.
        n$vlan = vlan_lookup(n$src);
        if (n$vlan != 0) {
            n$location = vlanlist[n$vlan]$location;
        }
    }

    if (n?$dst && n$vlan==0) {
        n$vlan = vlan_lookup(n$dst);
        if (n$vlan != 0) {
            n$location = vlanlist[n$vlan]$location;
        }
    }

    if (n$note in Notice::sampled_notes && n$vlan == 0) {
        # In this case we may have a sampled set of servers
        #  generated by sumstats, we can look them up but they
        #  could be in difference VLANs.   Better to set the location
        #  to "sampled" ?

        # We'll use the first VLAN we can successfully lookup,
        # but also create a 'sampled' field in the Notice so they
        # can be excluded from the data later if necessary.

        for (sample_str in set(n$msg,n$sub)) {
            n$sampled = T;
            dst_addrs = extract_ip_addresses(sample_str);
            for (dst_idx in dst_addrs) {
                n$vlan = vlan_lookup(to_addr(dst_addrs[dst_idx]));
                if (n$vlan != 0) {
                  n$location = vlanlist[n$vlan]$location;
                  break;
                }
            }
        }
    }
    if(n$vlan == 0){
        n$location = "Unknown";
    }
}


