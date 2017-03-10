## Preparation for Secure Boot on Key Management Server.
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Background

Within a data center, a dedicated **Key Management Server** should exist to perform **every** action related to private key **files**, including the procedure to generate necessary stuffs for Secure Boot's deployment.

##### File based trustchain building.

efitools is only provided in sid repo. You can add it into /etc/apt/sources.list:
```
# Unstable repo main, contrib and non-free branches, no security updates here
deb http://http.us.debian.org/debian unstable main non-free contrib
deb-src http://http.us.debian.org/debian unstable main non-free contrib
```

Prerequested Packages for Debian 9:

```
# apt-get install gnutls-bin uuid-runtime efitools sbsigntool udisks2 dosfstools make grub-efi-amd64-bin shim
```

Invoke [this Makefile](../scripts/secureboot/Makefile) to build the trustchain. (You had better do it in a separate directory.)
```
$ make [-f path/to/this/Makefile] auth
```

##### Signing EFI utilities and generate Maintenance Disk Image

Now use the trustchain (DB key) to sign EFI utilities.
```
$ make [-f path/to/this/Makefile] signedtools
```
Generate a disk image and partition it.
```
$ fallocate -l 64M efiboot.img
$ /sbin/sgdisk -o -a 34 -n 1:34:2047 -a 2048 -n 2:2048 -t 1:ef02 -t 2:ef00 efiboot.img
```
Create an vfat file system on the second partition of the image.
```
$ udisksctl loop-setup -f efiboot.img
# mkfs.vfat -n EFIBOOT /dev/loop0p2
$ udisksctl mount -b /dev/loop0p2
```
Install signed public keys and EFI utilities into the image.
```
$ ln -s /media/${LOGNANE}/EFIBOOT EFIBOOT
$ make install
```
After that you can release the image
```
$ udisksctl unmount -b /dev/loop0p2
$ udisksctl loop-delete -b /dev/loop0
```

##### Sign Boot Loader

It is possible to boot a linux kernel directly from UEFI via EFI stub, but it is not recommended for it needs kernels to be put in `EFI System Partition`, which most distros would not do automatically, as well as some other security issues, so I recommend to use signed boots to load signed kernel. 

Invoke [This Makefile](../scripts/secureboot/grub.mk) to generate and sign proper standalone grub (`grubx64.efi`) and shim (`BOOTX64.EFI`) for you, with existing db.key and db.crt as part of the trustchain. Proper [modules.lst](../scripts/secureboot/modules.lst) and [grub.cfg.embedded](../scripts/secureboot/grub.cfg.embedded) should also be provided.

```
$ make -f /path/to/grub.mk 
```

##### Build and sign the Linux kernel

Use [these instructions](https://github.com/hardenedlinux/grsecurity-reproducible-build) to build a linux kernel which would verify its modules' signature before loading them.

Sign the vmlinuz with the DB key generated with above procedures.
```
$ sbsign --key db.key --cert db.crt --output vmlinuz-some-version-amd64.efi.signed vmlinuz-some-version-amd64
```
TODO: integrate this into the procedures to build and pack the kernel package.

###### References:
######[1] [Ways to build your own trustchain for secureboot.](./build-secureboot-trustchain.md)
######[2] [Use GRUB with Secure Boot](./grub-with-secure-boot.md), [This Makefile](../scripts/coreboot/grub.mk)
######[3] [Reproducible builds for PaX/Grsecurity](https://github.com/hardenedlinux/grsecurity-reproducible-build)
