
# Monitoring System Example

1.  [Solution Overview](#org98fb4c1)
    1.  [NsmLab example](#org709b4f4)
    2.  [Data Sources](#orgf684a25)
    3.  [Map cyber activity to attacker infrastructure.](#org58e67bd)
        1.  [GeoIP](#org3a78eaa)
        2.  [Domain Tools](#org070df60)
    4.  [Malware analysis](#orge3bbe28)
    5.  [ALternative Tecnology stacks](#org83bbbba)
        1.  [PF<sub>RING</sub>](#orgd24bb1d)


<a id="org98fb4c1"></a>

# Solution Overview

we chose the following technological components to creat our monitoring system.


<a id="org709b4f4"></a>

## NsmLab example

The folloing table summarizes the techology at Esxi-NSM.lab

-   Virtual Server Host
    -   Vmware ESXi
    -   qemu (company machines)

-   Virtual Machines
    -   Window
    -   Linux

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>

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


<a id="orgf684a25"></a>

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


<a id="org58e67bd"></a>

## Map cyber activity to attacker infrastructure.

Actually, we are planning through follow ways to achieve this function, including domains and IPs, and connect them with nearly
every active's relationship on the Internet (Platform like ELK or real-time Web Ui).


<a id="org3a78eaa"></a>

### GeoIP

In this part, we will test and show your how to build a visual mapping  of the ip addresses of your nsm lab, by using Elasticsearch, Logstash, and Kibana.
So, make sure you have already done of the depoly Bro-suricata-Snort tutorial.

The MaxMInd provides the following products:

    free databases
    Paid databases

you should be know their most services and higt precision for customers, but this lab we are going to use free databases.

if you want to know more information about the produce, please reading here:
  <https://dev.maxmind.com/geoip/legacy/downloadable/#Download_Limits>

-   Geoip filter Plugin

<https://www.elastic.co/guide/en/logstash/current/plugins-filters-geoip.html#plugins-filters-geoip>

1.  Configure Logstash to use GeoIP


<a id="org070df60"></a>

### Domain Tools

those toolkit will help us uses various soures to gather information about domain names, host names, autonomous systems, routers etc.
<https://www.robtex.com/>

<https://www.domaintools.com/>


<a id="orge3bbe28"></a>

## Malware analysis

In this example, I've shown here on the lab we see that will need serveral different tools and operating systems avaliable to cover the range of use cases. that will help and support our work. 

Malware analysis and simulations signature development that feed the detection mechanisms，thus generates alerts within their environment, this is usually going to be with more signature-base intrusion detection systems like snort and suricata or both in some cases the bro framewokk Signature.

-   Virtual Tools

virustotal-search.py is a Python program to search VirusTotal for hashes.

virustotal-submit.py is a Python program to submit files to VirusTotal.
if you want detecting malware automatically and dont hae to submit a file. this scipt is useful for own investigation.

<https://blog.didierstevens.com/programs/virustotal-tools/>


<a id="org83bbbba"></a>

## ALternative Tecnology stacks


<a id="orgd24bb1d"></a>

### PF<sub>RING</sub>

-   Installing PF<sub>RING</sub>

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

