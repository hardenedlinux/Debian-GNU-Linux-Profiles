## Deploy Bro as an IDS

#### Keyword: IDS, Bro, file capabilities.

##### Build Bro

Install dependencies.

Debian 9 have introduced Bro, so `# apt-get build-dep` could be invoked:

```
# apt-get build-dep bro
# apt-get install swig swig3.0 python-dev python3-dev git
```
or install all the build dependencies (which could be extracted from the output of `$ apt-cache showsrc bro`) by hand:
```
# apt-get install debhelper cmake binpac btest bison flex \
rsync libbind-dev libcurl-dev, libreadline-dev libgeoip-dev \
libgoogle-perftools-dev libpcap-dev libsqlite3-dev libssl1.0-dev \
libxml2-dev zlib1g-dev swig swig3.0 python-dev python3-dev git
```
Currently the latest stable version of `Broker` depends on EXACT `actor-framework` version 0.15, which can hardly be built, so a Bro without Broker is going to be built:

```
$ git clone --recursive git://git.bro.org/bro
$ cd bro
$ git checkout origin/release/2.5
$ ./configure --disable-broker --prefix=/usr/local
$ make -j$(nproc)
# make install
```

##### Essential Configuration

```
# mkdir -p /var/log/bro
# mkdir -p /var/spool/bro
```

Modify the following options inside `/usr/local/etc/broctl.cfg` like below:

```
...
MailTo = you@example.com
...
LogDir = /var/log/bro
...
SpoolDir = /var/spool/bro
...
CfgDir = /usr/local/etc
```

Edit the `/usr/local/etc/networks.cfg` file and add each network (using standard CIDR notation) that is considered local to the monitored environment, e.g., when bro is deployed on the server to monitor itself, which has the address `221.221.221.221/18`, the `networks.cfg` should contain the following content:

```
221.221.192.0/18    monitored network
```

With all config files adjusted, run the following command to update broctl installation/configuration:

```
# broctl install
```

Now bro is functional. You can invoke
```
# broctl start
```
to start it, and
```
# broctl stop
```
to shut it down. Log files will be written into `/var/log/bro`, and raw monitor results will be saved into `/var/spool/bro`.

##### Bro policies

The local customizable bro script is located at `/usr/local/share/bro/site/local.bro`, which has already contained several predefined `@load` instructions, so you could load modules you want, e.g. add 
```
@load policy/misc/scan
```
to load  `/usr/local/share/bro/policy/misc/scan.bro` module. You can also write your own modules via bro script language and load them.

##### Daemonize Bro

```
# adduser --system --home /var/spool/bro --disabled-login bro
# chown -R bro:adm /var/spool/bro
# chown -R bro:adm /var/log/bro
# chown bro /usr/local/bin/bro
# setcap cap_net_raw,cap_net_admin=eip /usr/local/bin/bro
```
then write `/etc/systemd/system/bro.service`:

```
[Unit]
Description=Bro IDS
After=network.target

[Service]
User=bro
Type=forking
Environment=HOME=/var/spool/bro 
ExecStart=/usr/local/bin/broctl start
ExecReload=/usr/local/bin/broctl restart
ExecStop=/usr/local/bin/broctl stop

[Install]
WantedBy=multi-user.target
```

After this service file installed
```
# systemctl enable bro.service
```

the bro system is configured as a daemon.

###### Further Readings.
######[1] [BrashEndeavours/bro-elk-IDS#install-bro-25](https://github.com/BrashEndeavours/bro-elk-IDS#install-bro-25)
######[2] [Build Bro nightly & bro-plugins on CentOS 7.x](https://gist.github.com/dcode/1a4a5c93371dfccde596#file-build_bro_nightly-sh)
######[3] [Bro FAQ](https://www.bro.org/documentation/faq.html#how-can-i-capture-packets-as-an-unprivileged-user)
######[4] [Web Application Attack Analysis Using Bro IDS](https://www.sans.org/reading-room/whitepapers/detection/web-application-attack-analysis-bro-ids-34042)
######[5] [A Bro Walk-Through](http://www.icir.org/robin/rwth/bro-tour.pdf)
