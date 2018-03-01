
# Monitoring System Example

1.  [Solution Overview](#orgd951a7b)
    1.  [NsmLab example](#org55b1d4a)
    2.  [Data Sources](#org9e28c3e)
    3.  [Map cyber activity to attacker infrastructure.](#org8417c27)
        1.  [GeoIP](#orgd8fa711)
    4.  [Malware analysis](#org7e62646)
        1.  [Virtualotal](#org3712605)
    5.  [ALternative Tecnology stacks](#orgb770cd1)
        1.  [Bro](#orga615193)
        2.  [Snort/Suricata](#org3abab69)
    6.  [Open source intelligence (OSINT)](#org58af098)
        1.  [Threl intel platform](#org610cc59)
    7.  [Data analysis with python or Clojure](#org410946d)
        1.  [PySpark](#orge626ece)
        2.  [Using Clojure achived Spark steaming](#org50fcd19)
        3.  [Virtualotal type of collected netflow.](#org8ea5ef6)


<a id="orgd951a7b"></a>

# Solution Overview

we chose the following technological components to creat our monitoring system.


<a id="org55b1d4a"></a>

## NsmLab example

The folloing table summarizes the techology at Esxi-NSM.lab

-   Virtual Server Host:
    -   Vmware ESXi
    -   qemu (company machines)

-   Virtual Machines:
    -   Window
    -   Linux

Sensor Server:

    Snort
    Suricata
    Bro
    Silk

Pcap Server:

    Netsniff-NG 

Analysis Server:

    Sguil
    FLowBat
    Bat

Operating Systems(client)

    Windows 10
    Debian 9
    Operating Systems(Server)

    Debian 9
    Windows Server 2012 Domain controller

Managerment platform

    The hive 


<a id="org9e28c3e"></a>

## Data Sources

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left">Category</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Packet Capture</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Network Flow Data</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Operating System Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Windows Sysmon Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">HTTP Transaction Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">DNS Transaction Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Antivirus Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">IDS Alerts logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Firewall Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Application Access Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">E-Mail Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Bro Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">VPN Access Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">SSL Transaction Logs</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Memory Image</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">OSINT – Reputation Data</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">OSINT – Ownership Data</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Malware Sandbox</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>


<a id="org8417c27"></a>

## Map cyber activity to attacker infrastructure.

Actually, we are planning through follow ways to achieve this function, including domains and IPs, and connect them with nearly every active's relationship on the Internet (Platform like ELK or real-time Web Ui).


<a id="orgd8fa711"></a>

### GeoIP

In this part, we will test and show your how to build a visual mapping of the ip addresses of your nsm lab, by using Elasticsearch, Logstash, and Kibana. So, make sure you have already done of the depoly Bro-suricata-Snort tutorial.
The MaxMInd provides the following products:

    free databases
    Paid databases

you should be know their most services and higt precision for customers, but this lab we are going to use free databases.

    sudo apt-get install libgeoip-dev
    
      wget -N http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
      ## Install database
      gunzip GeoLiteCity.dat.gz
      sudo mkdir  /usr/local/share/GeoIP/
      sudo mv GeoLiteCity.dat /usr/local/share/GeoIP/
      sudo mv GeoLiteCity.dat /usr/local/share/GeoIP/

Geolocation

<https://github.com/bro/bro-scripts/blob/master/conn-add-geodata.bro>

    filter {
      geoip {
        source => "evt_dstip"
        target => "geoip"
        database => "/usr/local/share/GeoIP/GeoLiteCity.dat"
        add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][city\_name]}"  ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][continent\_code]}" ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][country\_code2]}"  ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][country\_code3]}"  ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][country\_name]}" ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][dma\_code]}"  ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][postal\_code]}"  ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][region\_name]}"  ]
      }
    }

.
├── GeoIPCity.dat
├── GeoIPCityv6.dat
├── GeoIP.dat
└── GeoIPv6.dat

    sudo wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz

-   Testing GeoIp Database

bro -e "print lookup<sub>location</sub>(8.8.8.8);"

if you have an error message like this: 
it's does matter, then you may need to either rename or move your GeoIP city database file (the error message should give you the full pathname of the database file that Bro is looking for).

    <command line>, line 3: Failed to open GeoIP City database: /usr/share/GeoIP/GeoIPCity.dat
    <command line>, line 3: Fell back to GeoIP Country database
    <command line>, line 3: Failed to open GeoIP Cityv6 database: /usr/share/GeoIP/GeoIPCityv6.dat
    <command line>, line 3: Failed to open GeoIPv6 Country database: /usr/share/GeoIP/GeoIPv6.dat

sudo bin/logstash-plugin install logstash-filter-geoip

-   Testing GeoIp Database

bro -e "print lookup<sub>location</sub>(8.8.8.8);"

`[country_code=US, region=<uninitialized>, city=<uninitialized>, latitude=37.750999, longitude=-97.821999]`

if you got this output that should be good.

if you want to know more information about the produce, please reading here: <https://dev.maxmind.com/geoip/legacy/downloadable/#Download_Limits>

-   Geoip filter Plugin

<https://www.elastic.co/guide/en/logstash/current/plugins-filters-geoip.html#plugins-filters-geoip>

Configure Logstash to use GeoIP

-   Domain Tools

those toolkit will help us uses various soures to gather information about domain names, host names, autonomous systems, routers etc. <https://www.robtex.com/>

<https://www.domaintools.com/>


<a id="org7e62646"></a>

## Malware analysis

In this example, I've shown here on the lab we see that will need serveral different tools and operating systems avaliable to cover the range of use cases. that will help and support our work.

Malware analysis and simulations signature development that feed the detection mechanisms，thus generates alerts within their environment, this is usually going to be with more signature-base intrusion detection systems like snort and suricata or both in some cases the bro framewokk Signature.


<a id="org3712605"></a>

### Virtualotal

virustotal-search.py is a Python program to search VirusTotal for hashes.

virustotal-submit.py is a Python program to submit files to VirusTotal. if you want detecting malware automatically and dont hae to submit a file. this scipt is useful for own investigation.

<https://blog.didierstevens.com/programs/virustotal-tools/>


<a id="orgb770cd1"></a>

## ALternative Tecnology stacks


<a id="orga615193"></a>

### Bro

1.  PF<sub>RING</sub>

    Pre installtion requirements
    
        sudo apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev \
        build-essential autoconf automake libtool libpcap-dev libnet1-dev \
        libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 \
        make libmagic-dev libnuma-dev build-essential bison flex linux-headers-$(uname -r)
        
        ;; next step, Download and install PF_RING for you system followin the instructions here.
        
        mkdir src
        cd src
        git clone https://github.com/ntop/PF_RING.git
        cd PF_RING
        make 
        ;;*NOT* as root
        
        make install
        
        ;;elevate as *root*
        
        
        cd kernel
        sudo make install
        cd ../userland/lib
        sudo make install
        
        ;;then
        sudo modprobe pf_ring
        
        ;;To check if you have everything you need, enter:
        
        modinfo pf_ring && cat /proc/net/pf_ring/info
        
        ;;;;;;;;;;;; the feedback likes this:
        
        filename:       /lib/modules/4.9.0-4-amd64/kernel/net/pf_ring/pf_ring.ko
        alias:          net-pf-27
        version:        7.1.0
        description:    Packet capture acceleration and analysis
        author:         ntop.org
        license:        GPL
        srcversion:     D173304DA43FD84C21E264E
        depends:
        vermagic:       4.9.0-4-amd64 SMP mod_unload modversions
        parm:           min_num_slots:Min number of ring slots (uint)
        parm:           perfect_rules_hash_size:Perfect rules hash size (uint)
        parm:           enable_tx_capture:Set to 1 to capture outgoing packets (uint)
        parm:           enable_frag_coherence:Set to 1 to handle fragments (flow coherence) in clusters (uint)
        parm:           enable_ip_defrag:Set to 1 to enable IP defragmentation(only rx traffic is defragmentead) (uint)
        parm:           quick_mode:Set to 1 to run at full speed but with upto one socket per interface (uint)
        parm:           force_ring_lock:Set to 1 to force ring locking (automatically enable with rss) (uint)
        parm:           enable_debug:Set to 1 to enable PF_RING debug tracing into the syslog, 2 for more verbosity (uint)
        parm:           transparent_mode:(deprecated) (uint)
        PF_RING Version          : 7.1.0 (dev:fcc142db7e2d5586a2923cc20f6a2cc4d7ebded5)
        Total rings              : 0
        
        Standard (non ZC) Options
        Ring slots               : 4096
        Slot version             : 17
        Capture TX               : Yes [RX+TX]
        IP Defragment            : No
        Socket Mode              : Standard
        Cluster Fragment Queue   : 0
        Cluster Fragment Discard : 0

2.  Bro to Kafka to Spark

    -   Install librdkafka C library implementation of the Apache Kafka protocol
        
            sudo apt-get install  librdkafka-dev
    
    -   Inbstall local spark server
        `pip install pyspark`
    
    -   Setting up Bro with the Kafka Plugin
        
            git clone https://github.com/apache/metron-bro-plugin-kafka
            cd metron-bro-plugin-kafka
             ./configure --bro-dist=/home/gtrun/src/bro ##$BRO_SRC_PATH
            sudo make install
            ## ensure you have already cloned Bro Path in SRC (~/src/bro) directory.
            
            ##Test this command that the plugin was installed successfully.
            
            sudo bro -N Apache::Kafka
            Apache::Kafka - Writes logs to Kafka (dynamic, version 0.1)
    
    -   Install Kafka:
    
        
                    # You can verify that JDK  is installed properly by running the following command:
                      sudo java -version
                    #Next install  ZooKeeper
                    sudo apt-get install zookeeperd
                    # test it by running the following command:
        
                    netstat -ant | grep :2181
                    #if the zookeeperd installed successfully , you should see the following Output:
        
                    tcp6       0      0 :::2181                 :::*                    LISTEN
        
                    #  Create a service User for Kafka
                    sudo adduser --system --no-create-home --disabled-password --disabled-login kafka
        
        
                    # Download kafka and create a directory for Kafka installation:
                    cd src
                    sudo mkdir /opt/Kafka
        
                    wget http://apache.mirrors.hoobly.com/kafka/1.0.0/kafka_2.12-1.0.0.tgz
                    sudo tar -xvzf kafka_2.12-1.0.0.tgz --directory /opt/Kafka --strip-components 1
        
        ## Configuring Kafka Server
        
        ## create a directory for Kafka persists data to disk 
        
          sudo mkdir /var/lib/kafka
          sudo mkdir /var/lib/kafka/data
        
        
        ###By default, Kafka doesn’t allow us to delete topics. To be able to delete topics, find the line and change it.
        The server config file stored in ~/opt/kafka/config/server.properties~
        ## find the line and change the value to true
        
        delete.topic.enable = true
        
        ###then, change log directory.
        log.dirs=/var/lib/kafka/data
        
        ## Permission of Directories
        sudo chown -R kafka:nogroup /opt/kafka
        sudo chown -R kafka:nogroup /var/lib/kafka
        
        ## edit  /opt/kafka/config/server.properties 
        sudo nano /opt/kafka/config/server.properties 
        
        ###Testing Kafka Server
         sudo  /opt/Kafka/kafka_2.12-1.0.0/bin/kafka-server-start.sh /opt/Kafka/kafka_2.12-1.0.0/config/server.properties
        
        ## In another terminal create a topic
        sudo /opt/Kafka/kafka_2.12-1.0.0/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1  --partitions 1 --topic testing
        
        ##You should get the following output, if the server has started successfully:
        Created topic "testing".
        
        
        ##After, publish some massages in testing topic.
        sudo /opt/Kafka/kafka_2.12-1.0.0/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic testing
        
        > hello
        
        #finally,use consumer command to check for messages on Apache Kafka Topic called testing by running the following command:
        sudo /opt/Kafka/kafka_2.12-1.0.0/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic testing --from-beginning
        
        >hello
        
        ##Creating Kafka as a service on startup
        sudo nano /etc/systemd/system/kafka.service
        
        
        
        [Unit]
        Description=High-available, distributed message broker
        After=network.target
        [Service]
        User=kafka
        ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
        [Install]
        WantedBy=multi-user.target
        
        
        #Start the newly created service
        
        sudo systemctl start kafka
        sudo systemctl status  zookeeper.service
    
    The local policy scripts (which you can edit) are located in/usr/local/bro/share/bro/site/local.bro, add the Bro script language to your local.bro file as shown to demonstrate the example.
    
    @load 
    redef Kafka::topic<sub>name</sub> = "";
    redef Kafka::logs<sub>to</sub><sub>send</sub> = set(Conn::LOG, <:LOG>, DNS::LOG, SMTP::LOG);
    redef Kafka::kafka<sub>conf</sub> = table(["metadata.broker.list"] = "localhost:9092");


<a id="org3abab69"></a>

### Snort/Suricata

-   AF<sub>PACKET</sub>

-   RF<sub>RING</sub>
-   NetMap

IPFW
NFQ


<a id="org58af098"></a>

## Open source intelligence (OSINT)


<a id="org610cc59"></a>

### Threl intel platform

   osint can be almost anything that criteria it could be a list of domains that are resolved to a specific IP address a list of malware hash is associated with Google search any of those pieces of information
(like Virtualotal, you can use these type of websites to help determine reputation)
Ownership: Using domain tools(whois etc.) checking RIPE or ARIN for IP addresss registered to the information. if this domain that is inherently mailicous.

Age - The age of a website is really important. if its someting that malicious actor recently created for possbile a redirect.

Related Indicators: checking any source informaiton for  intelligence, blog posts, reports etx. with related indicators.

will Upload later&#x2026;


<a id="org410946d"></a>

## Data analysis with python or Clojure


<a id="orge626ece"></a>

### PySpark

upload later&#x2026;


<a id="org50fcd19"></a>

### Using Clojure achived Spark steaming

TODO


<a id="org8ea5ef6"></a>

### Virtualotal type of collected netflow.

Todo

