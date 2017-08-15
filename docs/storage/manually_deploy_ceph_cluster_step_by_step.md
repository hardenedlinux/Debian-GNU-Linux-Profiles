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
git clone https://github.com/ceph/ceph.git
cd ceph
git checkout v10.2.9
```
modify `debian/rules` file and add `extraopts += --without-tcmalloc --with-jemalloc` under `extraopts += --without-tcmalloc --with-jemalloc`

Dealing the dependencies
```
apt-get install debhelper
dpkg-checkbuilddeps        # make sure we have all dependencies
```
And follow the missing dependencies list to get all the missing dependencies

After that build ceph

```
dpkg-buildpackage
```

```
$ cd ../
$ ls
ceph					 libcephfs1_10.2.9-1_amd64.deb
ceph-base_10.2.9-1_amd64.deb		 librados-dev_10.2.9-1_amd64.deb
ceph-common-dbg_10.2.9-1_amd64.deb	 librados2-dbg_10.2.9-1_amd64.deb
ceph-common_10.2.9-1_amd64.deb		 librados2_10.2.9-1_amd64.deb
ceph-fs-common-dbg_10.2.9-1_amd64.deb	 libradosstriper-dev_10.2.9-1_amd64.deb
ceph-fs-common_10.2.9-1_amd64.deb	 libradosstriper1-dbg_10.2.9-1_amd64.deb
ceph-fuse-dbg_10.2.9-1_amd64.deb	 libradosstriper1_10.2.9-1_amd64.deb
ceph-fuse_10.2.9-1_amd64.deb		 librbd-dev_10.2.9-1_amd64.deb
ceph-mds-dbg_10.2.9-1_amd64.deb		 librbd1-dbg_10.2.9-1_amd64.deb
ceph-mds_10.2.9-1_amd64.deb		 librbd1_10.2.9-1_amd64.deb
ceph-mon-dbg_10.2.9-1_amd64.deb		 librgw-dev_10.2.9-1_amd64.deb
ceph-mon_10.2.9-1_amd64.deb		 librgw2-dbg_10.2.9-1_amd64.deb
ceph-osd-dbg_10.2.9-1_amd64.deb		 librgw2_10.2.9-1_amd64.deb
ceph-osd_10.2.9-1_amd64.deb		 python-ceph_10.2.9-1_amd64.deb
ceph-resource-agents_10.2.9-1_amd64.deb  python-cephfs_10.2.9-1_amd64.deb
ceph-test-dbg_10.2.9-1_amd64.deb	 python-rados_10.2.9-1_amd64.deb
ceph-test_10.2.9-1_amd64.deb		 python-rbd_10.2.9-1_amd64.deb
ceph_10.2.9-1.dsc			 radosgw-dbg_10.2.9-1_amd64.deb
ceph_10.2.9-1.tar.gz			 radosgw_10.2.9-1_amd64.deb
ceph_10.2.9-1_amd64.buildinfo		 rbd-fuse-dbg_10.2.9-1_amd64.deb
ceph_10.2.9-1_amd64.changes		 rbd-fuse_10.2.9-1_amd64.deb
ceph_10.2.9-1_amd64.deb			 rbd-mirror-dbg_10.2.9-1_amd64.deb
libcephfs-dev_10.2.9-1_amd64.deb	 rbd-mirror_10.2.9-1_amd64.deb
libcephfs-java_10.2.9-1_all.deb		 rbd-nbd-dbg_10.2.9-1_amd64.deb
libcephfs-jni_10.2.9-1_amd64.deb	 rbd-nbd_10.2.9-1_amd64.deb
libcephfs1-dbg_10.2.9-1_amd64.deb
```
and install the package you need.

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
osd pool default size = 3
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

### A small cluster (3 storage node)

Each node has 6 * 6 TB Hard Drive, and 1 * 1.2 TB PCIE SSD.

So after we running previous `auto_add_osd_hdd.sh` with every HDD. we can get a osd tree like this

```
root@cephmon0# ceph osd tree
ID WEIGHT   TYPE NAME              UP/DOWN REWEIGHT PRIMARY-AFFINITY 
-1 18.00000 root default                                             
-2  6.00000     host cephnode0                                       
 0  1.00000         osd.0               up  1.00000          1.00000 
 1  1.00000         osd.1               up  1.00000          1.00000 
 2  1.00000         osd.2               up  1.00000          1.00000 
 3  1.00000         osd.3               up  1.00000          1.00000 
 4  1.00000         osd.4               up  1.00000          1.00000 
 5  1.00000         osd.5               up  1.00000          1.00000 
-3  6.00000     host cephnode1                                       
 6  1.00000         osd.6               up  1.00000          1.00000 
 7  1.00000         osd.7               up  1.00000          1.00000 
 8  1.00000         osd.8               up  1.00000          1.00000 
10  1.00000         osd.10              up  1.00000          1.00000 
11  1.00000         osd.11              up  1.00000          1.00000 
 9  1.00000         osd.9               up  1.00000          1.00000 
-4  6.00000     host cephnode2                                       
12  1.00000         osd.12              up  1.00000          1.00000 
13  1.00000         osd.13              up  1.00000          1.00000 
14  1.00000         osd.14              up  1.00000          1.00000 
15  1.00000         osd.15              up  1.00000          1.00000 
16  1.00000         osd.16              up  1.00000          1.00000 
17  1.00000         osd.17              up  1.00000          1.00000 
```
But there is not enough, because at this time. The cluster got shitty performance.

#### Simply benchmark

##### No split network, only use one 1Gb network adapter, using jemalloc, no other tuning

Note: `rbd` is default pool 

HDD 4k write
```
rados bench -p rbd 100 write --no-cleanup -b 4096

Total time run:         100.269021
Total writes made:      41043
Write size:             4096
Object size:            4096
Bandwidth (MB/sec):     1.59894
Stddev Bandwidth:       0.647372
Max bandwidth (MB/sec): 3.28125
Min bandwidth (MB/sec): 0.269531
Average IOPS:           409
Stddev IOPS:            165
Max IOPS:               840
Min IOPS:               69
Average Latency(s):     0.0390722
Stddev Latency(s):      0.074392
Max latency(s):         1.47944
Min latency(s):         0.00260458
```

HDD 4k seq read
```
rados bench -p rbd 100 seq

Total time run:       1.828573
Total reads made:     41043
Read size:            4096
Object size:          4096
Bandwidth (MB/sec):   87.6772
Average IOPS          22445
Stddev IOPS:          0
Max IOPS:             22173
Min IOPS:             22173
Average Latency(s):   0.000708072
Max latency(s):       0.0306722
Min latency(s):       0.000413685
```

HDD 4k rand read

```
rados bench -p rbd 100 rand

Total time run:       100.000634
Total reads made:     2365143
Read size:            4096
Object size:          4096
Bandwidth (MB/sec):   92.3878
Average IOPS:         23651
Stddev IOPS:          392
Max IOPS:             24434
Min IOPS:             22737
Average Latency(s):   0.000671967
Max latency(s):       0.0171427
Min latency(s):       0.000319885
```

As we can see, we really need some tuning.

#### SSD Cache Tiering



### To be continued


#### Reference:
http://docs.ceph.com/docs/jewel/architecture/   
http://docs.ceph.com/docs/jewel/install/manual-deployment/   
http://docs.ceph.com/docs/jewel/rados/configuration/auth-config-ref/   

