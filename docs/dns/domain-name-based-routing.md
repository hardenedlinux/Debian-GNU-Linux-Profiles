## Domain based routing on openwrt

#### Keyword: DNS, bind9, dnsmasq, iptables, ipset, route, OpenWRT.

##### Basic configuration

ISP-provided DNS are suspectable, they can be polluted, poisoned, etc, so [deploy your own recursive DNS server is recommended.](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/dns/basic-bind9-cfg-for-lan.md) I have developed [a scheme solely using Bind9](https://persmule.github.io/personal-dns-server), but it is mainly designed for solitary laptops.

For a local area network, the whole system could be deployed more modular. In this scheme, [OpenWRT](https://openwrt.org/) is used on the gateway, while independent recursive DNS server is based on Bind9.

This article is focused on configuration fo the gateway.

##### Gateway configuration.

Assuming lan is `192.168.0.0/24`, the gateway is `192.168.0.1`, and there are two recursive DNS servers `192.168.0.32` and `192.168.0.64`. The gateway has two WAN ports, `wan1`(default route), `wan2`.

`dnsmasq-full` has an ability to link domain names to ipsets, according which iptables could be used to mark packages, which could be routed by rules.


Install necessary packages (especially dnsmasq-full with ipset support).

```
opkg update
opkg install ip ipset kmod-ipt-ipset dnsmasq-full
```

Disable using DNS servers provided by DHCP servers for WANs, and set `lan` to use recursive dns servers inside lan:

/etc/config/network:

```
config interface 'wan1'
	...
	option peerdns '0'
	
config interface 'wan2'
	...
	option peerdns '0'
	
config interface 'lan'
	...
	option dns '192.168.0.32 192.168.0.64'
```

Then `dnsmasq` will forward unconfigured domains to the two servers.

Create a new route table, e.g. `p-wan2`.

/etc/iproute/rt_tables:

```
...
210 p-wan2
(EOF)
```

And create corresponding ipset and routing rule with firewall mark, e.g. `8`.

/etc/rc.local:

```
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

#ipset -N default iphash
ipset -N old iphash

#packages with firewall mark 8 will be routed according to routing table 'old'.
ip rule add fwmark 8 table p-wan2

exit 0
```

To ease openwrt's backup, put the directory inside /etc/config.


/etc/dnsmasq.conf:

```
...

conf-dir=/etc/config/dnsmasq.d
(EOF)
```


`$ ls /etc/config/dnsmasq.d`
```
apdns.conf    default.conf  old.conf
```

For example, ip addresses for domain `baidu.com` and `taobao.com` will be put inside ipset `old`.

/etc/config/dnsmasq.d/old.conf:

```
ipset=/baidu.com/old
ipset=/taobao.com/old
```

Polluted domain could be forwarded to external reliable DNS server (putting them into separate file is recommended.)

```
...
#only for example
server=/box.com/8.8.8.8
```

Then execute the following command (use the corresponding firewall mark above), AFTER ALL WAN ports get brought up (put them in the appropriate script):


```
# iptables -t mangle -A fwmark -m set --match-set old dst -j MARK --set-mark 8
# ip route add default via $(route|grep -e 'UH.*wan2'|awk '{print $1}') dev wan2 table p-wan2
```

The first command sets iptables to mark all packages with its destination in the set `old` with `8`, and the second command link the routing table `old` to the interface `wan2`, sending those packages to the `wan2`'s default gateway.

##### Extension.

IP addresses to anti-pollution DNS servers could be put into an independent ipset using ipset(8), in order to choose a route with less interference.

##### References.

######[1] man pages of dnsmasq(8) ipset(8) iptables(8) ip-route(8)
######[2] https://blog.sorz.org/p/openwrt-outwall/
