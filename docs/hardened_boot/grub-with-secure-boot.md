## Use GRUB with Secure Boot
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Sign your boot loaders

We assume that you have successfully built a usable trustchain and imported them into the firmware of a target system, according to our article *[Ways to build your own trustchain for secureboot.](./build-secureboot-trustchain.md)*. Now it is time to use them.

The most powerful bootloader [GRUB 2](https://www.gnu.org/software/grub/) will be used. However actually, GRUB cannot verify a signed kernel on its own, but depends on a [shim](https://packages.debian.org/sid/shim) instance already in memory to do that, so you should use a copy of signed shim as the default bootloader, then let it load a signed grub for EFI.

In secure boot environment, you cannot load executable modules for grub on disk as usual modular grub installation does, for all executable must be signed here. Instead, a standalone grub EFI executable with all needed modules embedded should be generated.

[This Makefile](../scripts/secureboot/grub.mk) would generate and sign proper standalone grub and shim for you, with existing db.key and db.crt as part of the trustchain. Because the DB key whose certificate is already imported into the firmware will be used to sign loaders and kernel, no key should be embedded into shim's executable.

The name of modules to embed are written in [modules.lst](../scripts/secureboot/modules.lst). Currently all provided modules are listed, you can strip them down to fit your usage more.

Aside of modules, a zero-level config file [grub.cfg.embedded](../scripts/secureboot/grub.cfg.embedded) should also be embedded, currently whose content is actually excerpted from the first menuentry of the common grub config file of the last release of [libreboot](https://libreboot.org/), which can be found from `resources/grub/config/menuentries/` inside the released source archive. The role of this config file is to find and load the config file installed by the operating system, just as libreboot's grub design.

##### Deploy signed bootloaders to secure-boot-enabled system

After `make(1)`, the signed shim and standalone grub are named `BOOTX64.EFI` and `grubx64.efi` accordingly. Copy them to `${EFI_PARTITION_MOUNT_POINT}/EFI/BOOT/` (put shim under the path for default bootloader, and shim is designed to load an EFI executable named `grubx64.efi` under the same directory by default.).

Reboot the system and enable the secure boot. The system should boot via shim and then the standalone grub. If not, invoke `FSn:\EFI\BOOT\BOOTX64.EFI` manually from the EFI shell.

If the operating system already has a copy of grub.cfg installed to the proper place, the standalone grub is now able to load it, and even boot into the operating system DESPITE the kernel is NOT SIGNED. This is because the kernel and initramfs is loaded with `linux` and `initrd` commands accordingly. In order to enforce signature verification, the EFI variant of this two command should be used.

Currently the grub fails to recognize disks on VirtIO, so IDE or SATA virtual interface should be used to connect disk images(at least the one with the EFI system partition).

##### Enforce secure boot on kernel loading.

First the default bootloader should be registered to EFI (assuming the EFI system partition is at `/dev/sdXY`):

`# efibootmgr --create --disk /dev/sdX --part Y --loader /EFI/BOOT/BOOTX64.EFI --label "Default Loader"`

The operating system may install and register its own grub bootloader, but it will not be executed for it is not signed, however its registration procedure may interfere boot order. The system may boot into EFI shell if the default bootloader is not registered explicitly.

Copy the kernel to the machine where DB keys are available, and then sign it:

`$ sbsign --key db.key --cert db.crt --output vmlinuz-some-version-amd64.efi.signed vmlinuz-some-version-amd64`

Then copy the signed kernel back to `/boot/` of the target machine, just beside the unsigned kernel, and apply [this patch](../scripts/secureboot/10_linux.diff) to `/etc/grub.d/10_linux`, in order to use `linuxefi` and `initrdefi` instead of the traditional variant on signed kernel.

Now regenerate the `/boot/grub/grub.cfg`:

`# update-grub`

After reboot, this target system will only load signed kernels BY DEFAULT, for `linux` module remains available inside the standalone grub. You can choose to modify the grub module list to exclude `linux` module in order to load signed kernel only, or to harden the os-installed grub config file, leaving `linux` module as a fallback mechanism only available to administrators.

######Reference: 
######[1] man page of sbsign
######[2] Source code of grub
######[3] [Latest release of libreboot](https://libreboot.org/release/stable/20160907/libreboot_r20160907_src.tar.xz)
