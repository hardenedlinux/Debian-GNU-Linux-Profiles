##! Information about VLANs, mapping VLAN ID to the expected IP Address range and location information

# Reservoir Labs Inc. 2017 All Rights Reserved.

module VLANLocation;

export {

    ## Location/IP subnet information corresponding to each VLAN
    type vlandata: record {
        ## Human readable description for the VLAN
        description: string &log;

        ## Expected IPv4 subnet information if available.
        ipv4net: subnet &log &optional;

        ## Expected IPv6 subnet information if available
        ipv6net: subnet &log &optional;

        ## Location information for the VLAN if applicable eg Building East, First Floor etc
        location: string &log &optional;
    };

    global vlanlist: table[int] of vlandata = table() &redef;

}

# This must be customized to each environment
redef vlanlist += {
[100] = [$description="north",$ipv4net=10.2.0.0/24,$ipv6net=[2001:0468:1f07:000b::]/64,$location="north"],
[101] = [$description="south",$ipv4net=10.12.0.0/24,$ipv6net=[2001:0468:1f07:000c::]/64,$location="south"],
[102] = [$description="west",$ipv4net=10.16.0.0/24,$ipv6net=[2001:0468:1f07:000d::]/64,$location="west"],
[103] = [$description="east",$ipv4net=10.10.0.0/24,$ipv6net=[2001:0468:1f07:f00e::]/64,$location="east"]
};
