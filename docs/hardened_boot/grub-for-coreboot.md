## Assemble GRUB executable for coreboot
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Implement a mechanism similar to linuxefi with grub config script

On UEFI platforms, `GRUB` implements a command `linuxefi` to load linux kernel only after its signature against the `DB key` is verified, and enable the feature for kernel to load modules after its signature get verified.

This command only available on UEFI platforms, but in reality, grub itself has the mechanism to import gpg public keys, and use them to verify detached signature for any file. it even has an option to make it implicitly verify any file before load it into ram.

All we need is to wrap those mechanism with grub config script into a function able to be invoked like a builtin command, with similar interface like `linuxefi`, like this [grub.cfg.embedded](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/scripts/coreboot/grub.cfg.embedded):

Function `linuxpgp` will first enable enforced signature verification, "load" linux kernel, with kernel command line option `module.sig_enforce=1` appended at the end of the command line, then disable enforced signature verification. This function could be used in place of `linux`, just as `linuxefi`.

Every OpenPGP public keys put under (cbfsdisk)/keys (inside the firmware flash, not any external storage) would be trusted.

This script will be embedded into the standalone ELF GRUB executable, to extend its functionality. In its execution, it loads the second stage config file under (cbfsdisk)/grub.cfg.

##### Generate an standalone ELF GRUB executable

Similar to procedures to generate a standalone grub EFI executable mentioned in [this article](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/grub-with-secure-boot.md), [This Makefile](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/scripts/coreboot/grub.mk) could be used to generate a standalone grub ELF executable in order to integrate into coreboot images. Proper [modules.lst](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/scripts/coreboot/modules.lst) and [instmod.lst](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/scripts/coreboot/instmod.lst) should also be provided.

In order to use that makefile, you should install the binaries of the coreboot version of grub:

```
# apt-get install grub-coreboot-bin
```

and a font will be integrated into the executable, you must copy or symlink the `ttf` formatted font file to `font.ttf` under the same directory of the makefile, e.g.

```
$ ln -s /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf font.ttf
```

The font will be converted to `pf2` format by `grub-mkfont(1)`, and integrated into the executable during the invocation of the makefile.

Make sure all dependencies are ready, the makefile could be invoked:

```
$ make -f grub.mk
```

A standalone grub ELF executable named `grub.elf` will be generated, with [grub.cfg.embedded](/scripts/coreboot/grub.cfg.embedded) integrated as the first stage config script.

###### Update for coreboot (after commit [2ac149d294af795710eb4bb20f093e9920604abd](https://review.coreboot.org/cgit/coreboot.git/commit/?id=2ac149d294af795710eb4bb20f093e9920604abd))

On some newer platforms of intel (confirmed on nehalem, sandy/ivy bridge), coreboot registers an SMI to lockdown some registers on the chipset,
as well as access to the SPI flash, optionally. The SMI will always be triggered by coreboot during S3 resume, but can be triggered by either
coreboot or the payload during normal boot path.

Enabling lockdown access to SPI flash will effectly write-protect it, but there is no runtime option for coreboot to control it, so letting
coreboot to trigger such SMI will leave the owner of the machine lost any possibility to program the SPI flash with its own OS, and becomes a
nightmare if the machine is uneasy to disassemble.

Fortunately, grub has the compatibility to use outb, outl, and outw, which means it has the ability to trigger SMI as well. We can then write
a [special config script](/scripts/coreboot/grub.sec.cfg.embedded), in which an auto-executed `menuitem` is designed to trigger the SMI, and whose
context is protected with a password. Only designated superuser could edit the code within this `menuitem` at runtime, thus disable the write-
protection temporarily, in order to reprogram the SPI flash.

Such config script is designed to embedded into the grub payload executable. In order to make such protection unable to bypass during boot,
the payload had better be executed by coreboot directly, rather than to be chainloaded from other runtime-operable payloads, such as SeaBIOS.

##### Integrate the executable into the coreboot image

For now, you are assumed to have set up a usable coreboot building environment under `${CBSRC}`.

First, configure it as your wish.

```
$ cd ${CBSRC}
$ make menuconfig
```

###### Use the grub payload directly

coreboot allows to use existing elf executable as payload, which will be executed by coreboot directly.

###### SeaGrub scheme

Use seabios as the default payload, which will be built and integrated into the image automatically during coreboot's building process,
then use the script below to insert the grub payload into the image, and configure SeaBIOS to chainload it automatically.

##### Build coreboot's image

After saving the config result, invoke `make(1)` to build the coreboot image.

```
$ make
```

The coreboot image will be generated at `${CBSRC}/build/coreboot.rom`.

You need `cbfstool` to manipulate CBFS with the image. An usable executable should be built at `${CBSRC}/build/cbfstool` during coreboot's build process.

Copy the grub executable to `${CBSRC}/grub2.elf` and run the following script under `${CBSRC}`, if SeaGrub scheme will be used:

```
#!/bin/sh
if [ -z $1 ];then
	CBROM=build/coreboot.rom
else
	CBROM=$1
fi
build/cbfstool ${CBROM} add-payload -c lzma -f grub2.elf -n img/grub2
printf "/rom@img/grub2\n" > bootorder
build/cbfstool ${CBROM} add -f bootorder -n bootorder -t raw
build/cbfstool ${CBROM} add-int -i 1 -n etc/show-boot-menu || "already exists"
build/cbfstool ${CBROM} remove -n etc/ps2-keyboard-spinup || printf "does not exist"
build/cbfstool ${CBROM} add-int -i 3000 -n etc/ps2-keyboard-spinup || printf "already exists"
build/cbfstool ${CBROM} print
```

I recommend to leave one second for seabios before launching grub, in order to execute other payloads integraded during coreboot's build process.

##### Second stage grub config file for coreboot.

Exemplar [grub.cfg](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/scripts/coreboot/grub.cfg) and [grubtest.cfg](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/scripts/coreboot/grub.cfg) are those used by [libreboot](https://libreboot.org). You could insert them into the coreboot image with the following script:

```
#!/bin/sh
if [ -z $1 ];then
        CBROM=build/coreboot.rom
else
        CBROM=$1
fi
build/cbfstool ${CBROM} add -t raw -n grub.cfg -f grub.cfg
build/cbfstool ${CBROM} add -t raw -n grubtest.cfg -f grubtest.cfg
build/cbfstool ${CBROM} print
```

provided that you have copied the two files under `${CBSRC}`.

Hints to write your own config file could be found in coreboot's documents for grub referred below.

##### Integrate OpenPGP public key to verify kernel (optional)

Use the following script to integrate pubkeys into the coreboot image:

```
#!/bin/sh

case $1 in
	*.rom)
	CBROM=$1
	shift
	;;
	*)
	CBROM=build/coreboot.rom
	;;
esac

FILE=${1}
echo "Insert OpenPGP pubkey ${FILE}..."
build/cbfstool ${CBROM} add -t raw -f ${FILE} -n keys/$(basename ${FILE})
build/cbfstool ${CBROM} print
```

You could then flash this image to its targeting mother board.

##### Boot Scheme with verification

Very similar to the scheme described in [this article](./setup-unrestricted-secureboot-on-supporting-machine.md).

Sign your kernel with the corresponding private key, which should be recognized inside your private keyring, and could be inside an OpenPGP card, using [this wrapper script](../../scripts/coreboot/gpg-sign-kernel.sh).

```
$ /path/to/gpg-sign-kernel.sh /boot/vmlinuz-ver-arch <key identity>
```

The signature file is generated inside your current working directory. Copy it to `/boot`.

Patch `/etc/grub.d/10_linux` with [this patch](../../scripts/coreboot/10_linux.diff). This version could handle both UEFI secure boot and this scheme, as well as the ordinary insecure scheme.

Then regenerate the `/boot/grub/grub.cfg`.

```
# patch /etc/grub.d/10_linux 10_linux.diff
# update-grub
```

For now signed kernels is going to be loaded with `linuxpgp` function.

######Reference: 
[1] [The beta version of GRUB2's documents](https://dev.gentoo.org/~floppym/grub.html#Using-digital-signatures)

[2] manpages of grub-mkstandalone(1)

[3] Source code of grub

[4] [Latest release of libreboot](https://libreboot.org/release/stable/20160907/libreboot_r20160907_src.tar.xz)

[5] https://www.coreboot.org/SeaBIOS

[6] https://www.coreboot.org/GRUB2
