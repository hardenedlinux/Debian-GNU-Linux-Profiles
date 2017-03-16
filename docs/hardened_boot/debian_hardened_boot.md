## Mission impossible: Mission impossible: Hardening the x86 based core infrastructures

"Once upon a time, hackers lives in a world with full of libre/free software/firmware/hardware"...oh, wait, it's not happened yet. Not sure if we can make it happen. It's totally depends on the decision we make today. Some people might think we are already lost our freedom on x86. Because there are a bunch of [shitty binary blobs](https://www.coreboot.org/Binary_situation) during the boot/runtime( Who's gonna watching the watchers?) process in x86, e.g: GBE( no big deal?), CPU microcode( Do we really believe the vendor don't leave a backdoor there? Ok, it's unlikely to happen because the "magic" constant shit is not hard to find but...possibility is still there?), VGA	BIOS( the 1st rule of OptionROM is do not talk about-_-), MRC( lacking of effort to do the reversing?), [Intel ME](https://github.com/hardenedlinux/firmware-anatomy/blob/master/hack_ME/me_info.md)( red alert....). We may have chance to build the libre/free core infrastructure( SW/FW/HW) on ARMv8 in the near future or wait for RISC-V for another decade? I don't know the answer. But I do know is there are huge number of desktop, server and embedded devices( did I fuc\*ing say IoT shit?) running on x86, which need to be hardened. We've been trying hard to build the hardening solution by free/libre software/firmware for x86. Maybe we( who's fuc\* we?) still need to [try harder 2 be ourselves](http://phenoelit.org/stuff/Zeronights_Keynote.pdf)....

Free software community has been facing the big threats from firmware level for a long time. Those free software implementation of firmware, such as Libreboot/Coreboot is still hard to apply to diverse x86 hardware. The situation we have isn't optimistic according to the threat model.


<pre>
+----------------------------------------------------------------------------------------+
|  Level  |  Threat: e.g:                       | Defense gate                           |
+----------------------------------------------------------------------------------------+
| Ring 3  | compromised program with setuid     | Compiler mitigation                    |
+----------------------------------------------------------------------------------------+
| Ring 0  | root priv esclation                 | PaX/Grsecurity                         |
+----------------------------------------------------------------------------------------+
| Ring -1 | virtual machine escape              | PaX/Grsecurity + Situational hardening |
+----------------------------------------------------------------------------------------+
| Ring -2 | bypass sig verify/SMM arbitrary RWX | Secure boot + Situational hardening    |
+----------------------------------------------------------------------------------------+
| Ring -3 | Rootkit friendly ME                 | Kill it? Or you better run /(-)\       |
+----------------------------------------------------------------------------------------+
</pre>


We've been losing software freedom because ME, which is the most powerful demon from Ring -3 world. Since it's more likely an invincible enemy even Intel haven't disable SPI by adding a similar feature into the same physical package of processor( because it'd be harmful to OEM's interest?) yet and we'd still have some chances( illusion?) to build our defense for Ring -2 and above world. We are going to make UEFI Secure Boot, bootloader( Grub2), linux kernel and kernel modules on the chain of trust by signing/verify at each level. There are less than 5% of machines( let's say 100 servers...damn, how long can we neutralize the ME for 100 machines and finish the bunch of regression test due to reduce the risk of business impact) are running *critical/important* production systems. We should do the hardening by its situation.

<pre>
+--------------------------------------------------------------------------------------------------------------------------------------------+
|  Level    |  Digtial asset need to be protected        |  Solution                                                                         |
+--------------------------------------------------------------------------------------------------------------------------------------------+
| Critical  | Private key, key mgt server, etc           | Neutralized ME + free/libre firmware + Secure/verified                            | 
|           |                                            | boot + reproducible builds for PaX/Grsecurity                                     |
+--------------------------------------------------------------------------------------------------------------------------------------------+
| Important | Asset could possibly cause business impact | Neutralized ME + Secure/verified + boot + reproducible builds for PaX/Grsecurity  |
+--------------------------------------------------------------------------------------------------------------------------------------------+
| Normal    | blah-blah-blah!                            | Original ME + Secure/verified + boot + reproducible builds for PaX/Grsecurity     |
+--------------------------------------------------------------------------------------------------------------------------------------------+
</pre>

### Demon from RING -3: a parallel world along side of x86
Do you really understand what/why we're doing( is wrong?) all of this to protect our digital asset and privacy( is not a joke today?). Fortunately, we're getting closer to the current goal. First thing first, Intel ME can't be 100% disabled but we can restrict the power of Intel ME by minizing its functions. Plz follow [the instruction](https://hardenedlinux.github.io/firmware/2016/11/17/neutralize_ME_firmware_on_sandybridge_and_ivybridge.html). We've been testing on [some machines](https://github.com/hardenedlinux/hardenedlinux_profiles/tree/master/coreboot) and[ me_cleaner](https://github.com/corna/me_cleaner/) is done well. Hope more free software hackers and security research will join us to tearing [Intel ME](https://github.com/hardenedlinux/firmware-anatomy/blob/master/hack_ME/me_info.md) apart. Btw, hope [AMD will be more friendly](https://www.reddit.com/r/Amd/comments/5x4hxu/we_are_amd_creators_of_athlon_radeon_and_other/dekwva9/) to FLOSS community?


### Secure Boot and bootloaders( Grub2?)
* [Ways to build your own trustchain for secureboot](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/build-secureboot-trustchain.md)
* [Assemble GRUB executable for coreboot](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/grub-for-coreboot.md)
* [Use GRUB with Secure Boot](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/grub-with-secure-boot.md)
* [Preparation for Secure Boot on Key Management Server](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/preparation-for-secureboot-on-km-server.md)
* [Set Up Unrestricted Secure Boot On supporting machine](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/setup-unrestricted-secureboot-on-supporting-machine.md)


### Signed kernel?

The signature signing has been integrated with [reproducible builds for PaX/Grsecurity](https://github.com/hardenedlinux/grsecurity-reproducible-build). Reproducible build is good and you can see [how it work](https://github.com/hardenedlinux/grsecurity-reproducible-build/blob/master/THEORY.md). The [only side-effect](https://github.com/hardenedlinux/grsecurity-reproducible-build#signature-siging-for-secure-boot) we found is signed kernel image produced by reproducible builds won't be identical. It won't affect other files. It doesn't matter if your build system is not being compromised in the 1st place;-)


### Signing Kernel Module

Generating a private key/certificate for signing kernel modules

<pre>
# ./gen-x509-key.sh sha512 hardenedlinux.x509 hardenedlinux.pk
# cat hardenedlinux.x509 >> hardenedlinux.pk
# cp hardenedlinux.x509 hardenedlinux.pk /kbuild/
</pre>


Those out-of-tree kernel module can be signed by the private key/certificate manually:

<pre>
# ./kernel-src/scripts/sign-file sha512 /kbuild/hardenedlinux.pk /kbuild/hardenedlinux.x509 test.ko

# hexdump -C test.ko | tail

0002bb10  11 3f 49 cc f6 5c 82 89  4b e7 2e 89 e4 89 33 11  |.?I..\..K.....3.|
0002bb20  a4 9e 78 cf 4c 44 71 20  b8 07 de cc 2e ed 33 82  |..x.LDq ......3.|
0002bb30  98 65 6b 74 8b 0e ed 01  4f ad ec b4 0c 67 5b e7  |.ekt....O....g[.|
0002bb40  a9 76 91 35 8b 10 4d 7c  3b 4a 11 39 0b c8 79 db  |.v.5..M|;J.9..y.|
0002bb50  43 d6 12 72 68 58 37 4f  40 1a 39 81 6b 10 90 c7  |C..rhX7O@.9.k...|
0002bb60  e6 54 72 29 3c a3 67 47  53 45 44 c4 c0 3d c6 00  |.Tr)<.gGSED..=..|
0002bb70  00 02 00 00 00 00 00 00  00 02 d7 7e 4d 6f 64 75  |...........~Modu|
0002bb80  6c 65 20 73 69 67 6e 61  74 75 72 65 20 61 70 70  |le signature app|
0002bb90  65 6e 64 65 64 7e 0a                              |ended~.|
0002bb97
</pre>


### Know your enemy
[Intel x86 considered harmful](https://blog.invisiblethings.org/papers/2015/x86_harmful.pdf)

[Platform Embedded Security Technology Revealed: Safeguarding the Future of Computing with Intel Embedded Security and Management Engine](http://download.springer.com/static/pdf/940/bok%253A978-1-4302-6572-6.pdf?originUrl=http%3A%2F%2Flink.springer.com%2Fbook%2F10.1007%2F978-1-4302-6572-6&token2=exp=1482307879~acl=%2Fstatic%2Fpdf%2F940%2Fbok%25253A978-1-4302-6572-6.pdf%3ForiginUrl%3Dhttp%253A%252F%252Flink.springer.com%252Fbook%252F10.1007%252F978-1-4302-6572-6*~hmac=8dfe35980dc1ce90babcfe71699db6c5e9a745710f50ee2d3be6d58d053fee5b)


### Reference

[1] [Experiments with signed kernels and modules in Debian](https://womble.decadent.org.uk/blog/experiments-with-signed-kernels-and-modules-in-debian.html)

[2] [KERNEL MODULE SIGNING FACILITY](https://www.kernel.org/doc/Documentation/module-signing.txt)

[3] [Signed kernel module support](https://wiki.gentoo.org/wiki/Signed_kernel_module_support)
