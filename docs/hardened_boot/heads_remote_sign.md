# Generating boot signature in the main OS for a working Heads

[Heads](https://github.com/osresearch/heads) is a boot firmware (program stored in rom to init hardware) solution based on coreboot. It has implemented OpenPGP-based signed boot, TPM-based measured boot, and OTP-based attestation.

## Heads' signed boot
Heads' signed boot is implemented as a hash file tree like what is usually used in the software repositories: (In the aspect of file Hierarchy within Heads' environment)
```
/boot/kexec.sig-Sign-[a temp hash list]-Hashlist-|/boot/kexec_default.${i}.txt-Compare-[a temp list converted from grub.cfg]
	                                             |/boot/kexec_default_hashes.txt-Hashlist-|/path/to/vmlinuz
                                                 |(/boot/kexec_rollback.txt)              |(/path/to/initrd)
```

These `kexec*` files are stored in the root directory of the partition holding the kernel and initrd of the main OS (it is always mounted to `/boot/` within Heads' environment, and will be referred as `${BOOTPART}` in the aspect of file Hierarchy within main OS below). A temporary boot option list is converted from grub.cfg during every boot procedure, whose ${i}th line is saved as the default boot parameters to `/boot/kexec_default.${i}.txt` and compared with such line of the temporary list during every boot. `/boot/kexec_default_hashes.txt` is a hash file list for files (vmlinuz and initrd) to load in order to boot, and is verified every time. `/boot/kexec_rollback.txt` contains the value of a "counter" stored in TPM. Heads' boot script system saves the signature of the hash file list of all `/boot/kexec*.txt` to disk as `/boot/kexec.sig` (This top level hash file list itself is never saved, but generated on the fly and piped to gpg to verify during each boot). Any verification or comparison failure causes the boot process terminated.

If [This patch](https://github.com/osresearch/heads/pull/294) is applied and enabled, the initrd will be excluded from the hash tree if `module.sig_enforce=1` is present in the kernel commandline, and if TPM support is disabled, `/boot/kexec_rollback.txt` is excluded and never saved.

## Reconstruct Heads' hash tree in the main OS
If files to load, and/or grub.cfg are changed, the hash tree becomes invalid. According to Heads' original design, the boot procedure will terminate, and if such change is intentional for the user, they can start the recovery shell and use command line tools and scripts provided by Heads to reconstruct a valid hash tree, but this may not be convenient to manage large amounts of computers (e.g. for a datacenter), for which it is more convenient to reconstruct the hash tree inside the mail OS.

Most often affected files inside the hash tree is `/boot/kexec_default.${i}.txt` and `/boot/kexec_default_hashes.txt`. Regenerating them and the top signature could result in a valid hash tree.
(According to Heads' original design, TPM counter and `/boot/kexec_rollback.txt` is updated every time the hash tree is reconstructed VIA HEADS, but to ease maintenance, I do not believe Heads' design should be followed even here for on-line hash tree reconstruction.)

### Modify Heads' scripts for our usage
Using Heads' own scripts may make our goal easier to achieve, but Heads' scripts is designed to work in Heads' own environment. To make them usable in the main OS, they should be hacked a little:
```
$ mkdir -p ${playground}
$ cd ${playground}
${playground}$ mkdir etc
${playground}$ cp -r ${heads_repo_dir}/initrd/bin/ .
${playground}$ cp ${heads_repo_dir}/initrd/etc/functions etc/
${playground}$ sed -i 's/\/etc/etc/g' bin/*
```

The runtime config for this instance of Heads could be extracted from its own initrd:
```
${playground}$ xz -cd /path/to/initrd.cpio.xz | cpio -i etc/config
```
It affects the behavior of these scripts.
The default shell `#!/bin/sh` of Heads to interpret these scripts is Busybox's ash, which is usually not the default shell of the main OS, so Bash(1) should be explicitly used to interpret these scripts.

### Obtain default boot item (${BOOTPART}/kexec_default.${i}.txt)
Use `kexec-parse-boot` to convert grub's config file to the option list heads use, and fetch the ${i}th line as the default option, then save it to ${BOOTPART}.

```
${playground}$ for line in `find ${BOOTPART} -name "*.cfg"`; do bash bin/kexec-parse-boot "${BOOTPART}" "${line}" >> ${ITEMS}; done
$ head -n ${i} ${ITEMS}| tail -n 1 > kexec_default.${i}.txt
```

### Obtain default boot file hash list (${BOOTPART}/kexec_default_hashes.txt)
The path inside the list should be relative to the ${BOOTPART}, so they should be replaced accordingly.
```
${playground}$ BOOTPART_ESC=$(echo ${BOOTPART}|sed 's/\//\\\//g'); bash bin/kexec-boot -fb ${BOOTPART} -e "`cat kexec_default.${i}.txt`"|sed "s/^\./${BOOTPART_ESC}/g"|xargs sha256sum |sed "s/${BOOTPART_ESC}/./g" > kexec_default_hashes.txt
```

If [This patch](https://github.com/osresearch/heads/pull/294) is applied and enabled, the `-f` switch had better be replaced with `-h`, so initrd could be excluded from hash tree if the kernel verifies every modules to load.
Save the resulted hash list to ${BOOTPART}.

### Obtain signing payload (top level hash list that is not saved)
```
$ sha256sum `find ${BOOTPART}/kexec*.txt` > top_list.txt
```
Note: The path inside the list should always be amended to what is seen inside Heads' environment, so if there is no separate `/boot` partition in the main OS, i.e. ${BOOTPART} is `/` instead of `/boot`, the `kexec*.txt` lie under the root directory of the main OS, but ${BOOTPART} is mounted to `/boot` in heads, so paths inside the list should be amended accordingly. e.g. `/kexec_default_hashes.txt` should be changed to `/boot/kexec_default_hashes.txt`.

The top list generated on the computer using Heads should be copied to where you can use the OpenPGP secret keys and signed (not clear-signed) with GnuPG:
```
$ gpg --digest-algo SHA256 -bo kexec.sig top_list.txt
```
then copy the resulted signature back to the target computer as `${BOOTPART}/kexec.sig`. 

Now, the hash tree is reconstructed successfully.

You can also run [this script](/scripts/heads_remote_sign.sh) inside `${playground}`, with `${1}` to assign the default boot line:

The updated component of the hash tree will be generated in `/tmp/`, and they should be copied back to `${BOOTPART}` when convenient, along with the signature.

# References
[1] [Heads-wiki](https://github.com/osresearch/heads-wiki)
[2] [Heads' source code](https://github.com/osresearch/heads)
[3] [Deploy Heads atop coreboot for GNU/Linux](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/hardened_boot/heads-atop-coreboot.md)
