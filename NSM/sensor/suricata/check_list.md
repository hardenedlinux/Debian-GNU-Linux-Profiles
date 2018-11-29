
# Table of Contents

1.  [Deployment](#orgc1093a1)
    1.  [Basic information](#org8a4820a)
    2.  [Snort.conf to Suricata.yaml](#org31e068d)
    3.  [Workflows](#orgb77e17e)
    4.  [Extension<code>[2/2]</code>](#org6f8f2ef)
    5.  [Lua](#org0bcd511)
    6.  [Yaml](#orgc5d1d03)
    7.  [Evebox Installation](#orgd430288)
2.  [alert](#orgdf8fbf2)
    1.  [TCP](#orgf0e0ad6)
    2.  [http](#org6038a35)


<a id="orgc1093a1"></a>

# Deployment


<a id="org8a4820a"></a>

## Basic information

<https://researchspace.auckland.ac.nz/bitstream/handle/2292/31460/whole.pdf>


<a id="org31e068d"></a>

## Snort.conf to Suricata.yaml

<https://redmine.openinfosecfoundation.org/projects/suricata/wiki/Snortconf_to_Suricatayaml>

<https://bricata.com/blog/snort-suricata-bro-ids/> [BLOG]


<a id="orgb77e17e"></a>

## Workflows

**Capture methods**

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">IDS mode</td>
<td class="org-left">AF<sub>Packet</sub></td>
<td class="org-left">PF<sub>RING</sub></td>
<td class="org-left">NETMAP</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">IPS mode</td>
<td class="org-left">Netfilter(nfqueue)</td>
<td class="org-left">IPFW</td>
<td class="org-left">AF<sub>Packet</sub></td>
<td class="org-left">NETMAP</td>
</tr>


<tr>
<td class="org-left">Cross platform</td>
<td class="org-left">Libpcap</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Specialized Capture</td>
<td class="org-left">Endace</td>
<td class="org-left">Napatech</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>

-   AF<sub>Packet</sub> 
    -   Linux default
    -   Workds outside the box
-   PF<sub>RING</sub>
    -   Linux and intel NICs only
    -   Needs kernel module compilation

-   NETMAP
    -   Linux and FreeBSD
    -   needs kernel module complied and loaded

-   PCAP
    -   Cross platform (Linux/BSD/Windows)
    -   Least performant of the above mentioned

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left">System</td>
</tr>


<tr>
<td class="org-left">Ethernet Card</td>
</tr>


<tr>
<td class="org-left">RX- Receive Buffer</td>
</tr>


<tr>
<td class="org-left">Suricata</td>
</tr>
</tbody>
</table>

Start suricata with af-packet (AFP): 

`suricata -c /etc/suricata/suricata.yaml -v --af-packet`

Start suricata with af-packet (AFP) only on eth0:

`suricata -c /etc/suricata/suricata.yaml -v --af-packet=eth0`

Ethtool installation: 

`apt-get install ethtool`

For more information: 

`man ethtool`

`sudo ethtool -h`

    Here is how you can disable specific offloading settings if needed: 
    
    ethtool -K eth3 tso off 
    ethtool -K eth3 gro off 
    ethtool -K eth3 lro off 
    ethtool -K eth3 gso off 
    ethtool -K eth3 rx off 
    ethtool -K eth3 tx off 
    ethtool -K eth3 sg off 
    ethtool -K eth3 rxvlan off 
    ethtool -K eth3 txvlan off


<a id="org6f8f2ef"></a>

## Extension<code>[2/2]</code>

<https://github.com/StamusNetworks/scirius>

-   [X] Scirius Ruleset Manager
-   [X] EVEBOX


<a id="org0bcd511"></a>

## TODO Lua

Suricata signatures for network fingerprints


<a id="orgc5d1d03"></a>

## TODO Yaml


<a id="orgd430288"></a>

## Evebox Installation

    
    
       Installation
    
       sudo -i
    
       cat >> /etc/apt/sources.list.d/evebox.list <<EOF
    deb http://files.evebox.org/evebox/debian unstable main 
    EOF  
    
    Ctrl+D
    
    sudo apt-get update && sudo apt-get -y --allow-unauthenticated install evebox 
    
    sudo evebox oneshot /var/log/suricata/eve.json 
    
    #Generate some data examples in a separate terminal: 
    
    cd /tmp  
    
    seq 5 | xargs -I -- wget testmyids.com 
    
    wget --no-check-certificate https://untrusted-root.badssl.com/ https://expired.badssl.com/ 
    
    sudo apt-get update 


<a id="orgdf8fbf2"></a>

# alert

**tls**

    alert tls $EXTERNAL_NET any -> $HOME_NET any (msg:"OSIF TROJAN Observed Malicious SSL Cert (Orcus RAT)"; flow:established,from_server;tls_cert_subject;content:"CN=XXX";classtype:trojan-activity;sid:1;rev:1;)

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">Details & wireshark</th>
<th scope="col" class="org-left">Rules<sub>format</sub></th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">protocol</td>
<td class="org-left">tls</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">alert tls</td>
</tr>


<tr>
<td class="org-left">Destination</td>
<td class="org-left">$HOME<sub>NET,port</sub> any</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">$EXTERNAL<sub>NET</sub> any -> $HOME<sub>NET</sub> any</td>
</tr>


<tr>
<td class="org-left">Content</td>
<td class="org-left">Common Name (CN) field</td>
<td class="org-left">printableString:XXXX</td>
<td class="org-left">content:"CN=XXXX";</td>
</tr>


<tr>
<td class="org-left">Signature</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">Subject: rdnSequence</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">tls<sub>cert</sub><sub>subject</sub>;</td>
</tr>


<tr>
<td class="org-left">classtype</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">trojan-activity</td>
</tr>
</tbody>
</table>

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">wireshark</th>
<th scope="col" class="org-left">Next level</th>
<th scope="col" class="org-left">marked</th>
<th scope="col" class="org-left">Key</th>
<th scope="col" class="org-left">Rules<sub>format</sub></th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">Certificate</td>
<td class="org-left">signedCertificate</td>
<td class="org-left">Suject:rdnSequence</td>
<td class="org-left">UTF8String =site<sub>name</sub></td>
<td class="org-left">content:"CN=site<sub>name</sub>"</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>

**DNS**

    alert dns $HOME_NET any -> any nay (msg:"OISP TROJAN   "; dns_query; context:"XXX";isdataat:!1,relative;reference:url,site_name;classtype:trojan-activity;)

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">Details & wireshark</th>
<th scope="col" class="org-left">Rules<sub>format</sub></th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">protocol</td>
<td class="org-left">DNS</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">alert DNS</td>
</tr>


<tr>
<td class="org-left">Destination</td>
<td class="org-left">any, any</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">Content</td>
<td class="org-left">normalized domain</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">classtype</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">trojan-activity</td>
</tr>


<tr>
<td class="org-left">reference</td>
<td class="org-left">url</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">queries&#x2013;>site.name</td>
<td class="org-left">url,<site<sub>name</sub>></td>
</tr>


<tr>
<td class="org-left">msg</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">Observed DNS query to Know XXX;dns<sub>query</sub>;</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>

**Maldoc Payload**

    alert http $HOME_NET any -> $EXTERNAL_NET any (msg:"OISF CURRENT_EVENTS Maldoc Retrieving Payload";flow:established,to_server;content"<Key_Word>";fast_pattern;context:"<arguments>";http_user_agent;depth:15;pcre"/$/";http_header_names; content:!"Referer"; sid:2;rev:1;)

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">wireshark</th>
<th scope="col" class="org-left">Next level</th>
<th scope="col" class="org-left">marked</th>
<th scope="col" class="org-left">Key</th>
<th scope="col" class="org-left">Rules<sub>format</sub></th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">Hypertext Transfer Protocol</td>
<td class="org-left">HEAD</td>
<td class="org-left">HEAD</td>
<td class="org-left">HEAD=<payload<sub>Key</sub><sub>Word</sub>></td>
<td class="org-left">context:"Key<sub>Word</sub>";</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">fast<sub>pattern</sub>;</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">User-agent</td>
<td class="org-left"><String></td>
<td class="org-left">context:"<arguments>"</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">HEAD<sub>NAMES</sub></td>
<td class="org-left">payload<sub>charact</sub></td>
<td class="org-left">pcre:"<charact\_(regular expression>"</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>


<a id="orgf0e0ad6"></a>

## TCP

**DDOS**

    alert tcp $HOME_NET any -> $EXTERNAL_NET any (msg"ET TROJAN DDOS Client Information CheckIN"; flow:established; to_server;context"Windows";nocase;depth:7; content:"MHZ | 00 00 00 00 00 00 | ";distance:0; nocase; content:" | 00 00 00 00 00 00 | Win";distance:0; nocase;classtype:trojan-activity; )

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">Wireshard</th>
<th scope="col" class="org-left">Charact<sub>KEY</sub></th>
<th scope="col" class="org-left">protocol</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">Rules<sub>format</sub></th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">&#xa0;</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">DATA</td>
<td class="org-left">System<sub>Name</sub> & MHZ</td>
<td class="org-left">TCP</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">context"Windows";nocase;depth:7; content:"MHZ</td>
<td class="org-left">00 00 00 00 00 00</td>
<td class="org-left">";distance:0; nocase; content:"</td>
<td class="org-left">00 00 00 00 00 00</td>
<td class="org-left">Win";distance:0; nocase;classtype:trojan-activity;</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>


<a id="org6038a35"></a>

## http

**Phish Website**

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">HTTP</th>
<th scope="col" class="org-left">METHOD</th>
<th scope="col" class="org-left">Arguments</th>
<th scope="col" class="org-left">&#xa0;</th>
<th scope="col" class="org-left">Rules<sub>Format</sub></th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">HTTP<sub>HEAD</sub></td>
<td class="org-left">&#xa0;</td>
<td class="org-left">META HTTP-EQUIV</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">content:"200";http<sub>stat</sub><sub>code</sub>; http<sub>content</sub><sub>type</sub>; content:"text/html"; nocase; file<sub>data</sub>;</td>
</tr>


<tr>
<td class="org-left">HTTP<sub>REQUEST</sub></td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>


<tr>
<td class="org-left">INFO</td>
<td class="org-left">POST</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">viewer.php>idp=login</td>
<td class="org-left">content:"POST";  http<sub>method</sub>;</td>
</tr>


<tr>
<td class="org-left">OTHER</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">uri</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">content:".php"; http<sub>uri</sub>; nocase; isdataat:!1,relative;</td>
</tr>


<tr>
<td class="org-left">HTTP<sub>CLIENT</sub><sub>BODY</sub></td>
<td class="org-left">&#xa0;</td>
<td class="org-left">String</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">content:"<String>"; depth:9; nocase; http<sub>client</sub><sub>body</sub>;</td>
</tr>


<tr>
<td class="org-left">HTTP<sub>REFERER</sub></td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">content:"<charact>"; nocase;</td>
</tr>


<tr>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>

