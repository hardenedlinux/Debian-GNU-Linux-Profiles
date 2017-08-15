### Manually Deploy Ceph Cluster Step-by-Step

Note: Our installation is base on Ceph(10.2.9 LTS). The document url of this
version is http://docs.ceph.com/docs/jewel/

### Basic Setup

#### Install PaX/Grsecurity kernel

For Security build-in policy we should install PaX/Grsecurity kernel right
after we finish the system installation

```
root@cephmon0# ls
linux-firmware-image-4.9.38-unofficial+grsec+_4.9.38-unofficial+grsec+-7_amd64.deb
linux-headers-4.9.38-unofficial+grsec+_4.9.38-unofficial+grsec+-7_amd64.deb
linux-image-4.9.38-unofficial+grsec+-dbg_4.9.38-unofficial+grsec+-7_amd64.deb
linux-image-4.9.38-unofficial+grsec+_4.9.38-unofficial+grsec+-7_amd64.deb
linux-libc-dev_4.9.38-unofficial+grsec+-7_amd64.deb
root@cephmon0# dpkg -i *.deb
```

#### Install Ceph

##### Build Ceph from github (build with jemalloc)

```
git 
```



##### Or you can use ceph with tcmalloc(default)

```
root@cephmon0# apt install software-properties-common -y
root@cephmon0# wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
root@cephmon0# apt-add-repository 'deb http://cn.ceph.com/debian-jewel/ stretch main'
root@cephmon0# apt update
root@cephmon0# apt install ceph -y
```

### Ceph Architecture (Manually Version)

TBD

### Configure Ceph Monitor

Install UUID tool

```
root@cephmon0# apt install uuid-runtime -y
root@cephmon0# uuidgen
a7f64266-0894-4f1e-a635-d0aeaca0e993
```

Create /etc/ceph/ceph.conf, using the UUID for fsid(cluster uuid)

```
[global]
fsid = a7f64266-0894-4f1e-a635-d0aeaca0e993
mon initial members = mon0
mon host = 192.168.200.1
public network = 192.168.200.0/24
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 2
osd pool default min size = 1
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1
```

Create client admin keyring

```
root@cephmon0# ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'
```

Create monitor keyring

```
root@cephmon0# ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
```

Add client.admin keyring into ceph.mon keyring

```
root@cephmon0# ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
```

Create the monitor map

```
root@cephmon0# monmaptool --create --add cephmon0 192.168.200.157 --fsid a7f64266-0894-4f1e-a635-d0aeaca0e993 /tmp/monmap

monmaptool: monmap file /tmp/monmap
monmaptool: set fsid to a7f64266-0894-4f1e-a635-d0aeaca0e993
monmaptool: writing epoch 0 to /tmp/monmap (1 monitors)
```

Populate the monitor daemon(s) with the monitor map and keyring.

```
root@cephmon0# ceph-mon --mkfs -i cephmon0 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring --setuser ceph --setgroup ceph

ceph-mon: set fsid to a7f64266-0894-4f1e-a635-d0aeaca0e993
ceph-mon: created monfs at /var/lib/ceph/mon/ceph-cephmon0 for mon.cephmon0
```
Create done file

```
root@cephmon0# touch /var/lib/ceph/mon/ceph-cephmon0/done
root@cephmon0# chown ceph:ceph /var/lib/ceph/mon/ceph-cephmon0/done
```

Autostart

```
root@cephmon0# systemctl enable ceph-mon@cephmon0
root@cephmon0# systemctl start ceph-mon@cephmon0
```

### Configure Ceph OSD

On Ceph Monitor Node

#### Create new OSD and Add new OSD entry to Cluster and get the OSD ID
```
root@cephmon0# ceph osd create 
0
```
Note: In this example osd id is 0

#### Partition (On Ceph OSD Node)

```
root@cephnode0# sgdisk --mbrtogpt -- /dev/sdc
root@cephnode0# mkfs.xfs /dev/sdc -f
```

#### Making the osd node directory

```
root@cephnode0# mkdir /var/lib/ceph/osd/ceph-0
```
Note: The ceph "ceph-0" is represent a cluster call "ceph", and the "0" in
"ceph-0" represent the osd id

#### Mount the disk to osd directory

```
root@cephnode0#mount /dev/sdc1 /var/lib/ceph/osd/ceph-0
chown ceph:ceph /var/lib/ceph/osd/ceph-0
```

#### Initial OSD

```
ceph-osd -i 0 --mkfs --mkkey --setuser ceph --setgroup ceph
```
Note: The `-i 0` means using osid = 0, and `--setuser ceph --setgroup ceph` means generate the initial file with owner by ceph:ceph, so the `ceph-osd` can use user `ceph` to run a ceph-osd service

#### Register the OSD authentication key

copy ceph monitor's /etc/ceph/ceph.client.admin.keyring to ceph OSD node /etc/ceph/ceph.client.admin.keyring

```
ceph auth add osd.0 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-0/keyring
```

#### Add host bucket and move it under "default"

```
ceph osd crush add-bucket cephnode0 host
ceph osd crush move cephnode0 root=default
```

#### Add OSD to CRUSH map

```
ceph osd crush add osd.0 1 root=default host=cephnode0
```

#### Add fstab entry for automount

```
DISK_UUID=$(ls /dev/disk/by-uuid/ -alh | grep sdc | awk '{print $9}')
echo "UUID=$DISK_UUID /var/lib/ceph/osd/ceph-0 xfs defaults 0 0" >> /etc/fstab
```

#### Systemd service

```
systemctl start ceph-osd@0
systemctl enable ceph-osd@0
```

#### simple script for automatic add new drive into ceph storage pool

```
#For hdd osd
#!/bin/bash

OSD_ID=$(ceph osd create)
sgdisk --mbrtogpt -- /dev/"$1"
mkfs.xfs /dev/"$1" -f
mkdir /var/lib/ceph/osd/ceph-$OSD_ID
mount /dev/"$1" /var/lib/ceph/osd/ceph-$OSD_ID
chown ceph:ceph /var/lib/ceph/osd/ceph-$OSD_ID
ceph-osd -i $OSD_ID --mkfs --mkkey --setuser ceph --setgroup ceph
ceph auth add osd.$OSD_ID osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-$OSD_ID/keyring
ceph osd crush add-bucket $HOSTNAME host
ceph osd crush move $HOSTNAME root=default
ceph osd crush add osd.$OSD_ID 1 root=default host=$HOSTNAME
systemctl start ceph-osd@$OSD_ID
systemctl enable ceph-osd@$OSD_ID

DISK_UUID=$(ls /dev/disk/by-uuid/ -alh | grep $1 | awk '{print $9}')
echo "UUID=$DISK_UUID /var/lib/ceph/osd/ceph-$OSD_ID xfs defaults 0 0" >> /etc/fstab
```
save it into `auto_add_osd_hdd.sh` file and use it `bash auto_add_osd_hdd.sh sdc`
Be careful, this script will format your harddrive, cause you lost all you data in the device you put it.
So really careful.




### To be continued


#### Reference:
http://docs.ceph.com/docs/jewel/architecture/   
http://docs.ceph.com/docs/jewel/install/manual-deployment/   
http://docs.ceph.com/docs/jewel/rados/configuration/auth-config-ref/   

