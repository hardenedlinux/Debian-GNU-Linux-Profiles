#!/usr/bin/env bash
sudo apt update
sudo apt -y upgrade
sudo apt -y install cmake make gcc g++ flex bison libpcap-dev python-dev swig zlib1g-dev libgeoip-dev  autoconf python-pip python3-pip jq curl wget libsasl2-dev libhtp-dev libssl-dev
mkdir src
cd ~/src
echo "Bro install..."
wget https://www.zeek.org/downloads/zeek-3.0.0-rc2.tar.gz
tar -xvf zeek-3.0.0-rc2.tar.gz
cd zeek-3.0.0-rc2
echo "install libmaxminddb"
sudo apt-get install libmaxminddb-dev -y

#download City database
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
tar zxf GeoLite2-City.tar.gz
wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz
tar zxf GeoLite2-Country.tar.gz
for cityfile in ./GeoLite2-City_2019*; do
      echo ${cityfile##*/}
done
sudo mv ${cityfile}/GeoLite2-City.mmdb /usr/share/GeoIP
#mv GeoIPcountry
for ctfile in ./GeoLite2-Country_2019*; do
      echo ${ctfile##*/}
done
sudo mv ${ctfile}/GeoLite2-Country.mmdb /usr/share/GeoIP
# the file "GeoLite2-City_YYYYMMDD/GeoLite2-City.mmdb" needs to be moved to the GeoIP database directory.
#* /usr/share/GeoIP/GeoLite2-City.mmdb
#* /usr/share/GeoIP/GeoLite2-Country.mmdb
#dowload Country database
./configure --with-geoip=/usr/share/GeoIP
make -j 4
sudo make install
sudo ln -s /usr/local/zeek/bin/zeek* /usr/local/bin
#Test Bro GeoIp
sudo zeek -e "print lookup_location(8.8.8.8);"
..
echo "Broker install..."
wget https://www.zeek.org/downloads/broker-1.2.0.tar.gz
tar -xvf broker-1.2.0.tar.gz
cd broker-1.2.0
./configure
sudo make -j4 install
echo "=== Broker Installation finished ==="



echo "PostgreSQL install .../"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-11 libpq-dev postgresql-server-dev-all
