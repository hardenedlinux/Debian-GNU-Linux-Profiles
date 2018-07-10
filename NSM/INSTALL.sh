#!/bin/bash

wget https://artifacts.elastic.co/downloads/kibana/kibana-6.2.2-amd64.deb
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.2.deb
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.2.2.deb
sudo dpkg -i *.deb
