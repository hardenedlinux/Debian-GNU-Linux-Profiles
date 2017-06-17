## Basic bind9 configuration for lan.

#### Keyword: DNS, bind9, private domain name, lan, recursive.

##### ISP-provided DNS are suspectable

Many do not hesitate in using DNS servers provided by the ISP (e.g. introduced via DHCP), but they can be poisoned by the ISP itself, polluted by higher recursive DNS, etc. I suggest, if only recursively DNS querying is not blocked by the ISP you are using, you should set up your own recursive DNS server for your lan.

##### BIND version 9

Debian GNU/Linux's `bind9` is already a recursive DNS server with [DNSSEC](https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) support with its default configuration, and you can additionally use it to provide private host names.

```
# apt-get install bind9 
```
	
##### (optional) generate dnssec key for your own domain.

You can generate a new key with the following options:

* algorithm HMAC-MD5 - identifies 157 (required for a TSIG signature and only algorithm supported by BIND)
* length of 512 octets (multiple of 64 with a maximum length of 512 for the above algorithm)
* name : ns-example-com_rndc-key 

```
# cd /etc/bind/
# dnssec-keygen -a HMAC-MD5 -b 512 -n USER ns-example-lan_rndc-key
```

The footprint associated with the key is 53334. We get two files, one with an extension key and the other with a private extension. Write the key to file ns-example-com_rndc-key with the following format:

```
# cat Kns-example-lan_rndc-key.+157+53334.private
Private-key-format: v1.2
Algorithm: 157 (HMAC_MD5)
Key: LZ5m+L/HAmtc9rs9OU2RGstsg+Ud0TMXOT+C4rK7+YNUo3vNxKx/197o2Z80t6gA34AEaAf3F+hEodV4K+SWvA==
Bits: AAA=

# cat ns-example-lan_rndc-key
key "ns-example-lan_rndc-key" {
        algorithm hmac-md5;
        secret "LZ5m+L/HAmtc9rs9OU2RGstsg+Ud0TMXOT+C4rK7+YNUo3vNxKx/197o2Z80t6gA34AEaAf3F+hEodV4K+SWvA==";
};
```

The file ns-example-lan_rndc-key should NOT be made world readable for security reasons. This should be inserted into the bind configuration by an include because the bind configuration itself is world-readable. Also, it's a good idea to delete the key and private files generated before. 

```
# chmod 600 ns-example-lan_rndc-key
# rm Kns-example-lan_rndc-key.+157+53334.*
```

##### Config your own domain.

In Debian, the main configuration file of BIND is usually separated into several files with different roles.


`/etc/bind/named.conf`:

```
// This is the primary configuration file for the BIND DNS server named.
//
// Please read /usr/share/doc/bind9/README.Debian.gz for information on the 
// structure of BIND configuration files in Debian, *BEFORE* you customize 
// this configuration file.
//
// If you are just adding zones, please do that in /etc/bind/named.conf.local

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
```

The basic configuration of your own DNS zone should be put to `/etc/bind/named.conf.local`


`/etc/bind/named.conf.local`:

```
//
// Do any local configuration here
//

// Manage the file logs
include "/etc/bind/named.conf.log";

// Domain Management example.lan
// ------------------------------
//  - The server is defined as the master on the domain.
//  - There are no forwarders for this domain.
//  - Entries in the domain can be added dynamically 
//    with the key ns-example-lan_rndc-key

include "/etc/bind/ns-example-lan_rndc-key";

zone "example.lan" {
        type master;
        file "/var/lib/bind/db.example.lan";
        //forwarders {};
        // If we do not comment the ''forwarders'' "empty" clients of the local subnet in my case don't have access to the upstream DNS ?
        //allow-update { key ns-example-lan_rndc-key; };
        allow-update { key rndc-key; };
        //confusion between the file name to import (ns-example-lan_rndc-key) and the key label (rndc-key) ?
};
zone "0.168.192.in-addr.arpa" {
        type master;
        file "/var/lib/bind/db.example.lan.inv";
        //forwarders {};
        //allow-update { key ns-example-lan_rndc-key; };
        allow-update { key rndc-key; };
};

// Consider adding the 1918 zones here, if they are not used in your
// organization
include "/etc/bind/zones.rfc1918";
```

Create the future log file with correct permission:

```
# cd /var/log
# touch bind.log security_info.log update_debug.log
# chown root:bind bind.log security_info.log update_debug.log
# chmod 664 bind.log security_info.log update_debug.log
```

(The permission may be 660.)

Config dedicated log of BIND:

```
# cat /etc/bind/named.conf.log 
logging {
        channel update_debug {
                file "/var/log/update_debug.log" versions 3 size 100k;
                severity debug;
                print-severity  yes;
                print-time      yes;
        };
        channel security_info {
                file "/var/log/security_info.log" versions 1 size 100k;
                severity info;
                print-severity  yes;
                print-time      yes;
        };
        channel bind_log {
                file "/var/log/bind.log" versions 3 size 1m;
                severity info;
                print-category  yes;
                print-severity  yes;
                print-time      yes;
        };

        category default { bind_log; };
        category lame-servers { null; };
        category update { update_debug; };
        category update-security { update_debug; };
        category security { security_info; };
};
```

Concrete zone info are stored inside `/var/lib/bind`

`/var/lib/bind/db.example.lan`:

```
$TTL    3600
@       IN      SOA     ns.example.lan. root.example.lan. (
                   2016112301           ; Serial
                         3600           ; Refresh [1h]
                          600           ; Retry   [10m]
                        86400           ; Expire  [1d]
                          600 )         ; Negative Cache TTL [1h]
;
@       IN      NS      ns.example.lan.
@       IN      MX      10 ns.example.lan.

ns     IN      A       192.168.0.16
host    IN      A       192.168.0.32
mc	IN	A	192.168.0.64
```

The explanation of above sections can be seen [here](https://wiki.debian.org/Bind9#Some_Explanations_:).

`/var/lib/bind/db.example.lan.inv`:

```
@ IN SOA        ns.example.lan. root.example.lan. (
                   2007010401           ; Serial
                         3600           ; Refresh [1h]
                          600           ; Retry   [10m]
                        86400           ; Expire  [1d]
                          600 )         ; Negative Cache TTL [1h]
;
@       IN      NS      ns.example.lan.

16       IN      PTR     ns.example.lan.
```

##### Config resolver of the DNS server itself.

```
# echo 'search example.com' >> /etc/resolv.conf 
```

##### Result.

Now you get a DNS server responsible to resolve your private domain `example.lan`, as well as other domains recursively, with DNSSEC.

##### Comments.

This document is excerpted from [a debian article](https://wiki.debian.org/Bind9) with some modifications.
