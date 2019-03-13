## Deploy Hyperledger Cello on Debian 9

### Keyworld: Debian, Hyperledger, Cello, Blockchain

### Platform

OS: Debian 9

### Prerequisites

```
apt install git make sudo dirmngr  -y
```

Install Docker

```
apt install apt-transport-https ca-certificates curl software-properties-common gnupg2 -y
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y 
```

Install Docker compose (Because the Cello using the docker compose v3 syntax, We should using at least version 1.10)

```
sudo sh -c 'printf "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list'
apt update
apt install -t stretch-backports docker-compose -y
```

```
git clone  https://github.com/hyperledger/cello.git
cd cello
git checkout cd035bd4cbbdd97d78fcb37f26a134706402ebdd
```
We checkout this commmit because we test all function in this version of source code

### Deployment

#### Deploy Master Node


```
SERVER_PUBLIC_IP=x.x.x.x make setup-master
```

If you encouter timeout error on keyclock service like below

```
(Controller Boot Thread) WFLYCTL0348: Timeout after [300] seconds waiting for service container stability. Operation will roll back. Step that first updated the service container was 'add' at address '[
cello-initial-keycloak-server |     ("core-service" => "management"),
cello-initial-keycloak-server |     ("management-interface" => "http-interface")
cello-initial-keycloak-server | ]'
cello-initial-keycloak-server | 09:39:03,963 ERROR [org.jboss.as.controller.management-operation]
```

You can login the keycloack service container and  edit `/opt/jboss/keycloak/bin/standalone.conf`


```
#
# Specify options to pass to the Java VM. 
#
if [ "x$JAVA_OPTS" = "x" ]; then
   JAVA_OPTS="-Xms64m -Xmx512m -XX:MaxMetaspaceSize=256m -Djava.net.preferIPv4Stack=true"
   JAVA_OPTS="$JAVA_OPTS -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true"
else
   echo "JAVA_OPTS already set in environment; overriding default settings with values: $JAVA_OPTS"
fi
### adding following line
JAVA_OPTS="$JAVA_OPTS -Djboss.as.management.blocking.timeout=600"
```

You can check `https://access.redhat.com/solutions/1190323` for more details



After finish the master node deployment, we can start  the service with

```
SERVER_PUBLIC_IP=x.x.x.x  make start
```

#### Deploy worker node

We setting the worker on second server.

We using docker for our worker node deployment, first we have to install the docker


Install Docker

```
apt install apt-transport-https ca-certificates curl software-properties-common gnupg2 git make sudo dirmngr -y
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y 
```

##### Confirguration 

edit `/etc/default/docker`

```
DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --api-cors-header='*' --default-ulimit=nofile=8192:16384 --default-ulimit=nproc=8192:16384"
```

edit `/lib/systemd/system/docker.service`

change 
```
ExecStart=/usr/bin/dockerd -H fd:// 
```

to

```
EnvironmentFile=-/etc/default/docker
ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_OPTS

```

```
systemctl daemon-reload
systemctl restart docker
```

edit `/etc/sysctl.conf`

```
net.ipv4.ip_forward=1
```


On some old version of Cello, the official doc will told you to init your worker node with following command. 

```
MASTER_NODE=x.x.x.x make setup-worker
```

But In newer version, they empty the value of `MASTER_NODE` before the initiation process in
`cello/scripts/worker_node/setup_worker_node_docker.sh` on line 28

So you should set this value manually. otherwise, the worker node don't know they have to connect the master node's NFS service.

After setting the `MASTER_NODE` in the script, now you can deploy the worker node.

```
make setup-worker
```

After finish the initiation, you can add the host on the `http://MASTER_IP:8080/` and create the new chain.
