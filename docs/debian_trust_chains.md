## Building a chain of trust on Debian GNU/Linux

We've been losing software freedom because ME, which is the most powerful demon from Ring -3 world. Since it's more likely an invincible enemy even Intel haven't disabled SPI by adding a similar feature into the same physical package of processor, we'd still have some chances( illusion?) to build our defense for Ring -2 and above world. With [reproducible builds for PaX/Grsecurity](https://github.com/hardenedlinux/grsecurity-reproducible-build), we'd like to make UEFI Secure Boot, bootloader( Grub2), linux kernel and kernel modules on the chain of trust by signing/verify at each level.


### Secure Boot


### Bootloader( Grub?)


### Signed kernel?


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

### Reference

[1] [Experiments with signed kernels and modules in Debian](https://womble.decadent.org.uk/blog/experiments-with-signed-kernels-and-modules-in-debian.html)

[2] [KERNEL MODULE SIGNING FACILITY](https://www.kernel.org/doc/Documentation/module-signing.txt)

[3] [Signed kernel module support](https://wiki.gentoo.org/wiki/Signed_kernel_module_support)
