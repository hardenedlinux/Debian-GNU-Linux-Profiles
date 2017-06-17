### Using shadowsocks amd bind to forward DNS request

In my country, we have very few option to choice ISP and they provide shitty
DNS Server. Some "Pubilc DNS Server" in my country are shitty too. We can not directly using some useful DNS Server like 8.8.8.8, because
something we both know.

So we can using some low latency VPS from our network to forward DNS request.
Shadowsocks is a usefull tool to bypass something we both know.


#### Setting shadowsocks server in remote server

Follow the offcial [instruction](https://github.com/shadowsocks/shadowsocks-libev) to install shadowsocks-libev

Configure shadowsocks server with udp-relay option enabled

#### Setting shadowsocks client in local udp-relay server

Install shadowsocks-libev in local udp-relay server

Setting forward

Tunneling local 53 port to 8.8.8.8:53


/etc/default/shadowsocks-libev

```
# Defaults for shadowsocks initscript
# sourced by /etc/init.d/shadowsocks-libev
# installed at /etc/default/shadowsocks-libev by the maintainer scripts

#
# This is a POSIX shell fragment
#
# Note: `START', `GROUP' and `MAXFD' options are not recognized by systemd.
# Please change those settings in the corresponding systemd unit file.

# Enable during startup?
START=yes

# Configuration file
CONFFILE="/etc/shadowsocks-libev/config.json"

# Extra command line arguments
DAEMON_ARGS="-L 8.8.8.8:53 -u"

# User and group to run the server as
USER=root
GROUP=root

# Number of maximum file descriptors
MAXFD=32768
```

/etc/shadowsocks-libev/config.json

```

{
    "server":"<server ip>",
    "local_address":"<udp relay server's local ip>",
    "server_port":<server port>,
    "local_port":53,
    "password":"<password>",
    "timeout":60,
    "method":"aes-256-cfb"
}

```

So if we using 192.168.1.253 as DNS Server, we using the 8.8.8.8 via
shadowsocks tunnel

#### Using bind server to make a full function DNS Server

You can find [Basic bind9 configuration for lan](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/dns/basic-bind9-cfg-for-lan.md)

And setting it as recursive DNS

add 192.168.1.253 (tunnel DNS address in local) to /etc/resolv.conf as primary
dns server and add another DNS server address as secondary

/etc/resolv.conf

```
nameserver 192.168.1.253
nameserver 114.114.114.114
```

So in our local network, we can simply using 192.168.1.254 as our DNS server,
it use *REAL* 8.8.8.8 to reslove DNS request, and fallback with
114.114.114.114
