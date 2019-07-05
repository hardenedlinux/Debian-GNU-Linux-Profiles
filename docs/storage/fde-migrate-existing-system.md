# This note is for those who want to use full-disk encryption but feel reinstall OS unaffordable.

## Prepare the temporary storage.
A storage device (e.g. an HDD) whose capacity is large enough to store all the data within the system to migrate is needed.

You had better deploy FDE on the temporary storage, too. To do so, [stuff the disk with meaningless encrypted data first](https://wiki.archlinux.org/index.php/Dm-crypt/Drive_preparation#dm-crypt_wipe_on_an_empty_disk_or_partition):

```
# cryptsetup open --type plain -d /dev/urandom /dev/sdZ to_be_wiped
# dd if=/dev/zero of=/dev/mapper/to_be_wiped bs=1M status=progress
# cryptsetup close to_be_wiped
```

If this disk is an SSD, you had better [clear all its memory cell](https://wiki.archlinux.org/index.php/Solid_state_drive/Memory_cell_clearing) prior to stuff it:
```
# hdparm --user-master u --security-set-pass PasSWorD /dev/sdX
# hdparm --user-master u --security-erase-enhanced PasSWorD /dev/sdX
```

After you stuff the disk, you can create a partition, upon which setup luks, upon which setup LVM physical volume and volume group, and finally, create logical volumes to store the content of existing partitions of the system to migrate.
```
# cryptsetup luksFormat --type luks2 /dev/sdZW
# cryptsetup open /dev/sdZW lc0
# pvcreate /dev/mapper/lc0
# vgcreate vg0 /dev/mapper/lc0
# lvcreate vg0 -L <capacity larger than /dev/disk/by-label/<label>> -n <label>-tmp
```
## Migrate data to the temporary storage
This can never be done with the existing system, you should use a live GNU/Linux system with a kernel whose version similar to the system to migrate. For example, the current pureos live system is a good choice to migrate an existing system running debian buster.

After unlock the luks and setup the LVs of the temporary storage,you can start to migrate data. Either by low-level copy file system:
```
# e2image -rap /dev/disk/by-label/<label> /dev/vg0/<label>-tmp
```
or by high level copy:
```
# mkfs.ext4 /dev/vg0/<label>-tmp -L <label>-tmp
# mount /dev/disk/by-label/<label> /mnt/<label>
# mount /dev/vg0/<label>-tmp /mnt/<label>-tmp
# cp -av /mnt/<label>/* /mnt/<label>-tmp
```
The partition tables of each disk on the migrating system had better be backed up, too, you can create a dedicate LV to store these metadata.
```
# lvcreate vg0 -L <feasible capacity> -n migr-meta
# mkfs.ext4 /dev/vg0/migr-meta -L migr-meta
# mount /dev/vg0/migr-meta /mnt/migr-meta
# sgdisk -b /mnt/migr-meta/sdX.gpt /dev/sdX
```
or you can use gdisk(8) to operate it interactively.

## Prepare disks on the migrating system
After you complete migrating all the data to the temporary storage, you are going to setup luks on disks on the migrating system. You should also stuff the with meaningless encrypted data first, as you have done when preparing the temporary storage (for SSD, clear all its memory cell first). Needless to say, unmount all partitions on them first.

You can reuse the partition tables you backed up, just delete most partitions, as they will be revived as logical volumes. Retain partitions for /boot, /boot/efi and BIOS boot partition, and create a large partition for encrypted storages.

## Migrate data back
Create luks inside the large partition, upon which setup LVM physical volume and volume group, and finally, create logical volumes according to the backed up partition tables (use `gdisk -l` to print it).

You can migrate data back now, just as how you migrate them to the temporary storage. adjust the migrated filesystem with resize2fs if you use e2image to do low level copy.

I prefer to create new filesystem, and do high level filesystem, as filesystem will slightly be optimized in the process.

```
# mkfs.ext4 /dev/vg-system/<label> -L <label>
# mount /dev/vg-system/<label> /mnt/<label>
# mount /dev/vg0/<label>-tmp /mnt/<label>-tmp
# cp -av /mnt/<label>-tmp/* /mnt/<label>
```

# Config system
Assuming now you have two disk (sda and sdb) in your target system, each has a "luks/pv/vg/lvs" on it, and the root lv is on sda.
```
# cryptsetup open --type luks /dev/sdaX luks-system
# mount /dev/vg-system/root /mnt/root
```
You can [add a key file to the luks on sdb](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Creating_a_keyfile_with_random_characters), store the key in root, and unlock it with crypttab.
```
# dd bs=512 count=4 if=/dev/random of=/mnt/root/etc/keys/luks-data.key iflag=fullblock
# mkdir /mnt/root/etc/keys
# cryptsetup luksAddKey /dev/sdbY /mnt/root/etc/keys/luks-data.key
```
At this point, backup headers of all luks in the target system.

You can even [detach the luks header (and erase the original one) from the luks](https://wiki.archlinux.org/index.php/Dm-crypt/Specialties#Encrypted_system_using_a_detached_LUKS_header) on sdb, making it totally unrecognizable.
```
# cryptsetup luksHeaderBackup --header-backup-file=/mnt/root/etc/keys/luks-data.hdr /dev/sdbY
## if /dev/sdb is an ssd
# blkdiscard -l <size of luks-data.hdr> /dev/sdbY
##
# dd if=/dev/urandom of=/dev/sdbY bs=<size of luks-data.hdr> count=1
# cryptsetup open --type luks --header /mnt/root/etc/keys/luks-data.hdr /dev/sdbY luks-data --key-file /mnt/root/etc/keys/luks-data.key
# chmod -R 600 /mnt/root/etc/keys/
```

back 

Update /etc/fstab with new mapped block devices:
```
/dev/vgs/root / ext4    errors=remount-ro 0 1
UUID=<some uuid> /boot ext2    default 0 2
...
```
Update /etc/crypttab. An absent /etc/crypttab indicates an absent package cryptsetup-initramfs. If so, please update /etc/crypttab after you have installed cryptsetup-initramfs in the target system via chroot (see below).
```
luks-system UUID=<uuid> none luks
luks-data PARTUUID=<partuuid> /etc/keys/luks-data.key luks,noearly,header=/etc/keys/luks-data.hdr
```
(since the header of luks-data get erased, it has no UUID, only PARTUUID of GPT is usable.)
You must map the lukses (on the live system) with names exactly corresponding to what is written into the crypttab, otherwise update-initramfs(8) may get confused.

Note: Currently debian scripts can only convert the keyfile path for initramfs (replace root with /FIXME-initramfs-rootmnt/, and convert to the real mount point of permanent root within initramfs) before pivoting to the permanent root, but not other paths (e.g. header path), so lukses using detached header (like the luks-data above) cannot be unlocked during initramfs phase (they will be unlocked after pivoting to the permanent root). Swap in it can not be used for resuming, so in such case, the RESUME variable in initramfs.conf (and conf.d) should be set to none to prevent the noearly flag above is ignored. Otherwise, initramfs will try to unlock luks-data several times without the correct header path, delaying the boot process.

If /etc/fstab is modified properly, you can chroot into the target system now, and finalize the configuration.
```
# mount -o bind /dev /mnt/root/dev
# mount -o bind /proc /mnt/root/proc
# mount -o bind /sys /mnt/root/sys
# mount -o bind /run /mnt/root/run
# chroot /mnt/root/
(chrooted)# mount -a
```
Confirm all block device in /etc/fstab is mounted. Double check whether lvm2 and cryptsetup-initramfs are installed in the target system. If not, install them now, provided that the host live system has network connection.
```
(chrooted)# apt-get update
(chrooted)# apt-get install lvm2 cryptsetup-initramfs
```
The best practice is to install them BEFORE you start the migration procedure, though.
```
(chrooted)# update-initramfs -ck <kernel version you want to use>
(chrooted)# update-grub
```

Now, the migrated system is very likely to boot properly.
