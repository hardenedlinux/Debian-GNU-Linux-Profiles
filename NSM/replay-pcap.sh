#!/bin/sh
for pf in $(find /home/gtrun/src/your-pcap-dir -name "*.pcap")
do
    pcap_name=$(basename ${pf})
    echo "scan pcap ${pf}"
    sudo /usr/local/bro/bin/bro -r ${pf} /usr/local/bro/share/bro/site/local.bro
done
