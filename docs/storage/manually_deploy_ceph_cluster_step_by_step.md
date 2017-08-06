### Manually Deploy Ceph Cluster Step-by-Step


### Basic Setup

#### Install PaX/Grsecurity kernel

For Security build-in policy we should install PaX/Grsecurity kernel right
after we finish the system installation

```
root@cephmon0# dpkg -i *.deb
```

#### Install Ceph

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
```
Create /etc/ceph/ceph.conf

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
Note: We using `uuidgen` to generate uuid


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

#### Create new OSD

Generate UUID

```
root@cephmon0# uuidgen 

c24ca5dd-0325-438c-b6bc-1de05688a1e1
```

#### Add new OSD entry to Cluster and get the OSD ID
```
root@cephmon0# ceph osd create adfa4a36-e12e-4e11-875b-ceda0ec9a228
0
```
Note: In this example osd id is 0

#### Partition (On Ceph OSD Node)

```
root@cephnode0# apt install parted -y
root@cephnode0# parted /dev/sdc mklabel gpt
root@cephnode0# #make new partition /dev/sdc1
root@cephnode0# mkfs.xfs /dev/sdc1
```

Making the osd node directory

```
root@cephnode0# mkdir /var/lib/ceph/osd/ceph-0
```
Note: The ceph "ceph-0" is represent a cluster call "ceph", and the "0" in
"ceph-0" represent the osd id

Mount the disk to osd directory

```
root@cephnode0#mount /dev/sdc1 /var/lib/ceph/osd/ceph-0
```

### To be continued


#### Reference:
http://docs.ceph.com/docs/master/architecture/   
http://docs.ceph.com/docs/master/install/manual-deployment/   
http://docs.ceph.com/docs/master/rados/configuration/auth-config-ref/   

