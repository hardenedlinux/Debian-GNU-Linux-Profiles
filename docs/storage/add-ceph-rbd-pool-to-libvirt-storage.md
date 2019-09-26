## Add Ceph RBD pool to Libvirt storage pool (Ceph 10.2.9 Jewel)

Env:    
   Ceph 10.2.9    
   OS: Debian 9.1   
   RBD pool: SSD based RBD pool   

#### Create SSD based RBD pool
Create SSD based crush ruleset

example
```
ceph osd crush rule create-simple {rulename} {root} {bucket-type} {first|indep}
```

In our case

```
ceph osd crush rule create-simple ssd-primary ssd host firstn
```

Create SSD based pool

```
ceph osd pool create {pool-name} {pg-num} [{pgp-num}] [replicated] [crush-ruleset-name] [expected-num-objects]
```

In our case

```
ceph osd pool create libvirt-ssd 450 450 replicated ssd-primary
```

#### Configure

Create a ceph user `libvirt-ssd` with proper permission

```
ceph auth get-or-create client.libvirt-ssd mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=libvirt-ssd'
```

save the key

```
ceph auth get-key client.libvirt-ssd | tee client.libvirt-ssd.key
```

create a secret slot for libvirt

```
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
        <usage type='ceph'>
                <name>client.libvirt-ssd secret</name>
        </usage>
</secret>
EOF


virsh secret-define --file secret.xml
```
it will output a secret uuid, like
```
9cb185d5-b219-4bcc-9a4d-7b17184a34fa
```

set the value for the secret

```
virsh secret-set-value --secret 9cb185d5-b219-4bcc-9a4d-7b17184a34fa --base64 $(cat client.libvirt-ssd.key) | rm client.libvirt-ssd.key secret.xml
```

define a rbd pool in libvirt


```
cat > ceph-ssd-pool.xml <<EOF
<pool type="rbd">
  <name>ceph-libvirt-ssd-pool</name>
  <source>
    <name>libvirt-ssd</name>
    <host name='176.16.0.10' port='6789'/>
    <host name='176.16.0.11' port='6789'/>
    <host name='176.16.0.12' port='6789'/>
    <auth username='libvirt-ssd' type='ceph'>
      <secret uuid='9cb185d5-b219-4bcc-9a4d-7b17184a34fa'/>
    </auth>
  </source>
</pool>
EOF

virsh pool-define ceph-ssd-pool.xml
#Mark as autostart
virsh pool-autostart ceph-libvirt-ssd-pool
```
In this xml,` <name>libvirt-ssd</name>` is the pool we created in ceph, the `<name>ceph-libvirt-ssd-pool</name>` is the name we are going to create in virsh pool

So after all abvoe, we can using virt-manager or libvirt to easily using the RBD pool.

#### Reference

https://docs.ceph.com/docs/mimic/rbd/libvirt/   
https://docs.ceph.com/docs/jewel/rados/operations/pools/   
https://docs.ceph.com/docs/jewel/rbd/libvirt/   
