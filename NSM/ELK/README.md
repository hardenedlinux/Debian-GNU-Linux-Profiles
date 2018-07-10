
# Table of Contents

1.  [About Open source NSM project](#org775cea0)
2.  [Quicly Start](#org797416b)
    1.  [Installing workflow Structure<code>[50%]</code>](#org225da86)
3.  [Log Analysis in NSM](#org5ba6280)
    1.  [Kafka & Spark <code>[0/1]</code>](#orgeac0e1a)
        1.  [Troubleshooting](#orgb77e361)
        2.  [Bro Script for Kafka <code>[1/2]</code>](#orgef442b8)
    2.  [Bat](#org924be4f)
        1.  [Virtualtotal](#orgcb5fa1c)
        2.  [BRO&#x2013;>HTTP](#orge218576)
    3.  [Silk](#orgbe4e7a5)
        1.  [Analysis logs with R languag](#orge1ad245)
    4.  [ELK](#org6ee46da)
        1.  [Logstash<code>[1/2]</code>](#orgc863ad8)
        2.  [Silk](#orga4a39c3)
        3.  [IDS](#org4d35022)
        4.  [filter](#org77a1b79)
    5.  [Bro](#org38917e3)
        1.  [Protocol](#org9e12dbb)



<a id="org775cea0"></a>

# About Open source NSM project

The open source NSM project is manuals of pratice which can able to help other maintainer to build a monitoring system. For data analysis and data visualization. This information will effectively draw integral structure with other open source components and academic tools in wide use.


<a id="org797416b"></a>

# Quicly Start

    mkdir ~/src
    cd src
    git clone https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles.git
    bash Debian-GNU-Linux-Profiles/NSM/ELK/ELK_INSTALL.sh

Some configure files we were not coding shell in bash script such as logstash conf and ids conf etc.  So you should be know how to move conf files and control it.


<a id="org225da86"></a>

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


<a id="org5ba6280"></a>

# Log Analysis in NSM


<a id="orgeac0e1a"></a>

## Kafka & Spark <code>[0/1]</code>


<a id="orgb77e361"></a>

### Troubleshooting

bash /opt/kafka/kafka\_2.12-1.0.0/bin/kafka-console-consumer.sh &#x2013;bootstrap-server localhost:9092 &#x2013;topic software

if you got some information looks like Bro log that will be good.


<a id="orgef442b8"></a>

### TODO Bro Script for Kafka <code>[1/2]</code>

1.  DONE Example 1

    -   State "DONE"       from "TODO"       <span class="timestamp-wrapper"><span class="timestamp">[2018-05-29 Tue 00:17]</span></span>
    
        Bro-kafka-log.bro: from <https://github.com/apache/metron-bro-plugin-kafk>
    README we were knew Example 1. because of phase-1 is a  basic NSMsystem or that is first push. So loaded Example 1 at local.bro

2.  TODO Example 2 or 3


<a id="org924be4f"></a>

## Bat


<a id="orgcb5fa1c"></a>

### Virtualtotal


<a id="orge218576"></a>

### BRO&#x2013;>HTTP

1.  DONE Agent & uri keyword to parse specialy info.

    -   State "DONE"       from "TODO"       <span class="timestamp-wrapper"><span class="timestamp">[2018-05-29 Tue 14:23]</span></span>

2.  TODO DNS <code>[0/1]</code>

    1.  TODO pdns & bro scirpt<code>[100%]</code>
    
        -   [X] count DNS and record first time and last time


<a id="orgbe4e7a5"></a>

## Silk


<a id="orge1ad245"></a>

### TODO Analysis logs with R languag


<a id="org6ee46da"></a>

## ELK


<a id="orgc863ad8"></a>

### Logstash<code>[1/2]</code>

-   [X] Bro-Kafka\_example-1 for logstash conf files
    -   NSM/ELK/conf/bro-kafka.conf
-   [ ] Example 2 & 3


<a id="orga4a39c3"></a>

### Silk


<a id="org4d35022"></a>

### IDS

-   [X] Simple conf (/NSM/ELK/conf/syslog.conf & /NSM/logs/sys-logs-conf/ELK\_IDS.conf)
-   [ ] [TODO] structured data apllicaitons.


<a id="org77a1b79"></a>

### filter

1.  Bro

    1.  Protocol<code>[1/1]</code>
    
        1.  DONE Move out HTTP-ref tag
        
            -   State "DONE"       from              <span class="timestamp-wrapper"><span class="timestamp">[2018-05-29 Tue 00:45]</span></span>


<a id="org38917e3"></a>

## Bro


<a id="org9e12dbb"></a>

### Protocol

1.  TODO Http <code>[0/0]</code>

    -   Application <code>[2/2]</code>
        -   [X] identifies QQ verstion and QQ\_num platform, otherwise parses some special data.
        -   [X] decode URl and SMTP subject for Chinese unicode
    
    by Bro script or combined ways.

