## Automatic build debian based installation image

### Install Docker

Update and install prerequisite
```
sudo apt-get update
sudo apt-get install \
   apt-transport-https \
   ca-certificates \
   curl \
   gnupg-agent \
   software-properties-common
```
Add Docker’s official GPG key:
```
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
```

add docker repository 
```
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
```

Install the docker packages 
```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

### Create a docker registry

We can simply using docker to run a local registry
```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

for testing
```
# pull debian 10 image from offcial registry
docker pull debian:10

# tag the image as localhost:500/my-debian
docker tag debian:10 localhost:5000/my-debian

# push the image to the local registry running at localhost:5000
docker push localhost:5000/my-debian

# remove the locally-cached debian-10 and localhost:5000/my-debian
docker image remove debian:10
docker image remove localhost:5000/my-debian

# pull the localhost:5000/my-debian from our local registry
docker pull localhost:5000/my-debian
```

### Building Server's Component

create project directory `harbian-iso-builder`

```
cd ~
mkdir harbian-iso-builder
```
#### Main building script inside container

create a directory call `scripts` inside your project directory
```
cd ~/harbian-iso-builder
mkdir scripts
```
create `scripts/build.sh`
```
#!/bin/bash

cd /data/harbian

build-simple-cdd --dvd \
	--profiles-udeb-dist buster \
	--debian-mirror http://192.168.3.17/debian/ \
	--dist buster \
	--security-mirror http://192.168.3.17/debian \
	--keyring /etc/apt/trusted.gpg.d/harbian-archive.gpg \
	--local-packages custompkg/ \
	--keyboard us \
	--locale en_US.UTF-8 \
	-a harbian \
	--conf profiles/harbian.conf -p harbian

rm images/debian-10-amd64-DVD-1.iso
#Custom bootloader
cd tmp/cd-build/buster
#Custom BIOS Mode boot menu

cp /data/conf.d/boot/isolinux.cfg boot1/isolinux/isolinux.cfg
cp /data/conf.d/boot/menu.cfg boot1/isolinux/menu.cfg
cp /data/conf.d/boot/txt.cfg  boot1/isolinux/txt.cfg
cp /data/conf.d/boot/splash.png boot1/isolinux/splash.png

#using xorriso to pack iso
xorriso -as mkisofs -r -checksum_algorithm_iso md5,sha1 -V 'Debian 10 amd64 1' -o /data/output/debian-10-amd64-DVD-1.iso -J -joliet-long -cache-inodes -isohybrid-mbr syslinux/usr/lib/ISOLINUX/isohdpfx.bin -b isolinux/isolinux.bin -c isolinux/boot.cat -boot-load-size 4 -boot-info-table -no-emul-boot -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus boot1 CD1
```
change permission
```
chmod +x scripts/build.sh
```
We are using `build.sh` download require package from our own debian mirror `http://192.168.3.17/debian/`   

#### Offline package installation

###### Debian packages
create `scripts/apt-rdepends.sh`
```
#!/bin/bash
export MAXPARAMETERS=255

function array_contains_find_index() {
    local n=$#
    local i=0
    local value=${!n}

    for (( i=1; i < n; i++ )) {
        if [ "${!i}" == "${value}" ]; then
            echo "REMOVING $i: ${!i} = ${value}"
            return $i
        fi
    }
    return $MAXPARAMETERS
}

LIST=( $( apt-rdepends $1 | grep -v "^ " ) )
echo ${LIST[*]}
read -n1 -r -p "... Packages that will be downloaded (Continue or CTRL+C) ..."

RESULTS=( $( apt-get download ${LIST[*]} |& cut -d' ' -f 8 ) )
LISTLEN=${#LIST[@]}

while [ ${#RESULTS[@]} -gt 0 ]; do
    for (( i=0; i < $LISTLEN; i++ )); do
        array_contains_find_index ${RESULTS[@]} ${LIST[$i]}
        ret=$?

	if (( $ret != $MAXPARAMETERS )); then
            unset LIST[$i]
        fi
    done

    FULLRESULTS=$( apt-get download ${LIST[*]} 2>&1  )
    RESULTS=( $( echo $FULLRESULTS |& cut -d' ' -f 11 | sed -r "s/'(.*?):(.*$)/\1/g" ) )
done

apt-get download ${LIST[*]}
```
We can using `apt-rdepends.sh` to download specific package with all dependencies
Usage: `bash apt-rdepends.sh <package name>`   
This script will download all debs into current directory.   

For example we can install `openssh-server` manually
```
$ mkdir debs
$ cd debs
$ apt install apt-rdepends -y
$ sudo apt-key add conf.d/harbian-archive.gpg
$ sudo cat > /etc/apt/sources.list <<EOF
> deb http://192.168.3.17/debian buster main
> deb-src http://192.168.3.17/debian buster main
> deb http://192.168.3.17/debian buster-updates main
> deb-src http://192.168.3.17/debian buster-updates main
> EOF
$ bash ../scripts/apt-rdepends.sh "openssh-server libgnutls-openssl27"

Reading package lists... Done
Building dependency tree       
Reading state information... Done
openssh-server adduser debconf perl-base dpkg tar libacl1 libattr1 libc6 libgcc1 gcc-8-base libselinux1 libpcre3 libbz2-1.0 liblzma5 zlib1g debconf-2.0 passwd libaudit1 libaudit-common libcap-ng0 libpam-modules libdb5.3 libpam-modules-bin libpam0g libsemanage1 libsemanage-common libsepol1 libcom-err2 libgssapi-krb5-2 libk5crypto3 libkeyutils1 libkrb5support0 libkrb5-3 libssl1.1 libpam-runtime cdebconf libdebian-installer4 libnewt0.52 libslang2 libtextwrap1 libsystemd0 libgcrypt20 libgpg-error0 liblz4-1 libwrap0 lsb-base openssh-client libedit2 libbsd0 libtinfo6 openssh-sftp-server procps init-system-helpers libncurses6 libncursesw6 libprocps7 ucf coreutils sensible-utils
... Packages that will be downloaded (Continue or CTRL+C) ...
REMOVING 1: debconf-2.0 = debconf-2.0

$ ls

adduser_3.118_all.deb			      libncursesw6_6.1+20181013-2+deb10u2_amd64.deb
cdebconf_0.249_amd64.deb		      libnewt0.52_0.52.20-8_amd64.deb
coreutils_8.30-3_amd64.deb		      libpam0g_1.3.1-5_amd64.deb
debconf_1.5.71_all.deb			      libpam-modules_1.3.1-5_amd64.deb
dpkg_1.19.7_amd64.deb			      libpam-modules-bin_1.3.1-5_amd64.deb
gcc-8-base_8.3.0-6_amd64.deb		      libpam-runtime_1.3.1-5_all.deb
init-system-helpers_1.56+nmu1_all.deb	      libpcre3_2%3a8.39-12_amd64.deb
libacl1_2.2.53-4_amd64.deb		      libprocps7_2%3a3.3.15-2_amd64.deb
libattr1_1%3a2.4.48-4_amd64.deb		      libselinux1_2.8-1+b1_amd64.deb
libaudit1_1%3a2.8.4-3_amd64.deb		      libsemanage1_2.8-2_amd64.deb
libaudit-common_1%3a2.8.4-3_all.deb	      libsemanage-common_2.8-2_all.deb
libbsd0_0.9.1-2_amd64.deb		      libsepol1_2.8-1_amd64.deb
libbz2-1.0_1.0.6-9.2~deb10u1_amd64.deb	      libslang2_2.3.2-2_amd64.deb
libc6_2.28-10_amd64.deb			      libssl1.1_1.1.1d-0+deb10u3_amd64.deb
libcap-ng0_0.7.9-2_amd64.deb		      libsystemd0_241-7~deb10u4_amd64.deb
libcom-err2_1.44.5-1+deb10u3_amd64.deb	      libtextwrap1_0.1-14.2_amd64.deb
libdb5.3_5.3.28+dfsg1-0.5_amd64.deb	      libtinfo6_6.1+20181013-2+deb10u2_amd64.deb
libdebian-installer4_0.119_amd64.deb	      libwrap0_7.6.q-28_amd64.deb
libedit2_3.1-20181209-1_amd64.deb	      lsb-base_10.2019051400_all.deb
libgcc1_1%3a8.3.0-6_amd64.deb		      openssh-client_1%3a7.9p1-10+deb10u2_amd64.deb
libgcrypt20_1.8.4-5_amd64.deb		      openssh-server_1%3a7.9p1-10+deb10u2_amd64.deb
libgpg-error0_1.35-1_amd64.deb		      openssh-sftp-server_1%3a7.9p1-10+deb10u2_amd64.deb
libgssapi-krb5-2_1.17-3_amd64.deb	      passwd_1%3a4.5-1.1_amd64.deb
libk5crypto3_1.17-3_amd64.deb		      perl-base_5.28.1-6+deb10u1_amd64.deb
libkeyutils1_1.6-6_amd64.deb		      procps_2%3a3.3.15-2_amd64.deb
libkrb5-3_1.17-3_amd64.deb		      sensible-utils_0.0.12_all.deb
libkrb5support0_1.17-3_amd64.deb	      tar_1.30+dfsg-6_amd64.deb
liblz4-1_1.8.3-1_amd64.deb		      ucf_3.0038+nmu1_all.deb
liblzma5_5.2.4-1_amd64.deb		      zlib1g_1%3a1.2.11.dfsg-1_amd64.deb
libncurses6_6.1+20181013-2+deb10u2_amd64.deb
```

Note: 

The reason why we add `libgnutls-openssl27` because this version of our repositories have some issue with autoinstall this package when using `simple-cdd`

```
2020-12-15 18:49:48 WARNING Found uninstallable packages in /data/harbian/tmp/mirror/dists/buster/main/binary-amd64/Packages:
2020-12-15 18:49:48 WARNING   output-version: 1.2
2020-12-15 18:49:48 WARNING   report:
2020-12-15 18:49:48 WARNING    -
2020-12-15 18:49:48 WARNING     package: libgnutls-openssl27
2020-12-15 18:49:48 WARNING     version: 3.6.7-4+deb10u4
2020-12-15 18:49:48 WARNING     architecture: amd64
2020-12-15 18:49:48 WARNING     status: broken
2020-12-15 18:49:48 WARNING     reasons:
2020-12-15 18:49:48 WARNING      -
2020-12-15 18:49:48 WARNING       missing:
2020-12-15 18:49:48 WARNING        pkg:
2020-12-15 18:49:48 WARNING         package: libgnutls-openssl27
2020-12-15 18:49:48 WARNING         version: 3.6.7-4+deb10u4
2020-12-15 18:49:48 WARNING         architecture: amd64
2020-12-15 18:49:48 WARNING         unsat-dependency: libgnutls30 (= 3.6.7-4+deb10u4)
2020-12-15 18:49:48 WARNING    
2020-12-15 18:49:48 WARNING   total-packages: 342
2020-12-15 18:49:48 WARNING   broken-packages: 1
2020-12-15 18:49:48 WARNING   
```
###### Python packages

If you want to install python package manually and pack into image.

For example we want to install `ubi_reader capstone cstruct pylzma python-lzo`

Create `scripts/download_python_packages.sh`

```
#!/bin/bash

pushd python_offline_packages
pip download -i https://mirrors.aliyun.com/pypi/simple/ ubi_reader capstone cstruct pylzma python-lzo
popd
tar zcvf python_offline_packages.tar.gz python_offline_packages/
```
Usage: `bash scripts/download_python_packages.sh`

```
cd ~/harbian-iso-builder
mkdir python_offline_packages
apt install python-pip
bash scripts/download_python_packages.sh
```

You will get `python_offline_packages.tar.gz` that you can push into image using simplecdd mechanism  

###### anotherpackage.tar.gz

example script 
```
cd ~/harbian-iso-builder
mkdir anotherpackage
cd anotherpackage/
touch some-script-during-installation.sh
touch first-boot.sh
chmod +x some-script-during-installation.sh 
chmod +x first-boot.sh
cd ..
tar zcvf anotherpackage.tar.gz anotherpackage/
```

#### Simple-CDD related

###### Simple-CDD custom profiles

create `conf.d/harbian`
```
cd ~/harbian-iso-builder
mkdir -p conf.d/harbian/profiles
```

Edit `conf.d/harbian/profiles/harbian.packages`   

We can put the package we want into this file, for example `openssh-server`
```
$ cat conf.d/harbian/profiles/harbian.packages

openssh-server
```

Edit `conf.d/harbian/profiles/harbian.conf`
```
all_extras="`pwd`/anotherpackage.tar.gz `pwd`/python_offline_packages.tar.gz"
```
We can using `all_extras` option to copy file into image  

Location:
```
cdrom/simple-cdd/anotherpackage.tar.gz
cdrom/simple-cdd/python_offline_packages.tar.gz
```

edit `conf.d/harbian/profiles/harbian.preseed`

```
d-i preseed/late_command string \
	cp cdrom/simple-cdd/anotherpackage.tar.gz /target/opt; \
	cp cdrom/simple-cdd/python_offline_packages.tar.gz /target/opt; \
        in-target /bin/bash -c 'tar zxf /opt/anotherpackage.tar.gz -C /opt;bash /opt/anotherpackage/some-script-during.sh;cp /opt/anotherpackage/first-boot.sh /etc/rc.local'
```
Copy the packages from iso into target machine's `/opt/` directory, and extract package `anotherpackage.tar.gz` during installation progress
```
	cp cdrom/simple-cdd/anotherpackage.tar.gz /target/opt; \
	cp cdrom/simple-cdd/python_offline_packages.tar.gz /target/opt; \
    in-target /bin/bash -c 'tar zxf /opt/anotherpackage.tar.gz -C /opt
```

Running script during installation progress

```
bash /opt/anotherpackage/some-script-during.sh
```
Copy the first boot script to deal something we can't do during installation progress

```
cp /opt/anotherpackage/first-boot.sh /etc/rc.local'
```
###### Simple-CDD default profiles

By default, simple-cdd will read `/usr/share/simple-cdd/default.preseed` and own custom preseed.

overwrite simple-cdd default preseed file
```
cd ~/harbian-iso-builder
mkdir conf.d/harbian/simple-cdd-default/ -p
```
We can put our customized `default.preseed` into this directory and the dockerfile will copy it into building server's container.

For example `default.preseed`
```
# these are the basic debconf pre-seeding items needed for a miminal
# interaction debian etch install using debian-installer

# this example pre-seeding file was largely based on
# http://d-i.alioth.debian.org/manual/example-preseed.txt
#
# for more explanation of the options, see:
# http://d-i.alioth.debian.org/manual/en.mips/apbs04.html

## simple-cdd options

# automatically select simple-cdd profiles
# NOTE: profile "default" is now automatically included, and should not be
# specified here.
#simple-cdd simple-cdd/profiles multiselect ltsp
#simple-cdd simple-cdd/profiles multiselect ltsp, x-basic


###### Package selection.

# You can choose to install any combination of tasks that are available.
# Available tasks as of this writing include: Desktop environment,
# Web server, Print server, DNS server, File server, Mail server, 
# SQL database, manual package selection. The last of those will run
# aptitude. You can also choose to install no tasks, and force the
# installation of a set of packages in some other way.

# don't install any tasks
#tasksel   tasksel/first multiselect 
#tasksel   tasksel/first multiselect Desktop environment
#tasksel  tasksel/first multiselect Web server, Mail server, DNS server


###### Time zone setup.

# Controls whether or not the hardware clock is set to UTC.
#d-i clock-setup/utc boolean true

# Many countries have only one time zone. If you told the installer you're
# in one of those countries, you can choose its standard time zone via this
# question.
#base-config tzconfig/choose_country_zone_single boolean true
#d-i     time/zone       select  US/Pacific


### keyboard configuration

# don't mess with the keymap
#console-common  console-data/keymap/policy      select  Don't touch keymap
#console-data    console-data/keymap/policy      select  Don't touch keymap

# keyboard layouts
#console-data console-data/keymap/qwerty/layout select US american
#console-data console-data/keymap/family select qwerty
#console-common console-data/keymap/family select qwerty


###### Account setup.

# To preseed the root password, you have to put it in the clear in this
# file. That is not a very good idea, use caution!
#passwd   passwd/root-password    password r00tme
#passwd   passwd/root-password-again  password r00tme

# If you want to skip creation of a normal user account.
#passwd   passwd/make-user    boolean false
# Alternatively, you can preseed the user's name and login.
#passwd   passwd/user-fullname    string Debian User
#passwd   passwd/username     string debian
# And their password, but use caution!
#passwd   passwd/user-password    password insecure
#passwd   passwd/user-password-again  password insecure


#### Network configuration.

# netcfg will choose an interface that has link if possible. This makes it
# skip displaying a list if there is more than one interface.
#d-i netcfg/choose_interface select auto

# Note that any hostname and domain names assigned from dhcp take
# precidence over values set here. However, setting the values still
# prevents the questions from being shown even if values come from dhcp.
#d-i netcfg/get_hostname string unassigned
#d-i netcfg/get_domain string unassigned
# to set the domain to empty:
#d-i netcfg/get_domain string 

# Disable that annoying WEP key dialog.
#d-i netcfg/wireless_wep string 


### Partitioning.

# you can specify a disk to partition. The device name can be given in either
# devfs or traditional non-devfs format.  For example, to use the first disk
# devfs knows of:
## NOTE: disabled for lenny, as it seemed to cause issues
#d-i partman-auto/disk string /dev/discs/disc0/disc

# In addition, you'll need to specify the method to use.
# The presently available methods are: "regular", "lvm" and "crypto"
#d-i partman-auto/method string regular

# If one of the disks that are going to be automatically partitioned
# contains an old LVM configuration, the user will normally receive a
# warning. This can be preseeded away...
#d-i partman-auto/purge_lvm_from_device boolean true
# And the same goes for the confirmation to write the lvm partitions.
#d-i partman-lvm/confirm boolean true

# Alternately, If the system has free space you can choose to only partition
# that space.
#d-i  partman-auto/init_automatically_partition select Use the largest continuous free space
#d-i partman-auto/init_automatically_partition       select  Guided - use entire disk

# You can choose from any of the predefined partitioning recipes:
#d-i partman-auto/choose_recipe  select All files in one partition (recommended for new users)
#d-i  partman-auto/choose_recipe  select Desktop machine
#d-i  partman-auto/choose_recipe  select Multi-user workstation

# uncomment the following three values to makes partman automatically partition
# without confirmation.
#d-i partman/confirm_write_new_label boolean true
#d-i partman/choose_partition  select Finish partitioning and write changes to disk
#d-i partman/confirm     boolean true

#### Boot loader installation.

# This is fairly safe to set, it makes grub install automatically to the MBR
# if no other operating system is detected on the machine.
#d-i grub-installer/only_debian  boolean true
# This one makes grub-installer install to the MBR if if finds some other OS
# too, which is less safe as it might not be able to boot that other OS.
#d-i grub-installer/with_other_os  boolean true


###### Apt setup.

# automatically set the CD as the installation media.
#base-config apt-setup/uri_type  select http
#base-config apt-setup/uri_type  select cdrom
# only scan the first CD by default
#d-i apt-setup/cdrom/set-first  boolean false
# don't ask to use additional mirrors
#base-config apt-setup/another boolean false
# Use a network mirror?
# apt-mirror-setup        apt-setup/use_mirror    boolean false

# Select individual apt repositories
#d-i apt-setup/services-select multiselect security, updates, backports
# Disable extra apt repositories
#d-i apt-setup/services-select multiselect 

# You can choose to install non-free and contrib software.
#d-i apt-setup/non-free  boolean true
#d-i apt-setup/contrib boolean true


###### Mailer configuration.

# During a normal install, exim asks only two questions. Here's how to
# avoid even those. More complicated preseeding is possible.
#exim4-config  exim4/dc_eximconfig_configtype  select no configuration at this time
# It's a good idea to set this to whatever user account you choose to
# create. Leaving the value blank results in postmaster mail going to
# /var/mail/mail.
#exim4-config  exim4/dc_postmaster   string 


### skip some annoying installation status notes

# Avoid that last message about the install being complete.
#d-i finish-install/reboot_in_progress note
# Avoid the introductory message.
#base-config base-config/intro note 
# Avoid the final message.
#base-config base-config/login note 

#d-i     popularity-contest/participate  boolean false


### simple-cdd commands

# you may add to the following commands by including a ";" followed by your
# shell commands.

# loads the simple-cdd-profiles udeb to which asks for which profiles to use,
# load the debconf preseeding and queue packages for installation.

# Locale sets language and country.
d-i debian-installer/language string en
d-i debian-installer/locale string en_US.UTF-8
d-i debian-installer/country string CN
d-i keyboard-configuration/xkb-keymap select us

# Networking

d-i netcfg/choose_interface select auto
d-i netcfg/link_wait_timeout string 10
d-i netcfg/dhcp_timeout string 30
d-i netcfg/hostname string harbian
d-i netcfg/get_hostname string harbian
d-i netcfg/get_domain string
d-i hw-detect/load_firmware boolean true
d-i netcfg/wireless_wep string

# Mirror settings

d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/cdrom/set-next boolean false   
d-i apt-setup/cdrom/set-failed boolean false
d-i apt-setup/no_mirror boolean true
#apt-mirror-setup apt-setup/use_mirror boolean flase
d-i apt-setup/use_mirror boolean false
#d-i mirror/country string manual
#d-i mirror/http/hostname string mirrors.163.com
#d-i mirror/http/directory string /debian
#d-i mirror/http/proxy string

# Disk

d-i partman/early_command string \
    USBDEV=$(list-devices usb-partition | sed "s/\(.*\)./\1/");\
    BOOTDEV=$(list-devices disk | grep -v "$USBDEV" | head -1);\
    debconf-set partman-auto/disk $BOOTDEV

d-i partman-auto/choose_recipe select boot-root
d-i partman-auto/method string regular
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
 
d-i partman-auto/expert_recipe string                         \
      boot-root ::                                            \
              4000 512 4096 linux-swap                        \
                         $primary{ } method{ swap } format{ } \
              .                                               \
              500 10000 -1 ext4                               \
                    $primary{ } $bootable{ } method{ format } \
               format{ } use_filesystem{ } filesystem{ ext4 } \
                                              mountpoint{ / } \
              .
 
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/default_filesystem string ext4
d-i partman/mount_style select uuid

# Time settings

d-i clock-setup/utc boolean false 
d-i clock-setup/ntp boolean false
d-i time/zone string Asia/Shanghai

# Package

tasksel tasksel/first multiselect minimal
d-i pkgsel/install-language-support boolean false
d-i pkgsel/language-pack-patterns string
d-i pkgsel/upgrade select none
d-i pkgsel/language-packs multiselect none
d-i pkgsel/update-policy select none
d-i popularity-contest/participate boolean false

# Account setting

d-i passwd/root-login boolean true 
d-i passwd/root-password-crypted password $6$KehULMd.hrq82IVE$A.VXVHn/juKlI7tZBZXOo3jd2Z9B.euoPRsSfMPOiLz86HRAc9CjvnN38Xb4RMbWgzzyZWNrkQ7NNQAb//zSj1
d-i passwd/user-fullname string Debian User 
d-i passwd/username string debian 
d-i passwd/user-password-crypted password $6$KehULMd.hrq82IVE$A.VXVHn/juKlI7tZBZXOo3jd2Z9B.euoPRsSfMPOiLz86HRAc9CjvnN38Xb4RMbWgzzyZWNrkQ7NNQAb//zSj1


# GRUB
d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string /dev/sda

d-i preseed/early_command string anna-install simple-cdd-profiles

# Finish
d-i finish-install/reboot_in_progress note
```

```
$ls conf.d/simple-cdd-default/

default.preseed
```

#### Custom repository

Because we use custom repository mirror `http://192.168.3.17/debian/`, so we need to add the public key into container

So we put the `harbian-archive.gpg` into `conf.d`

```
wget http://192.168.3.17/harbian-archive.gpg -O conf.d/harbian-archive.gpg
```

#### Custom Bootloader

create `conf.d/boot`

```
cd ~/harbian-iso-builder
mkdir conf.d/boot
```
we can put our custom `isolinux.cfg`, `txt.cfg` and `menu.cfg` into this directory.
Also the background image `splash.png`  

`conf.d/boot/isolinux.cfg`
```
# D-I config version 2.0
# search path for the c32 support libraries (libcom32, libutil etc.)
path 
include menu.cfg
default vesamenu.c32
prompt 0
timeout 0
```
`conf.d/boot/txt.cfg`
```
label install
	menu label ^Install
	kernel /install.amd/vmlinuz
	append preseed/file=/cdrom/simple-cdd/default.preseed debian-installer/locale=en_US.UTF-8 console-keymaps-at/keymap=us keyboard-configuration/xkb-keymap=us keyboard-configuration/layout=us simple-cdd/profiles=harbian vga=788 initrd=/install.amd/initrd.gz --- quiet 
```
`conf.d/boot/menu.cfg`
```
menu hshift 4
menu width 70

menu title Harbian installer menu (BIOS mode)
include stdmenu.cfg
include txt.cfg
```

### Building Image Builder Server from dockerfile

#### Dockerfile

Save following content as `Dockerfile` in your project main directory `~/harbian-iso-builder`
```
FROM debian
RUN apt-get update \
    && apt-get -y install simple-cdd git apt-rdepends gnupg2 vim lftp tzdata
RUN groupadd -g 999 simplecdd && \
    useradd -r -u 999 -g simplecdd simplecdd
RUN mkdir /data/harbian -p && \
    mkdir /data/output -p && \
    mkdir /data/conf.d/boot -p && \
    chown simplecdd:simplecdd /data/ -R && \
    mkdir /home/simplecdd/ -p && \
    chown simplecdd:simplecdd /home/simplecdd/ -R && \
    mkdir /data/harbian/custompkg/ -p && \
    chown simplecdd:simplecdd /data/harbian/custompkg/ -R
USER simplecdd
COPY scripts/build.sh /data/
COPY debs/ /data/harbian/custompkg/
COPY conf.d/harbian/profiles/ /data/harbian/profiles/
COPY conf.d/boot/ /data/conf.d/boot/
COPY conf.d/harbian-archive.gpg /etc/apt/trusted.gpg.d/harbian-archive.gpg

#You can uncomment following line to configure your own auto-installer
#COPY conf.d/harbian/simple-cdd-default/default.preseed /usr/share/simple-cdd/profiles/default.preseed

COPY python_offline_packages.tar.gz /data/harbian
COPY anotherpackage.tar.gz /data/harbian

ENV TZ Asia/Shanghai
ENTRYPOINT ["/data/build.sh"]
CMD ["master"]
```

```
FROM debian
```
Using debian image as base image   
```
RUN apt-get update && apt-get -y install simple-cdd git apt-rdepends gnupg2 vim lftp tzdata
```
Install prerequisite package  
```
RUN groupadd -g 999 simplecdd && useradd -r -u 999 -g simplecdd simplecdd
```
Add simplecdd user
```
RUN mkdir /data/harbian -p && \
    mkdir /data/output -p && \
    mkdir /data/conf.d/boot -p && \
    chown simplecdd:simplecdd /data/ -R && \
    mkdir /home/simplecdd/ -p && \
    chown simplecdd:simplecdd /home/simplecdd/ -R && \
    mkdir /data/harbian/custompkg/ -p && \
    chown simplecdd:simplecdd /data/harbian/custompkg/ -R
```
Create necessary directory inside container
```
USER simplecdd
```

Using simplecdd user to run following command

```
/data/harbian/
```
Default building main directory
```
COPY scripts/build.sh /data/
```
Copy building script `build.sh` into container's `/data/` directory
```
COPY debs/ /data/harbian/custompkg/
```
Copy all the manually download debs into `/data/harbian/custompkg/`
```
COPY conf.d/harbian/profiles/ /data/harbian/profiles/
```
Copy custom all simple-cdd profiles into container
```
COPY conf.d/boot/ /data/conf.d/boot/
```
Copy bootloader related configuration file into container
```
COPY conf.d/harbian-archive.gpg /etc/apt/trusted.gpg.d/harbian-archive.gpg
```
copy custom repository public key into container
```
#COPY conf.d/harbian/simple-cdd-default/default.preseed /usr/share/simple-cdd/profiles/default.preseed
```
overwrite default preseed
```
COPY python_offline_packages.tar.gz /data/harbian/
```
Copy python offline installation packages into container.
```
COPY anotherpackage.tar.gz /data/harbian/
```
Copy examplepackage.tar.gz into container

#### Local building test

Build docker image using Dockerfile
```
cd ~/harbian-iso-builder
docker build -t localhost:5000/harbian-iso-builder .
```

Push the image to the local registry running at localhost:5000
```
docker push localhost:5000/harbian-iso-builder
```
Remove the locally-cached debian-10 and localhost:5000/my-debian
```
docker image remove localhost:5000/harbian-iso-builder
```
Pull the localhost:5000/my-debian from our local registry
```
docker pull localhost:5000/harbian-iso-builder
```

Running the `harbian-iso-builder`

```
cd ~/
mkdir output
chown systemd-coredump:systemd-coredump output/ -R
docker  run -it -v $(pwd)/output:/data/output localhost:5000/harbian-iso-builder
```
output log
```
Drive current: -outdev 'stdio:/data/output/debian-10-amd64-DVD-1.iso'
Media current: stdio file, overwriteable
Media status : is blank
Media summary: 0 sessions, 0 data blocks, 0 data, 12.2g free
xorriso : WARNING : -volid text problematic as automatic mount point name
xorriso : WARNING : -volid text does not comply to ISO 9660 / ECMA 119 rules
xorriso : NOTE : -as mkisofs: Ignored option '-cache-inodes'
Added to ISO image: directory '/'='/data/harbian/tmp/cd-build/buster/boot1'
xorriso : UPDATE :      38 files added in 1 seconds
Added to ISO image: directory '/'='/data/harbian/tmp/cd-build/buster/CD1'
xorriso : UPDATE :    1373 files added in 1 seconds
xorriso : NOTE : Copying to System Area: 432 bytes from file '/data/harbian/tmp/cd-build/buster/syslinux/usr/lib/ISOLINUX/isohdpfx.bin'
libisofs: WARNING : Cannot add /debian to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /dists/stable to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/basic-defs.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/choosing.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/compatibility.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/contributing.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/customizing.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/faqinfo.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/ftparchives.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/getting-debian.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/index.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/kernel.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/nextrelease.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/pkg-basics.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/pkgtools.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/redistributing.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/software.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/support.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: WARNING : Cannot add /doc/FAQ/html/uptodate.html to Joliet tree. Symlinks can only be added to a Rock Ridge tree.
libisofs: NOTE : Aligned image size to cylinder size by 243 blocks
xorriso : UPDATE :  9.15% done
xorriso : UPDATE :  34.64% done
ISO image produced: 158208 sectors
Written to medium : 158208 sectors at LBA 0
Writing to 'stdio:/data/output/debian-10-amd64-DVD-1.iso' completed successfully.
```

Now we can find the image in `output` directory
```
ls ~/output/
debian-10-amd64-DVD-1.iso
```

### Gitlab Server

Install and configure the necessary dependencies
```
sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates
```

Install Postfix for notification emails

```
sudo apt-get install -y postfix
```

Add the GitLab package repository and install the package

```
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee
```

Visit the website and login then you can create your own project



create harbian-iso-builder
```
cd ~/harbian-iso-builder
git init
git remote add origin git@gitlab.247996.xyz:buildbot/harbian-iso-builder.git
git add .
git commit -m "Initial commit"
git push -u origin master
```

#### Create a repo with .gitlab-ci.yaml

First we should register 2 gitlab runner in our gitlab server

To deal with build docker image and upload to our docker registry, we should registry one runner with `shell` executor.  
To run docker image to build harbian installation image, we should registry one runner with `docker` executor.   

`Shell` executor
```
sudo gitlab-runner register -n \
  --url GITLAB_SERVER_URL \
  --registration-token REGISTRATION_TOKEN \
  --executor shell \
  --description "shell-runner" \
  --tag-list shell
```

Note:   
If you encounter following error message while running the CI/CD pipelines

```
The Runner of type Shell don't work: Job failed (system failure): preparing environment:
```

Please comment on the contents of the /home/gitlab-runner/.bash_logout file for the job to work.

`Docker` executor
```
sudo gitlab-runner register -n \
  --url GITLAB_SERVER_URL \
  --registration-token REGISTRATION_TOKEN \
  --executor docker \
  --docker-image docker \
  --description "docker-runner" \
  --tag-list docker 
```

Using `.gitlab-ci.yaml` to build docker image and push to docker registry and trigger `build.sh`

```
image:
  name: localhost:5000/harbian-iso-builder:latest
  entrypoint: [""]

stages:
  - build
  - deploy

build_docker_image:
  stage: build
  tags: 
  - shell
  script:
  - docker build -t localhost:5000/harbian-iso-builder .
  - docker push localhost:5000/harbian-iso-builder

deploy_job:
  stage: deploy
  tags: 
  - docker
  script:
    - export V_PWD="$(pwd)"
    - /data/build.sh
    - cd $V_PWD
    - mkdir -p output
    - mv /data/output/debian-10-amd64-DVD-1.iso ./output/harbian-$(date +%F_%H-%M).iso
    - lftp -e "mirror -R ./output/ ./Archives/ ; quit" -u archives,archives 192.168.1.147
```

Using lftp to push image into out ftp site
```
    - lftp -e "mirror -R ./output/ ./Archives/ ; quit" -u archives,archives 192.168.1.147
```


### Reference

https://stackoverflow.com/questions/63154881/the-runner-of-type-shell-dont-work-job-failed-system-failure-preparing-envi   
