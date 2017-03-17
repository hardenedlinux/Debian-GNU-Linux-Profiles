## Ways to build your own trustchain for secureboot.
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Background

Secure Boot need a trustchain, which has been described in [Pollux's blog](https://www.wzdftpd.net/blog/uefi-secureboot-debian.html) and [James Bottomley's random Pages](http://blog.hansenpartnership.com/owning-your-windows-8-uefi-platform/). This scheme is even useful for virtual machine, if [OVMF](http://www.tianocore.org/ovmf/) is used as the boot firmware.

The following procedures should all be done on a properly fortified host, for some private keys are going to be generated.

##### File based trustchain building.

The following packages should be installed (Note that currently efitools is only available in debian sid, and sbsigntool is only available in debian testing and sid.):

```
# apt-get install gnutls-bin uuid-runtime efitools sbsigntool udisks2 dosfstools
```

In the blogs above there have been some commands to do the deed, but I believe, in order to resolve these structural dependency, `make(1)` should be used to ease the execution, so I wrote [this Makefile](../../scripts/secureboot/Makefile) to build the trustchain. Although different keys had better be held in different administrators, they can all use this Makefile to perform their own duty.

To create certificates in batch, template files are needed, some exemplative files are provided in [this directory](../../scripts/secureboot/)

Run `make auth` to create .auth files which UEFI with secure boot feature accepts, 

```
$ make auth
```

and `make signedtools` could be used to create signed version of efi executables privided by `efitools` package, which are needed to import and manipulate keys on UEFI shell.

```
$ make signedtools
```

##### Create and upload disk image.

Create a disk image with the following GPT table via `gdisk(8)` (no need to be accurate, and its capacity may vary):

```
Number  Start (sector)    End (sector)  Size       Code  Name
   1              34            2048   1007.5 KiB  EF02  BIOS boot partition
   2            2074          131038   63.0 MiB    EF00  EFI System
```

Not that the type of partitions should be set to EF02 (BIOS boot partition) and EF00 (EFI boot partition) respectively (with `T` command of `gdisk(8)`, `%%` as comment):

```
$ fallocate -l 64M efiboot.img
$ /sbin/gdisk efiboot.img
%% create bios boot partition before the first alignment.
%% to do so, sector alignment should be set to 34 (just after the first gpt).
Command (? for help): x
Expert command (? for help): l
Enter the sector alignment value (1-65536, default = 2048): 34
Expert command (? for help): m
Command (? for help): n
Partition number (1-128, default 1): 1
First sector (34-131038, default = 34) or {+-}size{KMGTP}: 34
Last sector (34-131038, default = 131038) or {+-}size{KMGTP}: 2047
Current type is 'Linux filesystem'
%% ef02 is 'BIOS boot partition'
Hex code or GUID (L to show codes, Enter = 8300): ef02
%% reset the alignment to 2048.
Command (? for help): x
Expert command (? for help): l
Enter the sector alignment value (1-65536, default = 2048): 2048
Expert command (? for help): m
Command (? for help): n
%% use all remaining as the efi boot partition.
First sector (2048-131038, default = 2048) or {+-}size{KMGTP}: 
Last sector (2049-131018, default = 131018) or {+-}size{KMGTP}: 
Current type is 'Linux filesystem'
%% ef00 is 'EFI System'
Hex code or GUID (L to show codes, Enter = 8300): ef00
Command (? for help): p
Number  Start (sector)    End (sector)  Size       Code  Name
   1              34            2047   1007.0 KiB  EF02  BIOS boot partition
   2            2048          131038   63.0 MiB    EF00  EFI System
Command (? for help): w
Final checks complete. About to write GPT data. THIS WILL OVERWRITE EXISTING
PARTITIONS!!

Do you want to proceed? (Y/N): y
```

Bind the image to a loop device:

`$ udisksctl loop-setup -f efiboot.img`

Create a fat32 file system on the second partition:

`# mkfs.vfat -n EFIBOOT /dev/loop0p2`

and mount it:

`$ udisksctl mount -b /dev/loop0p2`

Symlink its mount point to your working directory, or change the value of `DISKPATH` variable within the Makefile.

Run `make install`. .auth files will be installed to the root of the file system with the image, while efi executables (signed and unsigned) will be installed to EFT/BOOT/.

`$ make install`

Then you can test this image on a libvirt virtual machine using OVMF as boot firmware. 

##### Create a virtual machine to perform test.

 You should have access to a host of virtual machine in order to perform test (The host could be your local machine provided that all the software needed are [installed and configured](../recommended_cluster_config.md)). The host should have OVMF available. If not, ask its administrator to install it:
 
`# apt-get install ovmf`
 
 Create an empty raw disk image on the host:

`$ virsh -c ${HOST_URL} vol-create-as default efiboot 0`

Then upload the local disk image you just prepared to the place:

`$ virsh -c ${HOST_URL} vol-upload --pool default --vol efiboot --file efiboot.img`

Connect your `virt-manager` to the host, and create a virtual machine using the disk image you just upload (`Import existing disk image`) and OVMF (Choose `Customize configuration before install` in the last step, and select OVMF as firmware in the configuration interface). Now you can use this virtual machine to test your keys.

##### Test keys on the guest.

Under EFI shell, type `FSn:\EFI\BOOT\KeyTool.efi` to execute the KeyTool.

KeyTool itself has a curses-like user interface, in which the keys (PK, KEK, db, dbx, etc) for this firmware could be manipulated.

To import keys to a platform, select `Edit Keys` first, then a key variable, then `Add New Key`, now you are able to browse the file system on the image, to add an .auth file to the key variable.

PK should be imported AFTER KEK, db, and dbx, because once PK is imported, the secure boot is enabled, and only signed efi executables could be executed. If at this time there is no valid trustchain inside the firmware, you will not be able to invoke any efi executable.

PK could only be replaced or deleted, not able to be added. Select `PK`, then `Replace Key(s)`, then you can browse the .auth file you want to use.

An .auth file generated from an empty .esl file and signed with PK (`nopk.auth` in the Makefile) could be used to delete PK. Select the PK, then select the existing key expressed with its UUID, and `Delete with .auth File`, then you can browse the file to delete PK. Other keys could be delete directly.

If the nopk file is invalid or the trustchain is broken that no efi executable can be executed, you could enter the config interface of the firmware by pressing ESC when TianoCore's logo appears on the screen. Select `Device Manager`, then `Secure Boot Configuration`, then change `Secure Boot Mode` to `Custom Mode`, you can now delete present keys on the `Custom Secure Boot Options` appeared below. Note: after PK is delete, the secureboot is disabled, and `Secure Boot Mode` is changed back to `Standard Mode`, so you should enable `Custom Mode` again in order to remove remaining keys.

`Custom Secure Boot Options` could also be used to import keys from file on disk(image)s.

The image could also be used on physical machine if written to a usb drive.

##### Experimental PKCS#11 based trustchain building (not fully working).

Private keys should be stored in hardware module (e.g. PKCS#11 ones), so I developed the [modified Makefile](../../scripts/secureboot/Makefile.p11). 

Unfortunately, this scheme has not yet been able to produce valid signed efi executable, as well as usable nopk.auth, only the main trustchain is valid. I hope someone could help us to improve this scheme.

Assuming you guys have already had enough 2048-bit RSA keys stored in a smart card-like device supported by [OpenSC](https://github.com/OpenSC/OpenSC), you have to config your GnuTLS for PKCS#11 first:

```
$ mkdir -p $HOME/.config/pkcs11/modules/
$ echo 'module: /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so' > $HOME/.config/pkcs11/modules/opensc.module
```

Then list the PKCS#11 urls of your keys with the following command:

```
$ p11tool --provider opensc-pkcs11.so --list-privkeys --login --only-urls
```

write them down (one line per key)to the .url files needed by Makefile, one key per file, as targets of `make(1)`.

In order to run `certtool(1)` in batch mode, the `PIN`(`GNUTLS_PIN`) environment variable should be set to the real pin of your card:

```
$ PIN=<pin of card> make (...)
```

Some certificates should be imported back to the card. Warning: the label of a key may change after the corresponding certificate is imported, so do its PKCS#11 url. If so, you may have to write down its new url to corresponding .url file again.

Rather than invoking `sign-efi-sig-list(1)` directly, in order to use PKCS#11 module, `sign-efi-sig-list(1)` is used to export payloads to sign as files, then sign them with `certtool(1)`, finally, `sign-efi-sig-list(1)` is invoked again to assemble signatures with efi signature lists to produce .auth files.

Note the command to generate `timestamp`, sign-efi-sig-list use `strptime(3)` with "`%c`" to parse the timestamp string. It is very apt to fail if other time format is used, producing invalid .auth files.

There seems only libNSS-based `pesign(1)` able to sign efi executables with PKCS#11 modules, so a certdb directory should be create first.

######Reference: 
######[1] man page of sign-efi-sig-list, sbsign and pesign
######[2] man page of certtool and smime (1ssl)
######[3] Source code of sign-efi-sig-list
######[4] [User:Pjones/SecureBootSmartCardDeployment](https://fedoraproject.org/wiki/User:Pjones/SecureBootSmartCardDeployment)
