## Deploy Openstack From Stretch

### Keyword: Neutron, Nova, Glance, Cinder

### Platfrom

OS: Debian 9
repo:
```
deb http://mirrors.163.com/ubuntu cosmic main universe
deb-src http://mirrors.163.com/ubuntu cosmic main universe

deb http://mirrors.163.com/ubuntu cosmic-proposed main universe
deb-src http://mirrors.163.com/ubuntu cosmic-proposed main universe
```


#### Environment

##### Host Networking
All physical host must connect via Management network, for administrative purposes. Such as package installation, security updates, DNS and NTP.

Management on 172.16.50.0/24 with gateway  172.16.50.1

Provider network on 192.168.200.0/24 with gateway 192.168.200.1

###### Controller node

Configure the first interface as the management interface:

IP address: 172.16.50.20
Network mask: 255.255.255.0
Default gateway: 172.16.50.1

In my controller node, the management network is connect via enp5s0. For example in your server, can be eth1 or eno1

For Debian:

Edit /etc/network/interfaces file to contain the following:
```
auto enp5s0
iface enp5s0 inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down
```
Reboot the system to activate the changes.

Configure name resolution

1. Set the hostname of the node to controller.

2. Edit the /etc/hosts file to contain the following:

```
# controller
172.16.50.20 controller

# compute1
172.16.50.21 compute1

# compute2
172.16.50.22 compute2
```

Warning:

Some distributions add an extraneous entry in the /etc/hosts file that resolves the actual hostname to another loopback IP address such as 127.0.1.1. You must comment out or remove this entry to prevent name resolution problems. Do not remove the 127.0.0.1 entry.


https://docs.openstack.org/install-guide/environment-networking-controller.html
###### Compute node

Configure the first interface as the management interface:

IP address: 172.16.50.21
Network mask: 255.255.255.0
Default gateway: 172.16.50.1

In my controller node, the management network is connect via enp5s0. For example in your server, can be eth1 or eno1

For Debian:

Edit /etc/network/interfaces file to contain the following:
```
auto enp5s0
iface enp5s0 inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down
```
Reboot the system to activate the changes.

Configure name resolution

1. Set the hostname of the node to controller.

2. Edit the /etc/hosts file to contain the following:

```
# controller
172.16.50.20 controller

# compute1
172.16.50.21 compute1

# compute2
172.16.50.22 compute2
```

Warning:

Some distributions add an extraneous entry in the /etc/hosts file that resolves the actual hostname to another loopback IP address such as 127.0.1.1. You must comment out or remove this entry to prevent name resolution problems. Do not remove the 127.0.0.1 entry.

##### Network Time Protocol

To properly synchronize services among nodes, you can install Chrony, an implementation of NTP. We recommend that you configure the controller node to reference more accurate (lower stratum) servers and other nodes to reference the controller node.

###### Controller node

Install the packages:

```
apt install chrony
```

Edit the chrony.conf file and add, change, or remove the following keys as necessary for your environment.

edit the /etc/chrony/chrony.conf
```
pool cn.ntp.org.cn iburst
```

To enale other nodes to connect the chrony daemon on the controller node, add this key to the same chrony.conf file mentioned above:

```
allow 172.16.50.20/24
```

Restart the NTP service:

```
systemctl enable chronyd.service
systemctl start chronyd.service
```
###### Other nodes

Install the packages:

```
apt install chrony
```
Configure the chrony.conf file and comment out or remove all but one server key. Change it to reference the controller node.

```
server controller iburst
```
Comment out other pools or server line.

Restart the NTP service


```
systemctl enable chronyd.service
systemctl start chronyd.service

```

##### OpenStack packages

Using Ubuntu Packages

edit /etc/apt/source.list, add following sources
```
deb http://mirrors.163.com/ubuntu cosmic main universe
deb-src http://mirrors.163.com/ubuntu cosmic main universe

deb http://mirrors.163.com/ubuntu cosmic-proposed main universe
deb-src http://mirrors.163.com/ubuntu cosmic-proposed main universe
```
update the apt source
```
apt update
```

https://docs.openstack.org/install-guide/environment-packages-ubuntu.html
##### SQL database

Install SQL database for OpenStack Services

Install the packages
```
apt install mariadb-server python-pymysql
```

Create and edit the /etc/mysql/mariadb.conf.d/99-openstack.cnf

```
[mysqld]
bind-address = 172.16.50.20

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
```
and restart the mysql service

```
service mysql restart
```

Securing the database service by running the `mysql_secure_installation` script, and you should choose a suitable password for the database root account.


##### Message queue

OpenStack uses a message queue to coordinate operations and status information among services. The message queue service typically runs on the controller node.

Install the package

```
apt install rabbitmq-server
```

add the `openstack` user:
```
rabbitmqctl add_user openstack RABBIT_PASS
```

Replace RABBIT_PASS with a suitable password.

Setting permission for openstack user:

```
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```

##### Memcached

The Identity service authentication mechanism for services uses Memcached to cache tokens.

1. Install the packages:
```
apt install memcached python-memcache
```

2. Edit the /etc/memcached.conf  file and configure the service to use the management IP address of the controller node. This is to enable access by other nodes via the management network:


change `-l 127.0.0.1` to 

```
-l 172.16.50.20
```

Restart the Memcached service:

```
service memcached restart
```


##### Etcd

OpenStack services may use Etcd, a distributed reliable key-value store for distributed key locking, storing configuration, keeping track of service live-ness and other scenarios.

1. Install the etcd package:
```
apt install etcd
```
2. Edit the /etc/default/etcd file and set the ETCD_INITIAL_CLUSTER, ETCD_INITIAL_ADVERTISE_PEER_URLS, ETCD_ADVERTISE_CLIENT_URLS, ETCD_LISTEN_CLIENT_URLS to the management IP address of the controller node to enable access by other nodes via the management network:

```
ETCD_NAME="controller"
ETCD_DATA_DIR="/var/lib/etcd/"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_LISTEN_PEER_URLS="http://172.16.50.20:2380"
ETCD_LISTEN_CLIENT_URLS="http://172.16.50.20:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.16.50.20:2380"
ETCD_INITIAL_CLUSTER="controller=http://172.16.50.20:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://172.16.50.20:2379"
```
3. Restart the service

```
systemctl enable etcd
systemctl start etcd
```

#### Install Openstack Service

##### Keystone

The OpenStack Identity service provides a single point of integration for managing authentication, authorization, and a catalog of services.

###### Prerequisites

1. Use the database access client to connect to the database server as the root user:

```
mysql -uroot -p
```

2. Create the `keystone` database:

```
MariaDB [(none)]> CREATE DATABASE keystone;
```

3. Grant proper access to the keystone database:

```
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY 'KEYSTONE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY 'KEYSTONE_DBPASS';
```
Replace `KEYSTONE_DBPASS` with a suitable password.

###### Install and configure components

1. Install the packages:

```
apt install keystone  apache2 libapache2-mod-wsgi
```

2. Edit the `/etc/keystone/keystone.conf` file and complete the following actions:

In the [database] section, configure database access:
```
[database]
# ...
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
```
Replace `KEYSTONE_DBPASS` with the password you chose for the database.

In the [token] section, configure the Fernet token provider:

```
[token]
# ...
provider = fernet
```

3. Populate the Identity service database:

```
# su -s /bin/sh -c "keystone-manage db_sync" keystone
```

4. Initialize Fernet key repositories:

```
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
```
5. Bootstrap the Identity service:

```
keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
```
Replace `ADMIN_PASS` with a suitable password for an administrative user.

###### Configure the Apache HTTP server

1. Edit the /etc/apache2/apache2.conf file and configure the ServerName option to reference the controller node:

```
ServerName controller
```
###### Finalize the installation¶

1. Restart the  Apache service:

```
service apache2 restart
```

2. Configure the administrative account

```
$ export OS_USERNAME=admin
$ export OS_PASSWORD=ADMIN_PASS
$ export OS_PROJECT_NAME=admin
$ export OS_USER_DOMAIN_NAME=default
$ export OS_PROJECT_DOMAIN_NAME=default
$ export OS_AUTH_URL=http://controller:5000/v3
$ export OS_IDENTITY_API_VERSION=3
```

Replace `ADMIN_PASS` with the password used in the keystone-manage bootstrap command before

we can save this  admin credentials to "admin-openrc" file.

##### Glance

###### Prerequisites

1. Create glance database

```
mysql -uroot -p
```

Create the `glance` database:

```
MariaDB [(none)]> CREATE DATABASE glance;
```

Grant proper access to the glance database:

```
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY 'GLANCE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY 'GLANCE_DBPASS';
```

Replace GLANCE_DBPASS with a suitable password.

2. Source the admin credentials to gain access to admin-only CLI commands:

```
. admin-openrc
```

3. To create the service credentials, complete these steps:

Create the glance user:
```
openstack user create --domain default --password-prompt glance

User Password:
Repeat User Password:
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | 3f4e777c4062483ab8d9edd7dff829df |
| name                | glance                           |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
```
Add the admin role to the glance user and service project:

```
openstack role add --project service --user glance admin
```

Create the glance service entity:

```
$ openstack service create --name glance \
  --description "OpenStack Image" image

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Image                  |
| enabled     | True                             |
| id          | 8c2c7f1b9b5049ea9e63757b5533e6d2 |
| name        | glance                           |
| type        | image                            |
+-------------+----------------------------------+
```

4. Create the Image service API endpoints:
```
openstack endpoint create --region RegionOne \
  image public http://controller:9292
```
```
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
```
```
openstack endpoint create --region RegionOne \
  image admin http://controller:9292
```

###### Install and configure components¶

1. Install the packages:

```
apt install glance
```

2. Edit the /etc/glance/glance-api.conf file and complete the following actions:

```
[database]
# ...
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
```
Replace GLANCE_DBPASS with the password you chose for the Image service database.

In the [keystone_authtoken] and [paste_deploy] sections, configure Identity service access:
```
[keystone_authtoken]
# ...
auth_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
# ...
flavor = keystone
```
Replace GLANCE_PASS with the password you chose for the glance user in the Identity service.

In the [glance_store] section, configure the local file system store and location of image files:
```
[glance_store]
# ...
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
```

3. Edit the /etc/glance/glance-registry.conf file and complete the following actions:

In the [database] section, configure database access:

```
[database]
# ...
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
```
Replace GLANCE_DBPASS with the password you chose for the Image service database.

In the [keystone_authtoken] and [paste_deploy] sections, configure Identity service access:

```
[keystone_authtoken]
# ...
auth_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
# ...
flavor = keystone
```
Replace GLANCE_PASS with the password you chose for the glance user in the Identity service.

4. Populate the Image service database:

```
# su -s /bin/sh -c "glance-manage db_sync" glance
```
###### Finalize installation¶

```
service glance-registry restart
service glance-api restart
```

##### Nova Controller Node

###### Prerequisites

1. create the databases

a. Use the database access client to connect to the database server as the root user:

```
mysql -uroot -p
```
b. Create the nova_api, nova, nova_cell0, and placement databases:
```
MariaDB [(none)]> CREATE DATABASE nova_api;
MariaDB [(none)]> CREATE DATABASE nova;
MariaDB [(none)]> CREATE DATABASE nova_cell0;
MariaDB [(none)]> CREATE DATABASE placement;
```
c. Grant proper access to the databases:

```
Grant proper access to the databases:

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';

MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';
```
Replace NOVA_DBPASS with a suitable password.

2. Source the admin credentials to gain access to admin-only CLI commands:

```
. admin-openrc
```

3. Create the Compute service credentials:

a. Create the nova user:
```
openstack user create --domain default --password-prompt nova
```
b. Add the admin role to the nova user:

```
openstack role add --project service --user nova admin
```

c. Create the nova service entity:

```
openstack service create --name nova \
  --description "OpenStack Compute" compute
```

4. Create the Compute API service endpoints:

```
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1
```

5. Create a Placement service user using your chosen PLACEMENT_PASS:

```
openstack user create --domain default --password-prompt placement
```

6. Add the Placement user to the service project with the admin role:

```
openstack role add --project service --user placement admin
```

7. Create the Placement API entry in the service catalog:
```
openstack service create --name placement \
  --description "Placement API" placement
```

8. Create the Placement API service endpoints:

```
openstack endpoint create --region RegionOne \
  placement public http://controller:8778
openstack endpoint create --region RegionOne \
  placement internal http://controller:8778
openstack endpoint create --region RegionOne \
  placement admin http://controller:8778
```

###### Install and configure components¶

1. Install the packages:

```
apt install nova-api nova-conductor nova-novncproxy nova-scheduler \
  nova-placement-api
```

2. Edit the /etc/nova/nova.conf file and complete the following actions:

a. In the [api_database], [database], and [placement_database] sections, configure database access:
```
[api_database]
# ...
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api

[database]
# ...
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova

[placement_database]
# ...
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement
```
Replace NOVA_DBPASS with the password you chose for the Compute databases and PLACEMENT_DBPASS for Placement database.

b. In the [DEFAULT] section, configure RabbitMQ message queue access:

```
[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller
```
Replace RABBIT_PASS with the password you chose for the openstack account in RabbitMQ.

c. In the [api] and [keystone_authtoken] sections, configure Identity service access:

```
[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = NOVA_PASS
```
Replace NOVA_PASS with the password you chose for the nova user in the Identity service.

d. In the [DEFAULT] section, configure the my_ip option to use the management interface IP address of the controller node:

```
[DEFAULT]
# ...
my_ip = 172.16.50.20
```

e. In the [DEFAULT] section, enable support for the Networking service:

```
[DEFAULT]
# ...
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver
```

f. Configure the [neutron] section of /etc/nova/nova.conf. Refer to the Networking service install guide for more information.

g. In the [vnc] section, configure the VNC proxy to use the management interface IP address of the controller node:

```
[vnc]
enabled = true
# ...
server_listen = $my_ip
server_proxyclient_address = $my_ip
```
you probably would change your vnc listen ip to a more public address to your user not only to your admin.

h. In the [glance] section, configure the location of the Image service API:
```
[glance]
# ...
api_servers = http://controller:9292
```

i. In the [oslo_concurrency] section, configure the lock path:

```
[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp
```

j. Due to a packaging bug, remove the log_dir option from the [DEFAULT] section.


k. In the [placement] section, configure the Placement API:

```
[placement]
# ...
region_name = RegionOne
project_domain_name = default
project_name = service
auth_type = password
user_domain_name = default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS
```
Replace PLACEMENT_PASS with the password you choose for the placement user in the Identity service. Comment out any other options in the [placement] section.

3. Populate the nova-api and placement databases:


```
su -s /bin/sh -c "nova-manage api_db sync" nova
```

4. Register the cell0 database:

```
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
```

5. Create the cell1 cell:

```
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
```

6. Populate the nova database:

```
su -s /bin/sh -c "nova-manage db sync" nova
```

7. Verify nova cell0 and cell1 are registered correctly:

```
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
```
###### Finalize installation¶

Restart the Compute services:

```
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
```

##### Nova Compute Node


###### Install and configure components¶

1. Install the packages:


```
apt install nova-compute
```

2. Edit the /etc/nova/nova.conf file and complete the following actions:

a. In the [DEFAULT] section, configure RabbitMQ message queue access:

```
[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller
```
Replace RABBIT_PASS with the password you chose for the openstack account in RabbitMQ.


b. In the [api] and [keystone_authtoken] sections, configure Identity service access:

```
[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = NOVA_PASS
```
Replace NOVA_PASS with the password you chose for the nova user in the Identity service.

c. In the [DEFAULT] section, configure the my_ip option:

```
[DEFAULT]
# ...
my_ip = MANAGEMENT_INTERFACE_IP_ADDRESS
```
Replace MANAGEMENT_INTERFACE_IP_ADDRESS with the IP address of the management network interface on your compute node.

d. In the [DEFAULT] section, enable support for the Networking service:

```
[DEFAULT]
# ...
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver
```

e. Configure the [neutron] section of /etc/nova/nova.conf. Refer to the Networking service install guide for more details.

f. In the [vnc] section, enable and configure remote console access:

```
[vnc]
# ...
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html
```

The server component listens on all IP addresses and the proxy component only listens on the management interface IP address of the compute node. The base URL indicates the location where you can use a web browser to access remote consoles of instances on this compute node.

g. In the [glance] section, configure the location of the Image service API:

```
[glance]
# ...
api_servers = http://controller:9292
```
h. In the [oslo_concurrency] section, configure the lock path:
```
[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp
```

###### Finalize installation¶

1. Determine whether your compute node supports hardware acceleration for virtual machines:

```
egrep -c '(vmx|svm)' /proc/cpuinfo
```
If this command returns a value of one or greater, your compute node supports hardware acceleration which typically requires no additional configuration.

If this command returns a value of zero, your compute node does not support hardware acceleration and you must configure libvirt to use QEMU instead of KVM.

a. Edit the [libvirt] section in the /etc/nova/nova-compute.conf file as follows:

```
[libvirt]
# ...
virt_type = qemu
```
2. Restart the Compute service:


```
service nova-compute restart
```

###### Add the compute node to the cell database¶

1. Source the admin credentials to enable admin-only CLI commands, then confirm there are compute hosts in the database:

```
. admin-openrc
openstack compute service list --service nova-compute
```

2. Discover compute hosts:

```
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
```

`Note`

When you add new compute nodes, you must run nova-manage cell_v2 discover_hosts on the controller node to register those new compute nodes. Alternatively, you can set an appropriate interval in /etc/nova/nova.conf:

```
[scheduler]
discover_hosts_in_cells_interval = 300
```

##### Neutron

###### Prerequisites

1. Create the neutron database:

a. Use the database access client to connect to the database server as the root user:

```
mysql 
```
b. Create the neutron database:

```
MariaDB [(none)] CREATE DATABASE neutron;
```
c. Grant proper access to the neutron database, replacing NEUTRON_DBPASS with a suitable password:

```
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
```

2. Source the admin credentials to gain access to admin-only CLI commands:

```
. admin-openrc
```

3. To create the service credentials, complete these steps:

a. Create the neutron user:

```
openstack user create --domain default --password-prompt neutron
```

b. Add the admin role to the neutron user:

```
openstack role add --project service --user neutron admin
```

c. Create the neutron service entity:

```
openstack service create --name neutron \
  --description "OpenStack Networking" network
```

4. Create the Networking service API endpoints:

```
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696
```

###### Networking Option

We choose the 'Networking Option 2: Self-service netwroks' as example.

###### Install the components

```
apt install neutron-server neutron-plugin-ml2 \
  neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent openvswitch-switch openvswitch-common
```

###### Configure the server component

1. Edit the /etc/neutron/neutron.conf file and complete the following actions:

a. In the [database] section, configure database access:

```
[database]
# ...
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
```
Replace NEUTRON_DBPASS with the password you chose for the database.

b. In the [DEFAULT] section, enable the Modular Layer 2 (ML2) plug-in, router service, and overlapping IP addresses:

```
[DEFAULT]
# ...
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = true
```

c. In the [DEFAULT] section, configure RabbitMQ message queue access:

```
[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller
```
Replace RABBIT_PASS with the password you chose for the openstack account in RabbitMQ.

d. In the [DEFAULT] and [keystone_authtoken] sections, configure Identity service access:
```
[DEFAULT]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS
```
Replace NEUTRON_PASS with the password you chose for the neutron user in the Identity service.

`Note`
Comment out or remove any other options in the [keystone_authtoken] section.


e. In the [DEFAULT] and [nova] sections, configure Networking to notify Compute of network topology changes

```
[DEFAULT]
# ...
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[nova]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_PASS
```
Replace NOVA_PASS with the password you chose for the nova user in the Identity service.


###### Configure the Modular Layer 2 (ML2) plug-in

The ML2 plug-in uses the Linux bridge mechanism to build layer-2 (bridging and switching) virtual networking infrastructure for instances.

1. Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:
a. In the [ml2] section, enable flat, VLAN, and VXLAN networks:
```
[ml2]
# ...
type_drivers = flat,vlan,vxlan
```
b. In the [ml2] section, enable VXLAN self-service networks:

```
[ml2]
# ...
tenant_network_types = vxlan
```

c. In the [ml2] section, enable the OpenvSwitch and layer-2 population mechanisms:

```
mechanism_drivers = openvswitch,l2population
```

d. Configure the VXLAN network ID (VNI) range.

```
[ml2_type_vxlan]
vni_ranges = VNI_START:VNI_END
```
Replace VNI_START and VNI_END with appropriate numerical values.

For example, `vni_ranges = 1:1000`


###### Configure OVS

Create the OVS provider bridge `br-provider`
```
ovs-vsctl add-br br-provider
```
Add the physical port to br-provider

```
ovs-vsctl add-port br-provider eno2
```

Enable both br-provider and eno2

edit the `/etc/neutron/plugins/ml2/openvswitch_agent.ini` file, configure the layer-2 agent.

```
[ovs]
bridge_mappings = provider:br-provider
#local_ip = OVERLAY_INTERFACE_IP_ADDRESS
local_ip = 172.16.50.20

[agent]
tunnel_types = vxlan
l2_population = True

[securitygroup]
firewall_driver = iptables_hybrid
```
Replace OVERLAY_INTERFACE_IP_ADDRESS with the IP address of the interface that handles VXLAN overlays for self-service networks.
This should be a real ip in your interface, and can connect to each node.

edit ` /etc/neutron/l3_agent.ini` file, configure the layer-3 agent.

```
[DEFAULT]
ovs_integration_bridge = br-int
interface_driver = openvswitch
external_network_bridge =
```
The external_network_bridge option intentionally contains no value.

Restart the Open vSwitch agent & Layer-3 agent

###### Compute nodes

Create the OVS provider bridge `br-provider`
```
ovs-vsctl add-br br-provider
```
Add the physical port to br-provider

```
ovs-vsctl add-port br-provider eno2
```
Enable both br-provider and eno2

In the openvswitch_agent.ini file, enable VXLAN support including layer-2 population.

```
[ovs]
bridge_mappings = provider:br-provider
local_ip = OVERLAY_INTERFACE_IP_ADDRESS
local_ip = 172.16.50.21

[agent]
tunnel_types = vxlan
l2_population = True
```
Replace OVERLAY_INTERFACE_IP_ADDRESS with the IP address of the interface that handles VXLAN overlays for self-service networks.

Restart Open vSwitch agent


#### Use Case (Launch an instance)

##### Create virtual networks (flat)

Create the network:

```
openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat public01
```

Create a subnet on the network:
```
openstack subnet create --network public01   --allocation-pool start=192.168.200.200,end=192.168.200.220   --dns-nameserver 8.8.8.8 --gateway 192.168.200.1   --subnet-range 192.168.200.0/24 public01
```

Verify the netwrok
```
$ openstack network list
+--------------------------------------+----------+--------------------------------------+
| ID                                   | Name     | Subnets                              |
+--------------------------------------+----------+--------------------------------------+
| 664e6a30-2b12-4eec-a9da-45210e4cb5e6 | public01 | 948a058c-de2f-4fac-988f-aa09cbb52232 |
+--------------------------------------+----------+--------------------------------------+

```
##### Create flavor


```
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
```

```
$ openstack flavor list

+----+---------+-----+------+-----------+-------+-----------+
| ID | Name    | RAM | Disk | Ephemeral | VCPUs | Is Public |
+----+---------+-----+------+-----------+-------+-----------+
| 0  | m1.nano |  64 |    1 |         0 |     1 | True      |
+----+---------+-----+------+-----------+-------+-----------+
```

##### Create Image

We using cirros for test purpose

Download the image
```
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
```

Upload the image to Glance(image service)
```
openstack image create "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public
```

Verify

```
$ openstack image list

+--------------------------------------+--------+--------+
| ID                                   | Name   | Status |
+--------------------------------------+--------+--------+
| 38047887-61a7-41ea-9b49-27987d5e8bb9 | cirros | active |
+--------------------------------------+--------+--------+
```

###### Launch a instance

Replace PROVIDER_NET_ID with the ID of the `public01` provider network.
```
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=PROVIDER_NET_ID --security-group default \
  --key-name mykey provider-instance
```

Check the status of your instance:

```
$ openstack server list

+--------------------------------------+-------------------+--------+-------------------------+------------+
| ID                                   | Name              | Status | Networks                | Image Name |
+--------------------------------------+-------------------+--------+-------------------------+------------+
| 181c52ba-aebc-4c32-a97d-2e8e82e4eaaf | provider-instance | ACTIVE | provider=192.168.200.217| cirros     |
+--------------------------------------+-------------------+--------+-------------------------+------------+
```

Access the instance using the virtual console
```
openstack console url show provider-instance
+-------+---------------------------------------------------------------------------------+
| Field | Value                                                                           |
+-------+---------------------------------------------------------------------------------+
| type  | novnc                                                                           |
| url   | http://controller:6080/vnc_auto.html?token=5eeccb47-525c-4918-ac2a-3ad1e9f1f493 |
+-------+---------------------------------------------------------------------------------+
```
Or we could just using `SSH`

```
ssh cirros@192.168.200.217
```


We can login and check the connectivity between gateway and internet using `ping`




Reference:

https://opensource.com/article/17/4/openstack-neutron-networks   
https://docs.openstack.org/install-guide/launch-instance-networks-provider.html   
