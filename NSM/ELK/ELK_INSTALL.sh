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
mkdir src
cd src
https://github.com/bro/bro.git
git clone https://github.com/apache/metron-bro-plugin-kafka
cd metron-bro-plugin-kafka
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
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
