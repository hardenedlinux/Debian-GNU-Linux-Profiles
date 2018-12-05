#!/bin/bash
sudo apt-get update
mkdir ~/src
cd ~/src
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.5.1-amd64.deb
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.5.1.deb
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.5.1.deb
sudo apt-get update
sudo apt-get install openjdk-8-jre
sudo dpkg -i *.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service logstash.service kibana.service
sudo systemctl start elasticsearch.service kibana.service logstash.service

echo config.reload.automatic: true |sudo tee -a /etc/logstash/logstash.yml
echo config.reload.interval: 3s |sudo tee -a /etc/logstash/logstash.yml
sudo systemctl restart logstash.service

##
sudo apt -y install cmake make gcc g++ flex bison libpcap-dev python-dev swig zlib1g-dev libgeoip-dev zookeeperd autoconf python-pip python3-pip jq curl wget libsasl2-dev libhtp-dev libssl-dev
mkdir src
cd ~/src
echo "Bro install..."
wget https://www.bro.org/downloads/beta/bro-2.6-beta3.tar.gz
tar -xvf bro-2.6-beta3.tar.gz
cd bro-2.6-beta3/
./configure
make
sudo make install
sudo ln -s /usr/local/bro/bin/bro* /usr/local/bin
..
echo "Broker install..."
wget https://www.bro.org/downloads/broker-1.1.1.tar.gz
tar -xvf broker-1.1.1.tar.gz
cd broker-1.1.1
./configure
sudo make -j4 install
echo "=== Broker Installation finished ==="

#
su
curl -sL https://deb.nodesource.com/setup_9.x | bash -
apt-get install nodejs
exit
### if you git issue for nop, just put this command "sudo npm rebuild"

echo "ELK-Script install..."

# cd /usr/share/kibana/src/core_plugins
# sudo git clone https://github.com/JuanCarniglia/area3d_vis
# cd area3d_vis
# cd releases/5.5/
# sudo npm install vis
# sudo npm install
# cd ..
# sudo git clone https://github.com/dlumbrer/kbn_network.git network_vis -b 6-dev
# cd network_vis
# sudo rm -rf images/
# sudo npm install

cd ~/src
wget https://github.com/edenhill/librdkafka/archive/v0.11.4.tar.gz
sudo tar -xvf v0.11.4.tar.gz
cd librdkafka-0.11.4/
sudo ./configure --enable-sasl
sudo make
sudo make install
cd ~/src/
git clone https://github.com/apache/metron-bro-plugin-kafka.git
cd metron-bro-plugin-kafka
./configure --bro-dist=$HOME/src/bro-2.5.4/
make 
sudo make install


##

sudo /usr/share/logstash/bin/logstash-plugin install logstash-output-exec logstash-input-jdbc
sudo /usr/share/logstash/bin/logstash-plugin install --no-verify
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-geoip

sudo apt-get install zookeeperd
sudo systemctl enable zookeeper
sudo systemctl start zookeeper

##
sudo cp ~/src/Debian-GNU-Linux-Profiles/NSM/ELK/packages/kafka_2.12-1.0.0.tgz ~/src
sudo tar -xvf kafka_2.12-1.0.0.tgz
sudo mv kafka_2.12-1.0.0 /opt/kafka
sudo sed -i '/^log.dirs/{s/=.*//;}' /opt/kafka/config/server.properties
sudo sed -i 's/^log.dirs/log.dirs=\/var\/lib\/kafka/' /opt/kafka/config/server.properties
sudo mv ~/src/Debian-GNU-Linux-Profiles/NSM/ELK/packages/kafka.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable kafka
sudo systemctl start kafka

sudo apt-get install libgeoip-dev
cd ~/src
wget http://apache.claz.org/spark/spark-2.3.0/spark-2.3.0-bin-hadoop2.7.tgz
sudo tar -xvf spark-2.3.0-bin-hadoop2.7.tgz
sudo mv spark-2.3.0-bin-hadoop2.7 /opt/spark
