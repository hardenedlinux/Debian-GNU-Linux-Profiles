# An Attempt to port linuxboot to Dell Latitude E7240

## Introduction for LinuxBoot
[LinuxBoot](https://github.com/linuxboot/linuxboot) is a project aimed at "redirecting" UEFI's DXE stage, to load a Linux-kernel based boot environment like [Heads](https://github.com/osresearch/heads/) and/or [u-root](https://github.com/u-root/u-root), which should be specifically built for LinuxBoot.

I have experiences in build and patch coreboot for Heads. In order to find a best practice of porting LinuxBoot to new board, I have attempted to work on porting it to Dell Latitude E7240, a laptop using Haswell CPU, but with Boot Gaol (A digital handcuff technology which Intel calls "Boot Guard") disabled, but I have not succeed yet.

## More technical detail about UEFI and LinuxBoot (from the aspect of coreboot)
As an implementation of boot firmware for x86 and amd64, UEFI should also be stored in a flash chip mapped **under** 0xffffffff, with the very first instruction stored from the last 16 byte of the flash (which is mapped to the famous 0xfffffff0).

AT least on Intel platforms, the chip is divided into regions, only the last region containing 0xfffffff0 (the BIOS region) serves as the boot firmware, while other regions serve other component of the system.

Both in coreboot and in UEFI, the BIOS region is further divided into volumes.(this concept is borrowed from UEFI's FV - Firmware Volume, although most non-chromeboot coreboot builds are only assigned with one single volume) Inside a volume, a file-system-like data structure could be built (CBFS for coreboot, FFS for UEFI).

Contrary to coreboot, On UEFI, romstage (PEI) and ramstage (DXE) usually stored in different volumes, and each stage consists of a "core" to dispatch surrounding modules, rather than a statically linked executable. if someone builds a (PEI or DXE) module and inject it into the volume storing the corresponding stage with correct parameters, the module will be called by the core, with no need to rebuild the whole stage from source. However, this mechanism is designed to extend the existing firmware in a proprietary manner, and then, it can be used as an attacking vector.

Linux bzImage will be packed as a module capable to be called by DXE core (in the form of a DXE module or BDS), with Initramfs packed as its data, and they will be packed along with a set of vendor DXE modules (usually containing the core) as a new DXE volume with the same size as the vendor one to replace it.

## Obstacles against porting
### Dell Latitude E7240's DXE volume is not plain
LinuxBoot utilizes some scripts to unpack and repack UEFI volumes from the vendor firmware images. Most server board's DXE volume is plain, on which LinuxBoot's scripts work well, but in E7240's DXE volume, there are two large compressed volume nested, along with the DXE core and some modules. LinuxBoot's scripts cannot unpack those two nested volume, so [uefi-firmware-parser](https://github.com/theopolis/uefi-firmware-parser) should be used, along with the following script to retrieve module names:

```
#!/bin/sh
for m in $(find ${1} -name 'file-????????-????-????-????-????????????'); do
    dir=${m};
    name="$(find ${dir} -maxdepth 2 -name '*.ui' -exec iconv -f UCS-2LE -t UTF-8 {} \;)";
    [ -z ${name} ] && continue;
    ln -s file.obj ${dir}/${name}.ffs || continue;
done
```
The `image-files.txt` to list the retained DXE modules thus contains paths like "`${dir}/${name}.ffs`" generated with the script above, instead of the list of GUID-name pair like what other boards LinuxBoot supports use.

### LinuxBoot lacks a guideline to choose which DXE modules to retain
In order to retrieve free space and reduce attacking vector, most DXE modules will be excluded when repacking the DXE volume, with a little retained by listing them in the `image-files.txt` mentioned above, but there is no general rule yet to guide us to choose which modules to retain. Furthermore, there are dependencies between modules (stored as "depex" of a module), but they are expressed in a way that "a module depends on some 'protocols (API)'", but a tool to parse depexes to find the protocol provider and build dependency map is currently absent, so my retained module list for E7240 is an imitation of the list of winterfell, a server board using Haswell, the same CPU microarchitecture that E7240 uses.

### UEFI lack an index above volume
Above volumes, coreboot has a top-level index called Flashmap (FMAP), in which the offset and size of each volume (including the volume to store FMAP itself) is recorded, and only whose offset is hard-coded into executables needing to perform cross-volume access. In theory, if only the FMAP is kept not moved, all other volume is essentially relocatable.

On the contrary, there is currently no such top-level index in UEFI. Instead, in order to perform perform cross-volume access, a module must be hard-coded with the offset of the target volume. Because of these hard-coded offsets inside various modules, while it is possible to inject modules to a volume, or delete modules from a volume, relocating an existing volume itself inside the BIOS region is nearly impossible on UEFI, so one must keep the existing volume layout (which may be used by retained executables) unchanged, and write it into the `Makefile.board`, as the variable `FVS`, while keeping their sequence unchanged.

Things get worse because it is unable to jam bzImage, initramfs and retained DXE modules into the new DXE volume with the same size as the vendor one of E7240, although 5996 KiB could be retrieved from the ME region.(by using [me_cleaner](https://github.com/corna/me_cleaner) to remove most modules of the Intel Management Engine) The only way to make use of the newly available space is to create a new volume on it (of course with all existing volume, including the repacked DXE volume motionless), store packed bzImage module and Initramfs into the new volume, and pack a specific tiny module into DXE volume to locate the new volume and load its contents. The [LinuxBoot BDS](https://github.com/osresearch/linuxboot/blob/bds/dxe/linuxboot.c) is developed for this purpose, but till now, it has some minor problem to build (experimental gnu-efi 3.0.6 should be used).

## Basic porting procedure
Read <https://github.com/linuxboot/linuxboot/blob/master/README.md> and all existing `Makefile.board` first.
### Obtain the FVS variable.
Use the ${LINUXBOOT_REPO}/bin/extract-firmware to dissect the vendor firmware:
```
$ ${LINUXBOOT_REPO}/bin/extract-firmware vendor-firmware.rom | tee vendor-firmware-components.lst
```
All the files whose name starts with "0x" in succession makes up the variable `FVS` mentioned above. Concatenating them produces the original firmware. The key mechanism in this level is replacing the original DXE volume with a reconstructed one (done in `Makefile.board`, by replacing the name of the original DXE volume to `$(BUILD)/rom/dxe.vol` in the `FVS`).

However, this script seems to be designed for UEFI capsule with no real ifd, so if you decide to make use of the space claimed from ME region, you may have to replace the first two items `0x00000000.ifd` and `0x00010000.bin` with those extracted with ifdtool(1) of coreboot.

extract-firmware can only extract plain volume. For volumes with nested volumes, uefi-firmware-parser mentioned above should be used, and you may want to use the above script to retrieve module names.

### Reconstruct the DXE volume
As mentioned above, lots of DXE modules should be retained and incorporated into the new DXE volume. If the original DXE volume is plain and has enough space to store bzImage and initramfs, statements below used by most boards could be used:
```
dxe-size        := $(size-of-dxe-volume-in-hex)
#dxe-compress   := $(size-of-compressed-dxe-volume-in-hex)

dxe-path := $(BUILD)/rom/$(offset-of-dxe-volume)

dxe-files := $(shell awk  \
        '/^[0-9A-Fa-f]/ {print "$(dxe-path)/"$$1".ffs"}' \
        boards/$(BOARD)/image-files.txt \
)

...

# Replace the DxeCore and SmmCore with our own
# and add in the Linux kernel / initrd
$(BUILD)/dxe.vol: \
        $(dxe-files) \
        $(BUILD)/Linux.ffs \
        $(BUILD)/Initrd.ffs \

```
You could only prepare a file list containing GUIDs of DXE module to retain. The build procedure will extract the original firmware with `extract-firmware` mentioned above, and modules to retain will be picked according to the list and incorporated into the new DXE volume, along with packed bzImage and initramfs (generated from Heads or u-root built for linuxboot).

If you want to add volumes on the space claimed from ME region, you should add them into `FVS`, and add statements to build them, like those existing statements to build DXE volume.

The newly-built volumes will have the same size as what they will replace, they will be concat(1)enated along with other components of `FVS` in succession, to produce a new volume image as `${LINUXBOOT_REPO}/$(BOARD)/linuxboot.rom`, you can flash it back with external programmers.

## Conclusion
LinuxBoot is an excellent attempt to bring the "Linux-as-bootloader" scheme for coreboot world to UEFI, but the proprietary nature of UEFI have introduced many obstacles against its deployment. The most hard part may be the choise of which DXE modules to retain.
