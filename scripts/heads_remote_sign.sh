#!/bin/bash
BOOTPART=/boot
for line in `find ${BOOTPART} -name "*.cfg"`; do
    bash bin/kexec-parse-boot "${BOOTPART}" "${line}" >> /tmp/items;
done

head -n ${1} /tmp/items| tail -n 1 > /tmp/kexec_default.${1}.txt

BOOTPART_ESC=$(echo ${BOOTPART}|sed 's/\//\\\//g')
bash bin/kexec-boot -hb ${BOOTPART} -e "`cat /tmp/kexec_default.${1}.txt`"|sed "s/^\./${BOOTPART_ESC}/g"|xargs sha256sum | sed "s/${BOOTPART_ESC}/./g" > /tmp/kexec_default_hashes.txt
ln -s ${BOOTPART}/kexec_rollback.txt /tmp/
sha256sum `find /tmp/kexec*.txt` | sed "s/\/tmp/${BOOTPART_ESC}/g" > /tmp/top_list.txt

#gpg --digest-algo SHA256 -bo /tmp/kexec.sig /tmp/top_list.txt
