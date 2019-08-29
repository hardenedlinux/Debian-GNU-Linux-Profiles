#!/bin/sh
for pf in $(find /home/gtrun/src/your-pcap-dir -name "*.pcap")
do
    pcap_name=$(basename ${pf})
    echo "scan pcap ${pf}"
    sudo /usr/local/zeek/bin/zeek -r ${pf} /usr/local/zeek/share/zeek/site/local.zeek
done
