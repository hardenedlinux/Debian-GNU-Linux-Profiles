sudo apt-get update
sudo apt-get install aptitude
sudo aptitude install suricata
sudo aptitude install suricata-oinkmaster

cd ~/src
wget https://www.clamav.net/downloads/production/clamav-0.100.1.tar.gz
tar zxpvf clamav-0.100.1.tar.gz
cd clamav-0.100.1/
./configure
make -j 4
sudo make install
cd ..
sudo mkdir -p /usr/local/share/clamav

sudo cp clamd.service /lib/systemd/system/clamd.service
sudo cp clamd.conf /usr/local/etc/clamd.conf
sudo cp clamav-update /usr/local/bin/
sudo cp clamd-response /usr/local/bin/clamd-response

sudo cp ./rules/*.yar /usr/local/share/clamav/ 

sudo mkdir /var/log/clamav
sudo chown -R root:adm /var/log/clamav
sudo chmod 2755 /var/log/clamav

sudo ldconfig
sudo systemctl enable clamd
sudo systemctl start clamd



mkdir ~/src/snort_src
cd ~/src/snort_src
wget https://www.snort.org/downloads/snortplus/daq-2.2.2.tar.gz
tar -xvzf daq-2.2.2.tar.gz
cd daq-2.2.2/
./configure
make
sudo make install

cd ~/src/snort_src
wget http://downloads.sourceforge.net/project/safeclib/libsafec-10052013.tar.gz
tar -xzvf libsafec-10052013.tar.gz
cd libsafec-10052013
./configure
make
sudo make install

cd ~/src/snort_src
wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz
tar -xzvf ragel-6.10.tar.gz
cd ragel-6.10
./configure
make
sudo make install

   

cd ~/src/snort_src
wget https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.gz
tar -xvzf boost_1_64_0.tar.gz


cd ~/src/snort_src
wget https://github.com/01org/hyperscan/archive/v4.5.2.tar.gz
tar -xvzf v4.5.2.tar.gz
cd hyperscan-4.5.2

mdkir hypercan-4.5.2-build
cd hypercan-4.5.2-build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=~/src/snort_src/boost_1_64_0/
cd hyperscan-4.5.2
make
sudo make install



cd ~/src/snort_src
wget https://github.com/snort3/snort3/archive/BUILD_243.tar.gz
tar -xvf BUILD_243.tar.gz
cd snort3-BUILD_243/
autoreconf -isvf 
./configure_cmake.sh --prefix=/opt/snort
cd build
sudo ldconfig
make
sudo make install
sudo ln -s /opt/snort/bin/snort /usr/sbin/snort
export LUA_PATH=/opt/snort/include/snort/lua/\?.lua\;\;
export SNORT_LUA_PATH=/opt/snort/etc/snort

sh -c "echo 'export LUA_PATH=/opt/snort/include/snort/lua/\?.lua\;\;' >> ~/.bashrc"
sh -c "echo 'export SNORT_LUA_PATH=/opt/snort/etc/snort' >> ~/.bashrc"

echo Defaults env_keep += "LUA_PATH SNORT_LUA_PATH" |sudo tee -a /etc/sudoers

cd /src/snort_src
wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz
sudo tar -xvf snort3-community-rules.tar.gz
cd snort3-community-rules
sudo mkdir /opt/snort/etc/snort/rules
sudo cp snort3-community.rules /opt/snort/etc/snort/rules/
sudo cp sid-msg.map /opt/snort/etc/snort/rules/

wget https://www.snort.org/downloads/openappid/7630
tar -xzvf 7630
sudo cp -R odp /opt/snort/lib/
##
echo "#sudo nano /opt/snort/etc/snort/snort.lua
## find appid this line and add appid dir to here:

#appid =
#{
#    app_detector_dir = '/opt/snort/lib'
#}
then:
sudo snort -c /opt/snort/etc/snort/snort.lua --warn-all
###check conf files"


#GOlang
sudo curl -O https://dl.google.com/go/go1.11.2.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.11.2.linux-amd64.tar.gz
