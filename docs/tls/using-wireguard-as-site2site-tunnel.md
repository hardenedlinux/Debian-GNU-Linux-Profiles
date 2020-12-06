### Using wireguard as Site to Site tunnel

##### Environment

OS: Debian 10 buster   
Site A: 192.168.0.0/20   
proxy node from site A: 192.168.10.18    
Site B: 192.168.61.0/24    
proxy node from site B: 192.168.61.39   

##### Install Wireguard

Add Debian buster backports repository
```
sudo sh -c "echo 'deb http://deb.debian.org/debian buster-backports main contrib non-free' > /etc/apt/sources.list.d/buster-backports.list"
```
Install kernel headers for wireguard-dkms
```
sudo apt-get install linux-headers-`uname -r`
```

update apt cahce and install wireguard

```
apt update
apt install -t buster-backports wireguard
```

You should probably reboot to make sure `wireguard` kernel module is loaded.

##### Setting up the Server

generate the private key and publick

```
cd /etc/wireguard/
umask 077; wg genkey | tee privatekey | wg pubkey > publickey
```

enable IP-forwarding for IPv4

edit `/etc/sysctl.conf` add following contents

```
net.ipv4.ip_forward=1
```

apply change

```
/sbin/sysctl -p
```

setting up the configuration
create and edit `/etc/wireguard/wg0.conf`
```
[Interface]
Address = 10.0.99.1/32
SaveConfig = false
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.0.99.0/24 -d 192.168.0.0/20 -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.0.99.0/24 -d 192.168.0.0/20 -o eth0 -j MASQUERADE
ListenPort = 51820
PrivateKey = KJU1ROkyL1UfcC525MVrn3d68TQKNOFqQhHEpqwkCU4=

[Peer]
PublicKey = <client publickey>
AllowedIPs = 192.168.61.0/24,10.0.99.0/24
PersistentKeepalive = 25
```

`wg0`: wireguard interface  
`eth0`: lan interface which connect to site A network `192.168.0.0/20`  
`iptables -A FORWARD -i wg0 -j ACCEPT`: allow forward packets sent by `wg0` wireguard interface, default policy for FORWARD chain should be `DROP`  
`iptables -t nat -A POSTROUTING -s 10.0.99.0/24 -d 192.168.0.0/20 -o eth0 -j MASQUERADE`: translate source ip address of packets with a source ip address of `10.0.99.0/24` and a destination ip address of `192.168.0.0/20` to `eth0` interface's ip address   
`AllowedIPs = 192.168.61.0/24,10.0.99.0/24`: route all traffic with a destination ip address of `192.168.61.0/24` and all traffic with a destination ip address of `10.0.99.0/24` via wireguard `wg0` 10.0.99.1 gateway  
   
route table
```
ip route
default via 192.168.1.1 dev eth0 onlink 
10.0.99.0/24 dev wg0 scope link 
192.168.0.0/20 dev eth0 proto kernel scope link src 192.168.10.18 
192.168.61.0/24 dev wg0 scope link 
```

Enable the service for auto start
```
systemctl enable wg-quick@wg0
```

Start wireguard interface `wg0`
```
systemctl start wg-quick@wg0
```

##### Setting up the Client

generate the private key and publick

```
cd /etc/wireguard/
umask 077; wg genkey | tee privatekey | wg pubkey > publickey
```

enable IP-forwarding for IPv4

edit `/etc/sysctl.conf` add following contents

```
net.ipv4.ip_forward=1
```

apply change

```
/sbin/sysctl -p
```

setting up the configuration
create and edit `/etc/wireguard/wg0.conf`

```
[Interface]
Address = 10.0.99.2/32
SaveConfig = false
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.0.99.0/24 -d 192.168.61.0/20 -o ens18 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.0.99.0/24 -d 192.168.61.0/20 -o ens18 -j MASQUERADE
ListenPort = 51820
PrivateKey = qHMR/KMSJXNQojejRdln3C9vCTCoWBkzWryMRSvbAmA=

[Peer]
PublicKey = <server publickey>
AllowedIPs = 192.168.0.0/20,10.0.99.0/24
Endpoint = <server ip or domain name>:51821
PersistentKeepalive = 25
```

`wg0`: wireguard interface  
`ens18`: lan interface which connect to site A network `192.168.0.0/20`  
`iptables -A FORWARD -i wg0 -j ACCEPT`: allow forward packets sent by `wg0` wireguard interface, default policy for FORWARD chain should be `DROP`  
`iptables -t nat -A POSTROUTING -s 10.0.99.0/24 -d 192.168.61.0/20 -o ens18 -j MASQUERADE`: translate source ip address of packets with a source ip address of `10.0.99.0/24` and a destination ip address of `192.168.61.0/20` to `eth0` interface's ip address   
`AllowedIPs = 192.168.0.0/20,10.0.99.0/24`: route all traffic with a destination ip address of `192.168.0.0/20` and all traffic with a destination ip address of `10.0.99.0/24` via wireguard `wg0` 10.0.99.2 gateway  

route table

```
ip route
default via 192.168.61.1 dev ens18 
10.0.99.0/24 dev wg0 scope link 
192.168.0.0/20 dev wg0 scope link 
192.168.61.0/24 dev ens18 proto kernel scope link src 192.168.61.39
```

Finished
