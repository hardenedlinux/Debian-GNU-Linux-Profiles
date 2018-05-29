
# Table of Contents

1.  [About Open source NSM project](#org8ca79cf)
2.  [Quicly Start](#org383306d)
    1.  [Installing workflow Structure<code>[50%]</code>](#orge0d0dee)
3.  [Log Analysis in NSM](#org7f0ac26)
    1.  [Kafka & Spark <code>[0/1]</code>](#orge033989)
        1.  [Troubleshooting](#org09634db)
        2.  [Bro Script for Kafka <code>[1/2]</code>](#org1be5635)
    2.  [Bat](#orgf426175)
        1.  [Virtualtotal](#org5207ad1)
        2.  [DNS](#orgf91799b)
        3.  [](#orgeb9b575)
    3.  [Silk](#orgdca6abb)
        1.  [Analysis logs with R languag](#orgaa0252e)
    4.  [ELK](#orgeadadc3)
        1.  [Logstash<code>[1/2]</code>](#orge239ca5)
        2.  [Silk](#orga9509f1)
        3.  [IDS](#orgf99bc47)
        4.  [filter](#org77d215e)



<a id="org8ca79cf"></a>

# About Open source NSM project

The open source NSM project is manuals of pratice which can able to help other maintainer to build a monitoring system. For data analysis and data visualization. Those  informations will effectively draw integral structure with other open source components and academic tools in wide use.


<a id="org383306d"></a>

# Quicly Start


<a id="orge0d0dee"></a>

## Installing workflow Structure<code>[50%]</code>

1.  DONE ELK\_INSTALL.sh

    -   State "DONE"       from              <span class="timestamp-wrapper"><span class="timestamp">[2018-05-28 Mon 17:34]</span></span>
    
    1.  Kibana
    
    You just need to modify two commands line in Kibana
    
        server.port: 5601 ##default setting
        server.host: "localhost"  
        elasticsearch.url: "http://localhost:9200"
    
    1.  Logstash
    
    The configuation command exists was there (ELK\_INSTALL.SH)
    
        config.reload.automatic: true 
        config.reload.interval: 3s
    
    1.  Elasticsearch
        
        Testing Service
    2.  Bro
    3.  Lib-Kafka
    
    if you straight download  or clone Lib-kafka whatever librdkafka-dev or ..lib++1 0.9 verstion that will be got a error loaded in library. So I had put correctly Librd verstion sotred in Debian\_Profile/NSM/ELK/Package/
    
    1.  kafka
    
    Check directory Package or run command Bash shell.
    
    1.  metro\_bro-plugin-kafka
        
        metro\_bro\_plugin-kafka git repository is located at github.
    
    2.  Zookeeper
    
    9.Geoip
    
    1.  Plugin for ELK<code>[2/2]</code>
    
        -   [X] [] X-pack
        -   [X] [] elasticdump

2.  TODO Python-Components <code>[2/4]</code>

    run NSM\_PYTHON.sh  
    
    -   [X] []  Bat
    -   [X] []  Broccoli
        Brocoolie is a API
    -   [ ] []  Pyspark
    -   [ ] []  Other Scripts of the

3.  Testing Scripts<code>[2/4]</code>

    -   [X] [private]  Reply sources
    -   [X] []  Automatically Reply Pcap's Scripts
    
    -   [ ] []  Export Kibana Configuration
        The Bash shell can be exported in Json file, and easy to set up and use.
    
    you can make them as templates or simply export them.
    
    -   [ ] []  Loaded Config files in Logstash
        same like way.

4.  Check\_ELK\_Service.sh

5.  IDS\_INSTALL.sh <code>[1/3]</code>

    -   [X] []  Snort & Suricata
    -   [ ] [TODO]  Basic and defaulted configuration
    -   [ ] <code>[30%]</code> Configuring Suricata Rules

6.  Filter

    1.  Bro logs
    2.  IDS logs
    3.  Silk <code>[0/0]</code>

7.  Log setting & configure files<code>[2/3]</code>

    -   [X] [testing]  Logstash
    -   [X] []  syslog
    -   [ ] [TODO]  Snort & Suricata

8.  Dashboard & Data visualization<code>[0/0]</code>

    -   Index of the Bro
    -   Index of suricata and snort
    -   Index of the Silk

9.  Silk <code>[1/1]</code>

    -   [X] []  SIlk\_INSTALL.sh

10. Demo Show up

    1.  Bro Scripts
        -   Detect popular Application
        -   Notice
    2.  Bat Scripts
    3.  Logstash API


<a id="org7f0ac26"></a>

# Log Analysis in NSM


<a id="orge033989"></a>

## Kafka & Spark <code>[0/1]</code>


<a id="org09634db"></a>

### Troubleshooting

bash /opt/kafka/kafka\_2.12-1.0.0/bin/kafka-console-consumer.sh &#x2013;bootstrap-server localhost:9092 &#x2013;topic software

if you got some information looks like Bro log that will be good.


<a id="org1be5635"></a>

### TODO Bro Script for Kafka <code>[1/2]</code>

1.  DONE Example 1

    -   State "DONE"       from "TODO"       <span class="timestamp-wrapper"><span class="timestamp">[2018-05-29 Tue 00:17]</span></span>
    
        Bro-kafka-log.bro: from <https://github.com/apache/metron-bro-plugin-kafk>
    README we were knew Example 1. because of phase-1 is a  basic NSMsystem or that is frist push. So loaded Example 1 at local.bro

2.  TODO Example 2 or 3


<a id="orgf426175"></a>

## Bat


<a id="org5207ad1"></a>

### Virtualtotal


<a id="orgf91799b"></a>

### DNS


<a id="orgeb9b575"></a>

### 


<a id="orgdca6abb"></a>

## Silk


<a id="orgaa0252e"></a>

### Analysis logs with R languag


<a id="orgeadadc3"></a>

## ELK


<a id="orge239ca5"></a>

### TODO Logstash<code>[1/2]</code>

-   [X] Bro-Kafka\_example-1 for logstash conf files
    -   NSM/ELK/conf/bro-kafka.conf
-   [ ] Example 2 & 3


<a id="orga9509f1"></a>

### TODO Silk


<a id="orgf99bc47"></a>

### TODO IDS


<a id="org77d215e"></a>

### TODO filter

