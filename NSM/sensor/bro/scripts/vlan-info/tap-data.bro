##! Information about VLAN IDs created at the packet broker/tap/span.

# Reservoir Labs Inc. 2017 All Rights Reserved.

@load ./vlan-data.bro

module VLANLocation;

## Useful for validating that all expected taps are generating data
## Ensure these VLAN IDs are different from operational VLAN IDs

# This is sample data and must be replaced with actual information
redef vlanlist += {
[1001] = [$description="Gigamon Port 2/1/x1",$location="wifi-upper-level"],
[1002] = [$description="Gigamon Port 2/1/x2",$location="wifi-lower-level"],
};
