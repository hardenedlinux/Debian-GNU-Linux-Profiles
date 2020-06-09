## Manually deploy ceph cluster step by step

##### Tesing environment
```
OS: Debian 10 
Ceph: 15.2.1 octopus (bluestore)
Network Adapter: Mellanox ConnectX4 40/56Gb
Switch: Mellanox SX1012
Hard Drive: Dell Enterprise Hard 6TB 7.2K SAS 12 Gbps x6 per OSD node
Solid State Drive: Intel S3710 x2 RAID 1 for OS
PCI-E Solid State Drive: Intel 750 1.2TB x1 per OSD node
```

##### Machine information
```
Hostname: ceph0
IP address: 192.168.195.10

Hostname: ceph1
IP address: 192.168.195.11

Hostname: ceph2
IP address: 192.168.195.12
```



### Install Ceph package

Install Ceph Release key

```
apt install gnupg2 sudo curl vim uuid-runtime -y
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
```

Add source
/etc/apt/sources.list.d/ceph.list
```
cat >/etc/apt/sources.list.d/ceph.list <<EOF
deb http://mirrors.ustc.edu.cn/ceph/debian-octopus buster main
deb-src http://mirrors.ustc.edu.cn/ceph/debian-octopus buster main
EOF
```
note: you could also using official repo `https://download.ceph.com/debian-octopus`   

update and install
```
apt update
apt install ceph
```

### Configuration

#### Ceph Monitor
generate for ceph cluster
```
uuidgen
c9fc98d6-e691-4ea3-bb6e-c4beadc0eeb0
```

/etc/ceph/ceph.conf
```
fsid = c9fc98d6-e691-4ea3-bb6e-c4beadc0eeb0
mon initial members = ceph0
mon host = 192.168.0.10
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
public network = 192.168.0.0/20
cluster network = 192.168.20.0/24
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
mon_allow_pool_delete = true
osd pool default size = 3
osd pool default min size = 1
osd pool default pg num = 128
osd pool default pgp num = 128
osd crush chooseleaf type = 1
mon_pg_warn_max_object_skew = 20
mon_max_pg_per_osd = 400

[mon.ceph0]
    host = ceph0
    mon addr = 192.168.0.10
```

Create a keyring for your cluster and generate a monitor secret key.

```
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
```

Generate an administrator keyring, generate a client.admin user and add the user to the keyring.
```
sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
```
Generate a bootstrap-osd keyring, generate a client.bootstrap-osd user and add the user to the keyring.

```
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
```

Change the owner for ceph.mon.keyring.

```
sudo chown ceph:ceph /tmp/ceph.mon.keyring
```

Generate a monitor map using the hostname(s), host IP address(es) and the FSID. Save it as `/tmp/monmap`

```
monmaptool --create --add {hostname} {ip-address} --fsid {uuid} /tmp/monmap
```
For example:

```
monmaptool --create --add ceph0 192.168.195.10 --fsid c9fc98d6-e691-4ea3-bb6e-c4beadc0eeb0 /tmp/monmap
```

Create a default data directory (or directories) on the monitor host(s).

```
sudo mkdir /var/lib/ceph/mon/{cluster-name}-{hostname}
```
For example
```
sudo -u ceph mkdir /var/lib/ceph/mon/ceph-ceph0
```

Populate the monitor daemon(s) with the monitor map and keyring.

```
sudo -u ceph ceph-mon [--cluster {cluster-name}] --mkfs -i {hostname} --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
```
For example

```
sudo -u ceph ceph-mon --mkfs -i ceph0 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
```

Start ceph-mon service

```
systemctl start ceph-mon@ceph0
```

Check ceph cluster status

```
ceph -s
```
Enable the ceph-mon service
```
systemctl enable ceph-mon@ceph0
```

#### Enable msgr2

```
ceph mon enable-msgr2
```

#### Add more ceph monitor

On new monitor node `ceph1(192.168.195.11)`
```
sudo -u ceph mkdir /var/lib/ceph/mon/ceph-ceph1
```
On first monitor node `ceph0(192.168.195.10)`

Retrieve the keyring for your monitors
```
ceph auth get mon. -o /tmp/ceph.mon.keyring
```
Retrieve the monitor map
```
ceph mon getmap -o /tmp/ceph.map
```
copy the `ceph.mon.keyring` and `ceph.map` to new monitor node `ceph1(192.168.195.11)`

on new monitor node `ceph1(192.168.195.11)`
```
sudo -u ceph ceph-mon --mkfs -i ceph1 --monmap /home/debian/ceph.map --keyring /home/debian/ceph.mon.keyring
```
Start ceph-mon service

```
systemctl start ceph-mon@ceph1
```

Check ceph cluster status

```
ceph -s
```
Enable the ceph-mon service
```
systemctl enable ceph-mon@ceph1
```

Quote from official document
>It is advisable to run an odd-number of monitors but not mandatory. An odd-number of monitors has a higher resiliency to failures than an even-number of monitors. For instance, on a 2 monitor deployment, no failures can be tolerated in order to maintain a quorum; with 3 monitors, one failure can be tolerated; in a 4 monitor deployment, one failure can be tolerated; with 5 monitors, two failures can be tolerated. This is why an odd-number is advisable. Summarizing, Ceph needs a majority of monitors to be running (and able to communicate with each other), but that majority can be achieved using a single monitor, or 2 out of 2 monitors, 2 out of 3, 3 out of 4, etc.
>
>For an initial deployment of a multi-node Ceph cluster, it is advisable to deploy three monitors, increasing the number two at a time if a valid need for more than three exists.

and repeate adding the third monitor

#### Ceph Manager Daemon

On master node `ceph0`
```
sudo ceph auth get-or-create mgr.$name mon 'allow profile mgr' osd 'allow *' mds 'allow *'
```
For example
```
sudo ceph auth get-or-create mgr.ceph0 mon 'allow profile mgr' osd 'allow *' mds 'allow *'
```
Creating the directory for ceph-mgr
```
sudo -u ceph mkdir /var/lib/ceph/mgr/ceph-ceph0
```
Put the key into `/var/lib/ceph/mgr/ceph-ceph0/keyring`
```
chown ceph:ceph /var/lib/ceph/mgr/ceph-ceph0/keyring
```
Start Ceph-mgr service

```
systemctl start ceph-mgr@ceph0
```
Enable Ceph-mgr service
```
systemctl enable ceph-mgr@ceph0
```

Repeate adding the second and third mgr on `ceph1` and `ceph2`


#### Adding Ceph OSD

Ceph OSD node:

```
/dev/nvme0n1 #Intel 750 1.2T SSD
/dev/sdc     #6t hdd
/dev/sdd     #6t hdd
/dev/sde     #6t hdd
/dev/sdf     #6t hdd
/dev/sdg     #6t hdd
/dev/sdh     #6t hdd
```

On master node `ceph0`
Retrieve the keyring for bootstrap osd
```
ceph auth get client.bootstrap-osd
```
put it into `/var/lib/ceph/bootstrap-osd/ceph.keyring`

Change permission

```
chown ceph:ceph /var/lib/ceph/bootstrap-osd/ceph.keyring
```

>A WAL device can be used for BlueStore’s internal journal or write-ahead log. It is identified by the block.wal symlink in the data directory. It is only useful to use a WAL device if the device is faster than the primary device (e.g., when it is on an SSD and the primary device is an HDD).

>A DB device can be used for storing BlueStore’s internal metadata. BlueStore (or rather, the embedded RocksDB) will put as much metadata as it can on the DB device to improve performance. If the DB device fills up, metadata will spill back onto the primary device (where it would have been otherwise). Again, it is only helpful to provision a DB device if it is faster than the primary device.

Prepare the PCIE SSD for `wal` and `db` 
```
/sbin/ceph-volume lvm zap /dev/nvme0n1
/sbin/pvcreate /dev/nvme0n1
/sbin/vgcreate ceph-ssd-pool /dev/nvme0n1
/sbin/lvcreate -n osd0.wal -L 2G ceph-ssd-pool
/sbin/lvcreate -n osd0.db -L 198G ceph-ssd-pool
/sbin/lvcreate -n osd1.wal -L 2G ceph-ssd-pool
/sbin/lvcreate -n osd1.db -L 198G ceph-ssd-pool
/sbin/lvcreate -n osd2.wal -L 2G ceph-ssd-pool
/sbin/lvcreate -n osd2.db -L 198G ceph-ssd-pool
/sbin/lvcreate -n osd3.wal -L 2G ceph-ssd-pool
/sbin/lvcreate -n osd3.db -L 198G ceph-ssd-pool
/sbin/lvcreate -n osd4.wal -L 2G ceph-ssd-pool
/sbin/lvcreate -n osd4.db -L 198G ceph-ssd-pool
/sbin/lvcreate -n osd5.wal -L 2G ceph-ssd-pool
/sbin/lvcreate -n osd5.db -l 100%FREE ceph-ssd-pool
```

Zapping many raw devices

```
/sbin/ceph-volume lvm zap /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh 
```

Using `ceph-volume` to create osd
```
sudo -s # for $PATH env
ID=0;DEVICE=/dev/sdc;/sbin/ceph-volume lvm create --bluestore --data $DEVICE --block.wal ceph-ssd-pool/osd$ID.wal --block.db ceph-ssd-pool/osd$ID.db
ID=1;DEVICE=/dev/sdd;/sbin/ceph-volume lvm create --bluestore --data $DEVICE --block.wal ceph-ssd-pool/osd$ID.wal --block.db ceph-ssd-pool/osd$ID.db
ID=2;DEVICE=/dev/sde;/sbin/ceph-volume lvm create --bluestore --data $DEVICE --block.wal ceph-ssd-pool/osd$ID.wal --block.db ceph-ssd-pool/osd$ID.db
ID=3;DEVICE=/dev/sdf;/sbin/ceph-volume lvm create --bluestore --data $DEVICE --block.wal ceph-ssd-pool/osd$ID.wal --block.db ceph-ssd-pool/osd$ID.db
ID=4;DEVICE=/dev/sdg;/sbin/ceph-volume lvm create --bluestore --data $DEVICE --block.wal ceph-ssd-pool/osd$ID.wal --block.db ceph-ssd-pool/osd$ID.db
ID=5;DEVICE=/dev/sdh;/sbin/ceph-volume lvm create --bluestore --data $DEVICE --block.wal ceph-ssd-pool/osd$ID.wal --block.db ceph-ssd-pool/osd$ID.db
```

If you encounter some error like below
```
unning command: /usr/bin/ceph-authtool --gen-print-key
Running command: /usr/bin/ceph --cluster ceph --name client.bootstrap-osd --keyring /var/lib/ceph/bootstrap-osd/ceph.keyring -i - osd new f20214fe-8472-4742-b4b3-6dee58972ad4
Running command: /usr/sbin/lvcreate --yes -l 100%FREE -n osd-block-f20214fe-8472-4742-b4b3-6dee58972ad4 ceph-5a85dd02-6fa3-4270-aff1-f58d5dcdac08
 stderr: Calculated size of logical volume is 0 extents. Needs to be larger.
--> Was unable to complete a new OSD, will rollback changes
Running command: /usr/bin/ceph --cluster ceph --name client.bootstrap-osd --keyring /var/lib/ceph/bootstrap-osd/ceph.keyring osd purge-new osd.6 --yes-i-really-mean-it
 stderr: 2020-05-07T11:59:00.891+0800 7fd2b1797700 -1 auth: unable to find a keyring on /etc/ceph/ceph.client.bootstrap-osd.keyring,/etc/ceph/ceph.keyring,/etc/ceph/keyring,/etc/ceph/keyring.bin,: (2) No such file or directory
2020-05-07T11:59:00.891+0800 7fd2b1797700 -1 AuthRegistry(0x7fd2ac058b78) no keyring found at /etc/ceph/ceph.client.bootstrap-osd.keyring,/etc/ceph/ceph.keyring,/etc/ceph/keyring,/etc/ceph/keyring.bin,, disabling cephx
 stderr: purged osd.6
-->  RuntimeError: command returned non-zero exit status: 5
```
check with `lsblk`
```
sdc                                                                                                     8:32   0   5.5T  0 disk  
└─ceph--5a85dd02--6fa3--4270--aff1--f58d5dcdac08-osd--block--c9bf4fe3--662e--4fa8--9ca7--e64cd4d6bf16 253:14   0   5.5T  0 lvm   
```
It means last osd create preparation was some how fail and the drive `/dev/sdc` has been made as `physical volume` device and create a random `volume group` call `ceph-5a85dd02-6fa3-4270-aff1-f58d5dcdac08` and `logic volume` call `osd-block-c9bf4fe3-662e-4fa8-9ca7-e64cd4d6bf16`

So we have to delete those device and make the `/dev/sdc` as raw drive

```
lvremove /dev/ceph-5a85dd02-6fa3-4270-aff1-f58d5dcdac08/osd-block-c9bf4fe3-662e-4fa8-9ca7-e64cd4d6bf16
vgremove /dev/ceph-5a85dd02-6fa3-4270-aff1-f58d5dcdac08
pvremove /dev/sdc
```
And Zap again and run `ceph-volume` again  
Like following command
```
ID=0;DEVICE=/dev/sdc;/sbin/ceph-volume lvm create --bluestore --data $DEVICE --block.wal ceph-ssd-pool/osd$ID.wal --block.db ceph-ssd-pool/osd$ID.db
```

#### Ceph Block Device

Create rbd

```
ceph osd pool create vms
rbd pool init vms
ceph osd pool application enable vms rbd
```
#### CephFS

```
ceph fs volume create datacenter
```
Create an mds data point `/var/lib/ceph/mds/ceph-${id}` on mds node
```
sudo -u ceph mkdir /var/lib/ceph/mds/ceph-ceph0
```
Create the keyring for mds
```
sudo ceph auth get-or-create mds.ceph0 mon 'profile mds' mgr 'profile mds' mds 'allow *' osd 'allow *' 
```
and put it on mds node's  `/var/lib/ceph/mds/ceph-ceph0/keyring`

Start the ceph mds service
```
systemctl start ceph-mds@ceph0
```
Enable the ceph-mds service
```
systemctl start ceph-mds@ceph0
```


### Reference:

https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_Buster   
https://ceph.readthedocs.io/en/latest/install/manual-deployment/   
https://docs.ceph.com/docs/master/rados/operations/add-or-rm-mons/   
https://docs.ceph.com/docs/master/rados/deployment/ceph-deploy-osd/   
