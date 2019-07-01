## Install Ceph Object Storage

### Architecture

3 physical machine, 10 OSD and 1 monitor and 1 mgr per machine

### Install

On node1 (Monitor 1)

```
apt install radosgw
```
### Configure gateway

edit `/etc/ceph/ceph.conf`

add following content

```
[client.rgw.<obj_gw_hostname>]
host = <obj_gw_hostname>
rgw frontends = "civetweb port=7480"
rgw dns name = <obj_gw_hostname>.example.com
```

for example

```
[client.rgw.node1]
host = node1
rgw frontends = "civetweb port=7480"
rgw dns name = node1.example.com
```

create radosgw node dir

```
# mkdir -p /var/lib/ceph/radosgw/<cluster_name>-rgw.`hostname -s`
```
for example 

```
mkdir -p /var/lib/ceph/radosgw/ceph-rgw.node1
```

Create Object Gateway keyring

```
ceph auth get-or-create client.rgw.`hostname -s` osd 'allow rwx' mon 'allow rw' -o /var/lib/ceph/radosgw/<cluster_name>-rgw.`hostname -s`/keyring
```
for example

```
ceph auth get-or-create client.rgw.node1 osd 'allow rwx' mon 'allow rw' -o /var/lib/ceph/radosgw/ceph-rgw.node1/keyring
```
create done file

```
touch /var/lib/ceph/radosgw/ceph-rgw.node1/done
```
change permissions

```
chown -R ceph:ceph /var/lib/ceph/radosgw
```

### Test

Configurate Custom Domain

```
apt install dnsmasq
```

edit `/etc/dnsmasq.conf`

add following contents

Object Gateway IP: 192.168.1.120

```
server = 8.8.8.8
address = /.node1.example.com/192.168.1.120
```
restart dnsmasq service

```
systemctl restart dnsmasq
```

On Object Gateway Node

Create test user


```
radosgw-admin user create --uid="testuser" --display-name="First User"
{
    "user_id": "testuser",
    "display_name": "First User",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "subusers": [],
    "keys": [
        {
            "user": "testuser",
            "access_key": "UPHPDIXI65IB9IZCBSP5",
            "secret_key": "TIHTDiFMxaTHOecmgODnFrprlLWiUClfH4qgLWWi"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "default_storage_class": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "type": "rgw",
    "mfa_ids": []
}
```

Install python-boto package

```
apt install python-boto
```

vim s3test.py

```
import boto.s3.connection

access_key = 'UPHPDIXI65IB9IZCBSP5'
secret_key = 'TIHTDiFMxaTHOecmgODnFrprlLWiUClfH4qgLWWi'
conn = boto.connect_s3(
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        host='{hostname}', port={port},
        is_secure=False, calling_format=boto.s3.connection.OrdinaryCallingFormat(),
       )

bucket = conn.create_bucket('my-new-bucket')
for bucket in conn.get_all_buckets():
    print "{name} {created}".format(
        name=bucket.name,
        created=bucket.creation_date,
    )
```

save and run

```
python s3test.py 
my-new-bucket 2019-07-01T01:22:48.404Z
```

### Reference:

http://docs.ceph.com/docs/master/install/install-ceph-gateway/   
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html/installation_guide_for_red_hat_enterprise_linux/manually-installing-ceph-object-gateway   
