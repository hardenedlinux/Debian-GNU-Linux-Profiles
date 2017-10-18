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
mon initial members = cephmon0
mon host = 192.168.200.157
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
root@cephmon0# chown ceph:ceph /tmp/ceph.mon.keyring
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

#### SSD Cache Tiering
You must direct all client traffic from the storage pool to the cache pool.

##### Add SSD Based OSD

To add a SSD Cache Tiering, we should add new `root` bucket other then `default` root bucket, such as root bucket call ssd

```
ceph osd crush add-bucket ssd root
```
and add new hostname to split hdd and sdd, such as `cephnode0-ssd` and `cephnode1-ssd`
```
ceph osd crush add-bucket cephnode0-ssd host
```
and add the SSD drive into cluster just like before, you can just read the script show as below

```
#!/bin/bash

#ceph osd crush add-bucket ssd root
#for ssd pool

OSD_ID=$(ceph osd create)
sgdisk --mbrtogpt -- /dev/"$1"
mkfs.xfs /dev/"$1" -f
mkdir /var/lib/ceph/osd/ceph-$OSD_ID
mount /dev/"$1" /var/lib/ceph/osd/ceph-$OSD_ID
chown ceph:ceph /var/lib/ceph/osd/ceph-$OSD_ID
ceph-osd -i $OSD_ID --mkfs --mkkey --setuser ceph --setgroup ceph
ceph auth add osd.$OSD_ID osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-$OSD_ID/keyring
ceph osd crush add-bucket "$HOSTNAME"-ssd host
ceph osd crush move "$HOSTNAME"-ssd root=ssd
ceph osd crush add osd.$OSD_ID 1 root=ssd host="$HOSTNAME"-ssd
systemctl start ceph-osd@$OSD_ID
systemctl enable ceph-osd@$OSD_ID

DISK_UUID=$(ls /dev/disk/by-uuid/ -alh | grep $1 | awk '{print $9}')
echo "UUID=$DISK_UUID /var/lib/ceph/osd/ceph-$OSD_ID xfs defaults 0 0" >> /etc/fstab
```
save in as `auto_add_ssd_osd.sh` and use it like this `bash auto_add_ssd_osd.sh nvme0n1`
(because the intel 750 pcie ssd localtion is /dev/nvme0n1)

Note we add a host bucket call "cephnode0-ssd" and move it into `ssd` root bucket. But every time we restart the osd service
in this OSD, it will run the `/usr/lib/ceph/ceph-osd-prestart.sh` and this script will run the `/usr/bin/ceph-crush-location ` and this tool will pass the `$HOSTNAME` to the CRUSH map, so if the `osd.18` is the SSD based OSD, under the `cephnode0-ssd` ("$HOSTNAME"-ssd) under the root bucket call `ssd`. after we restart the service the `host` of `osd.18` will change from `"$HOSTNAME"-ssd` into `"$HOSTNAME"`. So we should manually assign the host of this kind of osd. In the `/etc/ceph/ceph.conf`

```
[osd.18]
    osd crush location = "root=ssd host=cephnode0-ssd"
```
so the osd tree show as below
```
ceph osd tree

ID WEIGHT   TYPE NAME              UP/DOWN REWEIGHT PRIMARY-AFFINITY 
-5  3.00000 root ssd                                                 
-7  1.00000     host cephnode1-ssd                                   
19  1.00000         osd.19              up  1.00000          1.00000 
-8  1.00000     host cephnode2-ssd                                   
20  1.00000         osd.20              up  1.00000          1.00000 
-6  1.00000     host cephnode0-ssd                                   
18  1.00000         osd.18              up  1.00000          1.00000 
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

##### Add new ruleset

after we put all the SSD based OSD into one root bucket, we can set some rules to let pool only use this bucket.


Get the CRUSH map
```
ceph osd getcrushmap -o crushmap
```
Decompile the CRUSH map
```
crushtool -d crushmap -o decompiled-crushmap
```

Now we can edit the CRUSH map and add one rule for ssd bucket

```
cat decompiled-crushmap
# begin crush map
tunable choose_local_tries 0
tunable choose_local_fallback_tries 0
tunable choose_total_tries 50
tunable chooseleaf_descend_once 1
tunable chooseleaf_vary_r 1
tunable straw_calc_version 1

# devices
device 0 osd.0
device 1 osd.1
device 2 osd.2
device 3 osd.3
device 4 osd.4
device 5 osd.5
device 6 osd.6
device 7 osd.7
device 8 osd.8
device 9 osd.9
device 10 osd.10
device 11 osd.11
device 12 osd.12
device 13 osd.13
device 14 osd.14
device 15 osd.15
device 16 osd.16
device 17 osd.17
device 18 osd.18
device 19 osd.19
device 20 osd.20

# types
type 0 osd
type 1 host
type 2 chassis
type 3 rack
type 4 row
type 5 pdu
type 6 pod
type 7 room
type 8 datacenter
type 9 region
type 10 root

# buckets
host cephnode0 {
	id -2		# do not change unnecessarily
	# weight 6.000
	alg straw
	hash 0	# rjenkins1
	item osd.0 weight 1.000
	item osd.1 weight 1.000
	item osd.2 weight 1.000
	item osd.3 weight 1.000
	item osd.4 weight 1.000
	item osd.5 weight 1.000
}
host cephnode1 {
	id -3		# do not change unnecessarily
	# weight 6.000
	alg straw
	hash 0	# rjenkins1
	item osd.6 weight 1.000
	item osd.7 weight 1.000
	item osd.8 weight 1.000
	item osd.10 weight 1.000
	item osd.11 weight 1.000
	item osd.9 weight 1.000
}
host cephnode2 {
	id -4		# do not change unnecessarily
	# weight 6.000
	alg straw
	hash 0	# rjenkins1
	item osd.12 weight 1.000
	item osd.13 weight 1.000
	item osd.14 weight 1.000
	item osd.15 weight 1.000
	item osd.16 weight 1.000
	item osd.17 weight 1.000
}
root default {
	id -1		# do not change unnecessarily
	# weight 18.000
	alg straw
	hash 0	# rjenkins1
	item cephnode0 weight 6.000
	item cephnode1 weight 6.000
	item cephnode2 weight 6.000
}
host cephnode1-ssd {
	id -7		# do not change unnecessarily
	# weight 1.000
	alg straw
	hash 0	# rjenkins1
	item osd.19 weight 1.000
}
host cephnode2-ssd {
	id -8		# do not change unnecessarily
	# weight 1.000
	alg straw
	hash 0	# rjenkins1
	item osd.20 weight 1.000
}
host cephnode0-ssd {
	id -6		# do not change unnecessarily
	# weight 1.000
	alg straw
	hash 0	# rjenkins1
	item osd.18 weight 1.000
}
root ssd {
	id -5		# do not change unnecessarily
	# weight 3.000
	alg straw
	hash 0	# rjenkins1
	item cephnode1-ssd weight 1.000
	item cephnode2-ssd weight 1.000
	item cephnode0-ssd weight 1.000
}

# rules
rule replicated_ruleset {
	ruleset 0
	type replicated
	min_size 1
	max_size 10
	step take default
	step chooseleaf firstn 0 type host
	step emit
}

# end crush map
```
We can see the last part of crush map is the `rules`

```
# rules
rule replicated_ruleset {
	ruleset 0
	type replicated
	min_size 1
	max_size 10
	step take default
	step chooseleaf firstn 0 type host
	step emit
}
```
This is the default rule for default pool, and the `ruleset` is `0`

we can add second rule after this rule.

```
rule ssd-primary {
	ruleset 1
	type replicated
	min_size 0
	max_size 4
	step take ssd
	step chooseleaf firstn 0 type host
	step emit
}
```
in the `step take <bucket-name>` option, we set the `ssd` root bucket. Every pool use this ruleset will use the `ssd` bucket only.
for more detail you can visit: http://docs.ceph.com/docs/jewel/rados/operations/crush-map/ 

recompile the crush map
```
crushtool -c decompiled-crushmap -o new-crush-map
```
update the new crush map to your cluster

```
ceph osd setcrushmap -i new-crush-mapeew-crush-mapw-crush-map
```

##### Create ssd-cache pool

```
ceph osd pool create <pool name> <pg number> <crush-ruleset-name>
```
for an example
```
ceph osd pool create ssd-cache 1024 ssd-primary
```

the why of pg number is 1024 because there is a formula   

for more detail: http://docs.ceph.com/docs/jewel/rados/operations/placement-groups/#choosing-the-number-of-placement-groups

Total PGs = （OSDs * 100）/ replicas   

(21 OSD * 100) / 3 = 700   

Nearest power of 2: 1024   

##### Setting up the cache pool

first we should create an hdd pool for daily use.

```
ceph osd pool create libvirt 1024
```
setting the cache tier####
```
ceph osd tier add {storagepool} {cachepool}
```
for example
```
ceph osd tier add libvirt ssd-cache
```

setting the cache mode
```
ceph osd tier cache-mode {cachepool} {cache-mode}
```
for example
```
ceph osd tier cache-mode ssd-cache writeback
```
You must direct all client traffic from the storage pool to the cache pool.
setting the overlay.  
```
ceph osd tier set-overlay {storagepool} {cachepool}
```
for example
```
ceph osd tier set-overlay libvirt ssd-cache
```
setting cache pool type

```
ceph osd pool set {cachepool} hit_set_type bloom
```
for example
```
ceph osd pool set ssd-cache hit_set_type bloom
```

### Ceph with libvirt

Install the libvirt and librbd and other package.


```
apt install qemu-kvm libvirt-clients libvirt-daemon-system qemu-block-extra 
```
for qemu-system-x86_64 and libvirtd with PaX/Grsecurity
```
paxctl-ng -perms /usr/bin/qemu-system-x86_64
paxctl-ng -perms /usr/sbin/libvirtd
```

Create the libvirt pool (already create it before)

```
ceph osd pool create libvirt 1024 1024
```

Create the Ceph user.

```
ceph auth get-or-create client.libvirt mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=libvirt'
```
the `client.libvirt` means a user name `libvirt`, and `mon 'allow r'` means allow read permission for monitor, `osd 'allow class-read object_prefix rbd_children'` means allow user to call `class-read` method to `rbd_children` which record the snapshot `parent` and `childern` relationship. And allow read, write, and call both read, wirte class method to pool `libvirt`

the you will get and keyring.

you can verify it by this command.

```
ceph auth list
```

#### Test with qemu-img

Copy the /etc/ceph/ceph.conf to libvirt host

and create /etc/ceph/ceph.client.libvirt.keyring, such as

```
[client.libvirt]
	key = AQCPPo9Z4yukHRAXdnjDfxbn0GfHr0JJI9mg==
```


```
qemu-img create -f raw rbd:<pool name>/<new-image-new>:id=<user>:conf=/etc/ceph/ceph.conf 20G
```
for example
```
qemu-img create -f raw rbd:libvirt/debian9-netinstall:id=libvirt:conf=/etc/ceph/ceph.conf 40G
Formatting 'rbd:libvirt/debian9-netinstall:id=libvirt:conf=/etc/ceph/ceph.conf', fmt=raw size=42949672960
```
check the image by using

```
qemu-img info  rbd:libvirt/debian9-netinstall:id=libvirt:conf=/etc/ceph/ceph.conf
image: rbd:libvirt/debian9-netinstall:id=libvirt:conf=/etc/ceph/ceph.conf
file format: raw
virtual size: 40G (42949672960 bytes)
disk size: unavailable
cluster_size: 4194304
```

Using Virt-manager to create a Virtual Machine (without enable the storage for this virtual machine)
And we manually add the ceph block device to this virtual machine.

```
virsh list --all
 Id    Name                           State
----------------------------------------------------
 -     debian9                        shut off
```
before we add the rbd, we should create a libvirt secret first

```
cat > libvirt-secret.xml <<EOF
<secret ephemeral='no' private='no'>
        <usage type='ceph'>
                <name>client.libvirt secret</name>
        </usage>
</secret>
EOF
```
Define the secret
```
virsh secret-define --file libvirt-secret.xml
Secret d550132c-ed06-4ece-bf45-570693cb0b8b created
```
Get the client.libvirt key and save the key string to a file

You can get the key from your monitor host by execute this command.
```
auth get-key client.libvirt |  tee client.libvirt.key
cat client.libvirt.key
AQCPPo9Z4yukHRAXdnjDfxbn0GfHr0JJI9mg==
```

```
virsh secret-set-value --secret {uuid of secret} --base64 $(cat client.libvirt.key) && rm client.libvirt.key libvirt-secret.xml
```
for example
```
virsh secret-set-value --secret d550132c-ed06-4ece-bf45-570693cb0b8b --base64 $(cat client.libvirt.key)
Secret value set
```
and add the 

```
<disk type='network' device='disk'>
  <source protocol='rbd' name='libvirt/debian9-netinstall'>
    <host name='176.16.0.10' port='6789'/>
    <host name='176.16.0.11' port='6789'/>
    <host name='176.16.0.12' port='6789'/>
  </source>
  <auth username='libvirt'>
  <secret type='ceph' uuid='d550132c-ed06-4ece-bf45-570693cb0b8b'/>
  </auth>
  <target dev='vda' bus='virtio'/>
</disk>
```
to the virsh xml

due to some xml problem
```
Failed. Try again? [y,n,i,f,?]: 
error: XML document failed to validate against schema: Unable to validate doc against /usr/share/libvirt/schemas/domain.rng
Extra element devices in interleave
Element domain failed to validate content
```
We can't use virsh edit just now. So we can dump the xml and undefine the domain and redefine it.

```
virsh dumpxml debian9 >debian9.xml
```
edit the debian9.xml

undefine the domain
```
virsh undefine debian9
```
redefine the domain
```
virsh define debian9.xml
```

Enjoy the ceph block device with libvirt

or

You can simply add the ceph pool into your libvirt pool

```
<pool type='rbd'>
  <name>ceph-libvirt-pool</name>
  <source>
    <host name='176.16.0.10' port='6789'/>
    <host name='176.16.0.11' port='6789'/>
    <host name='176.16.0.12' port='6789'/>
    <name>libvirt</name>
    <auth type='ceph' username='libvirt'>
      <secret uuid='d550132c-ed06-4ece-bf45-570693cb0b8b'/>
    </auth>
  </source>
</pool>
```
the `<name>libvirt</name>` it the ceph pool's name.
save this file in libvirt-pool.xml

```
virsh pool-define libvirt-pool.xml
virsh pool-start ceph-libvirt-pool
virsh pool-autostart ceph-libvirt-pool
Pool ceph-libvirt-pool marked as autostarted
```
So you can see the libvirt got a new storage call `ceph-libvirt-pool`. And you can use it to create new image and easily mount to virtual machine.

#### Reference:
http://docs.ceph.com/docs/jewel/architecture/   
http://docs.ceph.com/docs/jewel/install/manual-deployment/   
http://docs.ceph.com/docs/jewel/rados/configuration/auth-config-ref/   
http://docs.ceph.com/docs/jewel/rados/operations/cache-tiering/
http://docs.ceph.com/docs/jewel/rados/operations/user-management/
http://docs.ceph.com/docs/master/rbd/rbd-snapshot/
