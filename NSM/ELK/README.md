
# Table of Contents

1.  [About Open source NSM project](#orgac1e130)
2.  [Quicly Start](#org3e71585)
    1.  [Installing workflow Structure<code>[50%]</code>](#org5c69eb0)
3.  [Log Analysis in NSM](#orgf7010b6)
    1.  [Kafka & Spark <code>[0/1]</code>](#org23d4e7c)
        1.  [Troubleshooting](#org1fd7b3b)
        2.  [Bro Script for Kafka <code>[1/2]</code>](#orga867f20)
    2.  [Bat](#org93bd155)
        1.  [Virtualtotal](#org4caf6b6)
        2.  [BRO&#x2013;>HTTP](#org80a5e4a)
    3.  [Silk](#orga4faca7)
        1.  [Analysis logs with R languag](#orgc3aef93)
    4.  [ELK](#org6f041b7)
        1.  [Logstash<code>[1/2]</code>](#orgc47c072)
        2.  [Silk](#org82847ce)
        3.  [IDS](#org35a1aec)
        4.  [filter](#org6b48216)
    5.  [Bro](#org0a7f50c)
        1.  [Protocol](#org78c6c48)



<a id="orgac1e130"></a>

# About Open source NSM project

The open source NSM project is manuals of pratice which can able to help other maintainer to build a monitoring system. For data analysis and data visualization. This information will effectively draw integral structure with other open source components and academic tools in wide use.


<a id="org3e71585"></a>

# Quicly Start

    mkdir ~/src
    cd src
    git clone https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles.git
    bash Debian-GNU-Linux-Profiles/NSM/ELK/ELK_INSTALL.sh

Some configure files we were not coding shell in bash script such as logstash conf and ids conf etc.  So you should be know how to move conf files and control it.


<a id="org5c69eb0"></a>

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

    1.  Bro logs <code>[4/4]</code>
        -   [X] HTTP
        -   [X] ssh
        -   [X] dns
        -   [X] syslog
    2.  IDS logs
    3.  Silk <code>[0/0]</code>

7.  Log setting & configure files<code>[3/3]</code>

    -   [X] [testing]  Logstash
    -   [X] []  syslog
    -   [X] [DONE]  Snort & Suricata rule's templates
    -   [ ] [TODO] IDS yaml

8.  ELK plugin

    1.  DONE area3d\_vis
    
        -   State "DONE"       from              <span class="timestamp-wrapper"><span class="timestamp">[2018-09-28 Fri 19:42]</span></span>
    
    2.  DONE kbn\_network
    
        -   State "DONE"       from              <span class="timestamp-wrapper"><span class="timestamp">[2018-09-28 Fri 19:42]</span></span>

9.  Dashboard & Data visualization<code>[0/0]</code>

    -   Index of the Bro
    -   Index of suricata and snort
    -   Index of the Silk

10. Silk <code>[1/1]</code>

    -   [X] []  SIlk\_INSTALL.sh

11. AntiVirus<code>[1/1]</code>

    1.  DONE Clamav
    
        -   State "DONE"       from              <span class="timestamp-wrapper"><span class="timestamp">[2018-09-28 Fri 19:43]</span></span>

12. Demo Show up

    1.  Bro Scripts
        -   Detect popular Application
        -   Notice
    2.  Bat Scripts
    3.  Logstash API


<a id="orgf7010b6"></a>

# Log Analysis in NSM


<a id="org23d4e7c"></a>

## Kafka & Spark <code>[0/1]</code>


<a id="org1fd7b3b"></a>

### Troubleshooting

bash /opt/kafka/kafka\_2.12-1.0.0/bin/kafka-console-consumer.sh &#x2013;bootstrap-server localhost:9092 &#x2013;topic software

if you got some information looks like Bro log that will be good.


<a id="orga867f20"></a>

### TODO Bro Script for Kafka <code>[1/2]</code>

1.  DONE Example 1

    -   State "DONE"       from "TODO"       <span class="timestamp-wrapper"><span class="timestamp">[2018-05-29 Tue 00:17]</span></span>
    
        Bro-kafka-log.bro: from <https://github.com/apache/metron-bro-plugin-kafk>
    README we were knew Example 1. because of phase-1 is a  basic NSMsystem or that is first push. So loaded Example 1 at local.bro

2.  TODO Example 2 or 3


<a id="org93bd155"></a>

## Bat


<a id="org4caf6b6"></a>

### Virtualtotal


<a id="org80a5e4a"></a>

### BRO&#x2013;>HTTP

1.  DONE Agent & uri keyword to parse specialy info.

    -   State "DONE"       from "TODO"       <span class="timestamp-wrapper"><span class="timestamp">[2018-05-29 Tue 14:23]</span></span>

2.  TODO DNS <code>[0/1]</code>

    1.  TODO pdns & bro scirpt<code>[100%]</code>
    
        -   [X] count DNS and record first time and last time


<a id="orga4faca7"></a>

## Silk


<a id="orgc3aef93"></a>

### TODO Analysis logs with R languag


<a id="org6f041b7"></a>

## ELK


<a id="orgc47c072"></a>

### Logstash<code>[1/2]</code>

-   [X] Bro-Kafka\_example-1 for logstash conf files
    -   NSM/ELK/conf/bro-kafka.conf
-   [ ] Example 2 & 3


<a id="org82847ce"></a>

### Silk


<a id="org35a1aec"></a>

### IDS

-   [X] Simple conf (/NSM/ELK/conf/syslog.conf & /NSM/logs/sys-logs-conf/ELK\_IDS.conf)
-   [ ] [TODO] structured data apllicaitons.


<a id="org6b48216"></a>

### filter

1.  Bro

    1.  Protocol<code>[1/1]</code>
    
        1.  DONE Move out HTTP-ref tag
        
            -   State "DONE"       from              <span class="timestamp-wrapper"><span class="timestamp">[2018-05-29 Tue 00:45]</span></span>


<a id="org0a7f50c"></a>

## Bro


<a id="org78c6c48"></a>

### Protocol

1.  TODO Http <code>[0/0]</code>

    -   Application <code>[2/2]</code>
        -   [X] identifies QQ verstion and QQ\_num platform, otherwise parses some special data.
        -   [X] decode URl and SMTP subject for Chinese unicode
    
    by Bro script or combined ways.

