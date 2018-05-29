#!/bin/bash
mkdir ~/src
cd ~/src
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.2.3-amd64.deb
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.3.deb
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.2.3.deb
sudo apt-get update
sudo apt-get install openjdk-8-jre
sudo dpkg -i *.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service logstash.service kibana.service
sudo systemctl start elasticsearch.service kibana.service logstash.service

echo config.reload.automatic: true |sudo tee -a /etc/logstash/logstash.yml
echo config.reload.interval: 3s |sudo tee -a etc/logstash/logstash.yml
echo a |sudo tee -a 1.txt 
sudo systemctl restart logstash.service

##
sudo apt -y install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev libgeoip-dev zookeeperd autoconf python-pip python3-pip jq curl wget libsasl2-dev libhtp-dev libssl1.0-dev
mkdir src
cd ~/src
wget https://www.bro.org/downloads/bro-2.5.3.tar.gz
tar -xvf bro-2.5.3.tar.gz
cd bro-2.5.3/
./configure
make
sudo make install
sudo ln -s /usr/local/bro/bin/bro /usr/local/bin
..
cp ~/src/Debian-GNU-Linux-Profiles/NSM/ELK/packages/librdkafka.tar.gz ~/src/.
sudo tar -xvf librdkafka.tar.gz
cd librdkafka
./configure
make
sudo make install
..
git clone https://github.com/apache/metron-bro-plugin-kafka.git
cd metron-bro-plugin-kafka
./configure --bro-dist=$HOME/src/bro-2.5.3/
make
sudo make install


##

sudo /usr/share/logstash/bin/logstash-plugin install logstash-output-exec
sudo /usr/share/logstash/bin/logstash-plugin install --no-verify
sudo apt-get install zookeeperd
sudo systemctl enable zookeeper
sudo systemctl start zookeeper

##
sudo tar -xvf ~/src/Debian-GNU-Linux-Profiles/NSM/ELK/packages/kafka_2.12-1.0.0.tgz
sudo mkdir -p /opt/kafka
sudo cp ~/src/Debian-GNU-Linux-Profiles/NSM/ELK/packages/kafka_2.12-1.0.0 -r /opt/kafka
sudo apt-get install libgeoip-dev
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
gunzip GeoLiteCity.dat.gz
