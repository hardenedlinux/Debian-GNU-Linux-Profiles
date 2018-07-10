#!/bin/bash
# install x-pack
sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack
sudo /usr/share/kibana/bin/kibana-plugin install x-pack
echo 'xpack.security.enabled: false' | sudo tee -a /etc/elasticsearch/elasticsearch.yml
sudo /usr/share/logstash/bin/logstash-plugin install x-pack
sudo service elasticsearch restart
sudo service kibana restart
sudo service logstash restart
