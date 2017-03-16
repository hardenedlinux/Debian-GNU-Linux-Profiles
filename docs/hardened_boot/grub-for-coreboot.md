## Assemble GRUB executable for coreboot
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Generate an standalone ELF GRUB executable

Similar to procedures to generate a standalone grub EFI executable mentioned in [this article](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/grub-with-secure-boot.md), [This Makefile](../../scripts/coreboot/grub.mk) could be used to generate a standalone grub ELF executable in order to integrate into coreboot images.

In order to use that makefile, you should install the binaries of the coreboot version of grub:

	# apt-get install grub-coreboot-bin
	
and a font will be integrated into the executable, you must copy or symlink the `ttf` formatted font file to `font.ttf` under the same directory of the makefile, e.g.

	$ ln -s /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf font.ttf
	
The font will be converted to `pf2` format by `grub-mkfont(1)`, and integrated into the executable during the invocation of the makefile.

Make sure all dependencies are ready, the makefile could be invoked:

	$ make -f grub.mk
	
A standalone grub ELF executable named `grub.elf` will be generated.

##### Integrate the executable into the coreboot image

For now, you are assumed to have built a usable coreboot image with seabios as the default payload. (usually located in `${CBSRC}/build/coreboot.rom`)

You need `cbfstool` to manipulate CBFS with the image. An usable executable should be generated at `${CBSRC}/build/cbfstool` during coreboot's build process.

Copy the grub executable to `${CBSRC}/grub2.elf` and run the following script under `${CBSRC}`:

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

##### Configure files for coreboot.

There should be a 0th config file integrated into the grub executable.
In this scheme, [this file](../../scripts/coreboot/grub.cfg.embedded) is a stub to load integrated font and run the 1st config file located in CBFS.

Exemplar [grub.cfg](../../scripts/coreboot/grub.cfg) and [grubtest.cfg](../../scripts/coreboot/grub.cfg) are those used by [libreboot](https://libreboot.org). You could insert them into the coreboot image with the following script:

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

##### Further enhancements
Grub has the ability to import and trust OpenPGP public keys and verify
detached OpenPGP signatures, which can be used to implement a scheme with similar effect to UEFI's secureboot.

Further info could also be found in coreboot's documents for grub.

######Reference: 
######[1] manpages of grub-mkstandalone(1)
######[2] Source code of grub
######[3] [Latest release of libreboot](https://libreboot.org/release/stable/20160907/libreboot_r20160907_src.tar.xz)
######[5] https://www.coreboot.org/SeaBIOS
######[5] https://www.coreboot.org/GRUB2
