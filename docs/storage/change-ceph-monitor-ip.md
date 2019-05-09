## Change Ceph Cluster Monitor IP

#### Environment

3 OSD node: 6*6TB each
3 Monitor Node

Application: Libvirt RBD
rbd pool: libvirt

libvirt pool define profile
```
<pool type="rbd">
  <name>ceph-libvirt-pool</name>
  <source>
    <name>libvirt</name>
    <host name='172.16.50.20' port='6789'/>
    <host name='172.16.50.21' port='6789'/>
    <host name='172.16.50.22' port='6789'/>
    <auth username='libvirt' type='ceph'>
      <secret uuid='aaff1357-f3be-4d59-86cc-e8510f03d946'/>
    </auth>
  </source>
</pool>
```

### Stop the application


Stop all Virtual Machine that using RBD

```
virsh destroy {YOU VM}
```

on libvirt node

```
virsh pool-destroy ceph-libvirt-pool
```

stop the rbd based pool service

```
virsh pool-edit ceph-libvirt-pool
```

modify the monitor in the profile

```
<pool type='rbd'>
  <name>ceph-libvirt-pool</name>
  <uuid>6ad83445-f92a-4d9c-a9c7-d0d8c219f5e5</uuid>
  <capacity unit='bytes'>115177533849600</capacity>
  <allocation unit='bytes'>30663082059</allocation>
  <available unit='bytes'>111550491033600</available>
  <source>
    <host name='192.168.200.120' port='6789'/>
    <host name='192.168.200.120' port='6789'/>
    <host name='192.168.200.120' port='6789'/>
    <name>libvirt</name>
    <auth type='ceph' username='libvirt'>
      <secret uuid='aaff1357-f3be-4d59-86cc-e8510f03d946'/>
    </auth>
  </source>
</pool>
```

### Change Ceph Monitor IP

Getting monmap

```
ceph mon getmap -o /tmp/monmap
monmaptool --print /tmp/monmap

monmaptool: monmap file /tmp/monmap
epoch 5
fsid 2cf3o770-9j5d-42f2-ad21-1e38fffb161f
last_changed 2019-01-19 16:08:24.141547
created 2018-06-25 05:59:46.339005
min_mon_release 14 (nautilus)
0: [v2:172.16.50.20:3300/0,v1:172.16.50.20:6789/0] mon.mimicnode1
1: [v2:172.16.50.21:3300/0,v1:172.16.50.21:6789/0] mon.mimicnode2
2: [v2:172.16.50.22:3300/0,v1:172.16.50.22:6789/0] mon.mimicnode3
```

replace

```
monmaptool --rm mimicnode1   /tmp/monmap
monmaptool --add mimicnode1 192.168.200.120:6789 /tmp/monmap

monmaptool --rm mimicnode2   /tmp/monmap
monmaptool --add mimicnode2 192.168.200.121:6789 /tmp/monmap

monmaptool --rm mimicnode3   /tmp/monmap
monmaptool --add mimicnode3 192.168.200.122:6789 /tmp/monmap
```

```
monmaptool: monmap file /tmp/monmap
epoch 5
fsid 2cf3o770-9j5d-42f2-ad21-1e38fffb161f
last_changed 2019-04-19 16:08:24.141547
created 2018-06-25 05:59:46.339005
min_mon_release 14 (nautilus)
0: v1:192.168.200.120:6789/0 mon.mimicnode1
1: v1:192.168.200.121:6789/0 mon.mimicnode2
2: v1:192.168.200.122:6789/0 mon.mimicnode3
```

Shutdown hole cluster
On Monitor Node
```
systemctl stop ceph-mon.target
```
On Ceph OSD Node

```
systemctl stop ceph-osd.target
```

change `/etc/ceph/ceph.conf`
```
[global]
fsid = 2cf3o770-9j5d-42f2-ad21-1e38fffb161f
mon initial members = mimicnode1,mimicnode2,mimicnode3
mon host = [v2:172.16.50.20:3300/0,v1:172.16.50.20:6789/0],[v2:172.16.50.21:3300/0,v1:172.16.50.21:6789/0],[v2:172.16.50.22:3300/0,v1:172.16.50.22:6789/0]
public network = 172.16.50.0/24
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
mon_allow_pool_delete = true
osd pool default size = 1
osd pool default min size = 1
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1

[mon.mimicnode1]
    host = mimicnode1
    addr = 172.16.50.20

[mon.mimicnode2]
    host = mimicnode2
    addr = 172.16.50.21

[mon.mimicnode3]
    host = mimicnode2
    addr = 172.16.50.22
```

to

```
[global]
fsid = 2cf3o770-9j5d-42f2-ad21-1e38fffb161f
mon initial members = mimicnode1,mimicnode2,mimicnode3
mon host = 192.168.200.120:6789,192.168.200.121:6789,192.168.200.122:6789
public network = 192.168.200.120/24
cluster network = 172.16.50.0/24
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
mon_allow_pool_delete = true
osd pool default size = 1
osd pool default min size = 1
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1

[mon.mimicnode1]
    host = mimicnode1
    mon addr = 192.168.200.120

[mon.mimicnode2]
    host = mimicnode2
    mon addr = 192.168.200.121

[mon.mimicnode3]
    host = mimicnode3
    mon addr = 192.168.200.122
```

copy `/tmp/monmap` and updated `/etc/ceph/ceph.conf` to every ceph monitor node

on mimicnode1, run following command:

```
ceph-mon -i mimicnode1 --inject-monmap /tmp/monmap
```

on mimicnode2, run following command:

```
ceph-mon -i mimicnode2 --inject-monmap /tmp/monmap
```

on mimicnode3, run following command:

```
ceph-mon -i mimicnode3 --inject-monmap /tmp/monmap
```

and start the cephmon service


```
systemctl start ceph-mon.target
```

Now you can use `ceph -s` to check if monitor works

But you will see there's no v2 msgr

run following command:

```
ceph mon enable-msgr2
```

and update the /etc/ceph/ceph.conf on every node

```
mon host = [v2:192.168.200.120:3300/0,v1:192.168.200.120:6789],[v2:192.168.200.121:3300/0,v1:192.168.200.121:6789],[v2:192.168.200.122:3300/0,v1:192.168.200.122:6789]
```

restart mgr on every node

```
systemctl restart ceph-mgr.target
```

### Start the application



```
virsh pool-start ceph-libvirt-pool

virsh edit {your virtual machine} 

virsh start {your virtual machine} 
```


Reference:


http://docs.ceph.com/docs/mimic/man/8/monmaptool/   
http://mohankri.weebly.com/my-interest/ceph-monitor-ip-address-changed   
