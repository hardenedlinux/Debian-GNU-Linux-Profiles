#!/bin/bash

WORKDIR=/tmp/debian-grsec-configs
mkdir -p $WORKDIR
cd $WORKDIR

echo "###########################################################################"
echo -e "[+] \e[93mInstalling paxctl-ng/elfix...\e[0m"
echo "----------------------------------------------"
apt-get install -y vim libc6-dev libelf-dev libattr1-dev build-essential
wget https://dev.gentoo.org/%7Eblueness/elfix/elfix-0.9.2.tar.gz && tar zxvf elfix-0.9.2.tar.gz
cd elfix-0.9.2
./configure --enable-ptpax --enable-xtpax --disable-tests
make && make install
cd $WORKDIR

echo "###########################################################################"
echo -e "[+] \e[93mDeploying configs....\e[0m"
echo "----------------------------------------------"

wget https://github.com/hardenedlinux/hardenedlinux_profiles/raw/master/debian/77pax-bites
wget https://github.com/hardenedlinux/hardenedlinux_profiles/raw/master/debian/pax_flags_debian.config

cp 77pax-bites /etc/apt/apt.conf.d/
cp pax_flags_debian.config /etc/

echo "###########################################################################"
echo -e "[+] \e[93mDeploying pax-bites...\e[0m"
echo "----------------------------------------------"
git clone https://github.com/hardenedlinux/pax-bites.git
cp pax-bites/pax-bites.sh  /usr/sbin/
pax-bites.sh -e /etc/pax_flags_debian.config

