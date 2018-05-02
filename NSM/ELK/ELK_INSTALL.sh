#!/bin/bash
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.2.3-amd64.deb
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.3.deb
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.2.3.deb
sudo apt-get update
sudo apt-get install openjdk-8-jre
sudo dpkg -i *.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service logstash.service kibana.service
sudo systemctl start elasticsearch.service kibana.service logstash.service



##
sudo apt -y install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev libgeoip-dev zookeeperd autoconf python-pip python3-pip jq curl wget libsasl2-dev libhtp-dev
mkdir src
cd src
git clone https://github.com/bro/bro.git
cd bro
./configure
make
sudo make install
sudo ln -s /usr/local/bro/bin/bro /usr/local/bin
..
git clone https://github.com/apache/metron-bro-plugin-kafka
cd metron-bro-plugin-kafka
git clone https://github.com/edenhill/librdkafka.git
wget https://github.com/edenhill/librdkafka/archive/v0.11.4.tar.gz
cd librdkafka
./configure
make
sudo make install
..
./configure --bro-dist=../bro
make
sudo make install
##

sudo /usr/share/logstash/bin/logstash-plugin install logstash-output-exec
sudo /usr/share/logstash/bin/logstash-plugin install --no-verify
sudo apt-get install zookeeperd
sudo systemctl enable zookeeper
sudo systemctl start zookeeper

##
sudo tar -xvf packages/kafka_2.11-1.1.0.tgz
sudo mkdir -p /opt/kafka
sudo cp -r kafka_2.11-1.1.0 /opt/kafka
