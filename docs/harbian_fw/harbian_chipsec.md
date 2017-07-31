## Firmware auditing with CHIPSEC on Debian 9

### Install the prerequisite packages:
<pre>
apt-get install build-essential python-dev python gcc linux-headers-$(uname -r) nasm python-pip git
</pre>

Or if you are using [PaX/Grsecurity 4.9.x](https://github.com/minipli/linux-unofficial_grsec):
<pre>
apt-get install build-essential python-dev python gcc nasm python-pip git
</pre>

### Install the [CHIPSEC](https://github.com/chipsec/)
<pre>
cd chipsec/
pip install setuptools
python setup.py install
</pre>

### Firmware security checklist based on CHIPSEC

According to the [firmware security training](https://github.com/advanced-threat-research/firmware-security-training) from McAfee Advanced Threat Research. CHIPSEC modules perform a couple checks for the auditing purposes:

| Issue           | CHIPSEC Module    | References          |
|:---------------:|:-----------------:|:-------------------:|
| SMRAM Locking   | common.smm        | [CanSecWest 2006](http://www.ssi.gouv.fr/archive/fr/sciences/fichiers/lti/cansecwest2006-duflot.pdf)|
| BIOS Keyboard Buffer Sanitization | common.bios_kbrd_buffer | [DEFCON 16](http://www.slideshare.net/endrazine/defcon-16-bypassing-preboot-authentication-passwords-by-instrumenting-the-bios-keyboard-buffer-practical-low-level-attacks-against-x86-preboot-authentication-software) |
| SMRR Configuration | common.smrr | [ITL 2009](http://www.invisiblethingslab.com/resources/misc09/smm_cache_fun.pdf), [CanSecWest 2009](http://cansecwest.com/csw09/csw09-duflot.pdf) |
| BIOS Protection | common.bios_wp | [BlackHat USA 2009](http://www.blackhat.com/presentations/bh-usa-09/WOJTCZUK/BHUSA09-Wojtczuk-AtkIntelBios-SLIDES.pdf), [CanSecWest 2013](https://cansecwest.com/slides/2013/Evil%20Maid%20Just%20Got%20Angrier.pdf), [Black Hat](http://c7zero.info/stuff/Windows8SecureBoot_Bulygin-Furtak-Bazhniuk_BHUSA2013.pdf) [2013](https://www.blackhat.com/us-13/briefings.html), [NoSuchCon 2013](http://www.nosuchcon.org/talks/D2_01_Butterworth_BIOS_Chronomancy.pdf) |
| SPI Controller Locking | common.spi_lock | [Flashrom](http://www.flashrom.org/), [Copernicus](http://www.mitre.org/capabilities/cybersecurity/overview/cybersecurity-blog/copernicus-question-your-assumptions-about) |
| BIOS Interface Locking | common.bios_ts | [PoC 2007](http://powerofcommunity.net/poc2007/sunbing.pdf) |
| Secure Boot variables with keys and configuration are protected | common.secureboot.variables | [UEFI 2.4 Spec](http://uefi.org/) , All Your Boot Are Belong To Us ([here](https://cansecwest.com/slides/2014/AllYourBoot_csw14-intel-final.pdf) & [here](https://cansecwest.com/slides/2014/AllYourBoot_csw14-mitre-final.pdf)) |
| Memory remapping attack | remap | [Preventing and Detecting Xen Hypervisor Subversions](http://www.invisiblethingslab.com/resources/bh08/part2-full.pdf) |
| DMA attack against SMRAM | smm_dma | [Programmed I/O accesses: a threat to VMM?](http://www.ssi.gouv.fr/archive/fr/sciences/fichiers/lti/pacsec2007-duflot-papier.pdf), [System Management Mode Design and Security Issues](http://www.ssi.gouv.fr/uploads/IMG/pdf/IT_Defense_2010_final.pdf) |
| SMI suppression attack | common.bios_smi | [Setup for Failure: Defeating Secure Boot](https://www.hackinparis.com/sites/hackinparis.com/files/JohnButterworth.pdf) |
| Access permissions to SPI flash descriptor | common.spi_desc | [Flashrom](http://www.flashrom.org/) |
| Access permissions to UEFI variables defined in UEFI Spec | common.uefi.access_uefispec | [UEFI 2.4 Spec](http://uefi.org/) |
| Module to detect PE/TE Header Confusion Vulnerability | tools.secureboot.te | [All Your Boot Are Belong To Us](https://cansecwest.com/slides/2014/AllYourBoot_csw14-intel-final.pdf) |
| Module to detect SMI input pointer validation vulnerabilities | tool.smm.smm_ptr | [CanSecWest 2015](https://cansecwest.com/slides/2015/A%20New%20Class%20of%20Vulnin%20SMI%20-%20Andrew%20Furtak.pdf) |
| SPI Flash Descriptor Security Override Pin-Strap | common.spi_fdopss | FLOCKDN |
| IA32 Feature Control Lock | common.ia32cfg | IA32_Feature_Control MSR lock bit |
| Protected RTC memory locations | common.rtclock | ?? |
| S3 Resume Boot-Script Protections | common.uefi.s3bootscript | ?? |
| Host Bridge Memory Map Locks | memconfig | PCI cfg |


### Firmware whitelist management for the data center

Generate the firmware whitelists:
<pre>
chipsec_util spi dump firmware.bin
chipsec_main -m tools.uefi.whitelist -a generate,harbianN_list.json,firmware.bin
</pre>

Check if the firmware is on the whitelist:
<pre>
chipsec_main -i -n -m tools.uefi.whitelist -a check,efi_lenovo.json,/fw-content/9sjt91a.img
</pre>


### Reference
