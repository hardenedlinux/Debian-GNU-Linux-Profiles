This module provides a mapping between VLAN IDs and the physical location where available.
It augments conn.log and notice.log with VLAN and corresponding location information.
It generates vlanlocation.log containing periodic entries of all expected VLANs.
The seen flag indicates whether any connections with the corresponding VLAN tags were received.

Users are expected to modify the following
1. vlan-data.bro
2. tap-data.bro

in vlan-location:
    Notice::sampled_notes - Add or remove additional notices that need to be augmented with VLAN information

in tap-verify:
    vlan_report_interval - The periodicity with which all tap information is added to vlanlocation.log
    vlan_not_seen_interval - The expiration interval for connections which do not contain a VLAN ID. These will be marked
    as not seen in vlanlocation.log

Test Pcap available at https://drive.google.com/open?id=0B7FHRi80opInekVLSG5TTEZLd2s
