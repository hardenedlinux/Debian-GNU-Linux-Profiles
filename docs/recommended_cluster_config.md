## The recommended configs of host computers running Debian GNU/Linux within clusters.
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Use a shared storage pool to store disk images of virtual machines.

`libvirt`'s "migrate" action can only migrate the definition, as well as the whole state when performing a live migration. In reality, libvirt assumes that **the STORAGE POOL is shared between the source and the destination hosts, and mounted to the same path, the images should remain accessible via the very same path when the migration is done**, otherwise the migration will fail to start. So, the easiest way to config the hosts is mounting a shared storage (NFS and the like) on the path `/var/lib/libvirt/images`, where the pool `default` is defined, of each hosts, making them effectively a cluster.

Source images (e.g. isos for installation) can be put into the pool using `vol-upload` sub-command of `virsh(1)`, and you can get a backup of one image inside the pool using `vol-download` sub-command.

##### Use a normal user to perform libvirt-related maintenance.

There are a lot of documents related to libvirt in which `root` user is used to perform guest-related maintenance, but in reality, those are bad practices.

In Debian GNU/Linux, permissions needed to manage virtual machines are assigned to group `libvirt` and `kvm`, so you should create a user to be specialized to manage vms, e.g. `virtmgr`, and add it to those two group above:

```
# adduser virtmgr
# usermod -aG libvirt virtmgr
# usermod -aG kvm virtmgr
```

libvirt defaults to qemu:///session for non-root. So from `virtmgr` you'll need to do: 

`$ virsh --connect qemu:///system list --all`

You can use environment variable `LIBVIRT_DEFAULT_URI` to change this. 

Such user account is feasible to perform remote management via ssh. You can use `virsh`, `virt-manager` or other tools based on libvirt to conect to the host via this account to perform everything libvirt provides, e.g.

`$ virsh --connect qemu+ssh://virtmgr@$HOSTNAME_OF_THE_HOST.local/system ...`

##### Use mdns to make it possible to access computers via domain names derived from their hostname instead of ip address.

By deploying [mdns](https://en.wikipedia.org/wiki/Multicast_DNS) (one of whose famous implementation is the Bonjour of Apple Inc) server on each computers within the same subnet, they can contact each other by using domain names in a format like "**$HOSTNAME_OF_THE_TARGET_HOST.local**".

I believe it is needless to say that domain name derived from hostname is easier to remember than ip address.

The major implementation of mdns on most Unix-like operation systems is [Avahi](https://en.wikipedia.org/wiki/Avahi_%28software%29). In Debian GNU/Linux, it is divided to a lot of packages. To make use of the most basic function of mdns, you could just install `avahi-daemon` as mdns server and `libnss-mdns` to interface mdns name resolution to [Name Service Switch](https://en.wikipedia.org/wiki/Name_Service_Switch):

`# apt-get install avahi-daemon libnss-mdns`

Enjoy mdns name resolution after deploying them on every host within your subnet!

##### Making the management console of the cluster able to mount the shared storage pool may be benefitting.

A management console of a cluster is a computer for the cluster administrators to log in, able to access and manage hosts within the cluster, through which the guests living upon the hosts get managed. But how could it become if the console also mounts the shared storage pool used by worker hosts, and becomes a functional host itself?

Virtual machines can then be created and calibrated on the management console, and can be *migrated* onto an appropriate worker host once it is feasible for production use. Malfunctional but running guests can also be *migrated* onto the management console to check and repair.

Disks images can be uploaded and downloaded "locally" if the management console directly mounts the shared storage pool, eliminating the communicational expense between the console and a worker host.

######Reference: 
######[1] https://libvirt.org/virshcmdref.html
######[2] https://docs.fedoraproject.org/en-US/Fedora/13/html/Virtualization_Guide/chap-Virtualization-KVM_live_migration.html#sect-Virtualization-KVM_live_migration-Live_migration_requirements
######[3] https://docs.fedoraproject.org/en-US/Fedora_Draft_Documentation/0.1/html/Virtualization_Deployment_and_Administration_Guide/App_Migration_Disk_Image.html
