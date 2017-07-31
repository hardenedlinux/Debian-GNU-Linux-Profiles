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
