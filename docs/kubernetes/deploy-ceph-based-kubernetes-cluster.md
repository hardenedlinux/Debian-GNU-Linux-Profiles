# Deploy ceph Based Kubernetes Cluster

## Pre-requirement

### Install libvirt

apt install qemu-block-extra libvirt-daemon-system openvswitch-switch libvirt-daemon-driver-storage-rbd qemu qemu-kvm

### Configurate Host Bridge Interface

```
ovs-vsctl add-br br0
ovs-vsctl add-port br0 eno2
```

vim `/etc/network/interfaces` add following contents

```
auto eno2
allow-br0 eno2
iface eno2 inet manual
  ovs_bridge br0
  ovs_type OVSPort
```

### Configurate Ceph RBD Pool

#### On Ceph Controller Node

```
ceph osd pool create libvirt 128 128
ceph auth get-or-create client.libvirt mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=libvirt'
ceph auth get-key client.libvirt | tee client.libvirt.key
ceph osd pool application enable libvirt rbd
rbd pool init libvirt
```

#### On Libvirt Node ( Virtual Machine Host)

Create secret profile

```
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
        <usage type='ceph'>
                <name>client.libvirt secret</name>
        </usage>
</secret>
EOF
```
Define secret
```
virsh secret-define --file secret.xml 
Secret 1cbf0392-32d6-4cb5-9e30-1f81fd3e9716 created
```

After the definition, will return the secret `uuid`, then we can set the value.

```
virsh secret-set-value --secret 1cbf0392-32d6-4cb5-9e30-1f81fd3e9716 --base64 $(cat client.libvirt.key) && rm client.libvirt.key secret.xml
```

Create libvirt storage pool profile

```
cat > ceph-libvirt-pool.xml <<EOF
<pool type="rbd">
  <name>ceph-libvirt-pool</name>
  <source>
    <name>libvirt</name>
    <host name='172.16.50.20' port='6789'/>
    <host name='172.16.50.21' port='6789'/>
    <host name='172.16.50.22' port='6789'/>
    <auth username='libvirt' type='ceph'>
      <secret uuid='1cbf0392-32d6-4cb5-9e30-1f81fd3e9716'/>
    </auth>
  </source>
</pool>
EOF
```

Define the `ceph-libvirt-pool`

```
virsh pool-define  ceph-libvirt-pool.xml 
Pool ceph-libvirt-pool defined from ceph-libvirt-pool.xml
```

Check the libvirt storage pool

```
virsh pool-list --all
```

Start the pool

```
virsh pool-start ceph-libvirt-pool
Pool ceph-libvirt-pool started
```

Turn on autostart

```
virsh pool-autostart ceph-libvirt-pool
```

#### Install VM on libvrit node

We install one k8s controller node and one k8s worker node each Host

```
Node0: 

    Ceph Monitor
    Ceph OSD Node

    KVM :
        K8S Controller (16GB RAM, 2 CPUS, 200GB CEPH RBD based disk, 1 NIC)
        K8S Controller Load Balancer (16GB RAM, 2 CPUS, 200GB CEPH RBD based disk, 1 NIC)
        K8S Worker

Node1:

    Ceph Monitor
    Ceph OSD Node

    KVM :
        K8S Controller (16GB RAM, 2 CPUS, 200GB CEPH RBD based disk, 1 NIC)
        K8S Worker

Node2:

    Ceph Monitor
    Ceph OSD Node

    KVM :
        K8S Controller (16GB RAM, 2 CPUS, 200GB CEPH RBD based disk, 1 NIC)
        K8S Worker
```

## Kubernetes

### Information

```
Kubernetes Subnet — 192.168.200.0/24 # Host Network
POD_CIDR — 10.100.0.0/16
SERVICE_CIDR — 10.32.0.0/16

k8s-controllers-lb 192.168.200.190
k8s-controllers-0 192.168.200.180
k8s-controllers-1 192.168.200.181
k8s-controllers-2 192.168.200.182
k8s-worker-0: 192.168.200.185
k8s-worker-1: 192.168.200.186
k8s-worker-2: 192.168.200.187
```

you should edit the `/etc/hosts` on all your controller node and worker node

```
192.168.200.180	controllers-0
192.168.200.181	controllers-1
192.168.200.182	controllers-2 
192.168.200.185	worker-0
192.168.200.186	worker-1
192.168.200.187	worker-2
```
and install package for all node

```
apt install conntrack socat -y
```

### Setting up cfssl & generating configs

We using CloudFlare's PKI toolkit generation of the certificate authority and for generating the TLS certs that the cluster services and users will use to interact with the cluster. 


Install cfssl

```
wget -q --show-progress --https-only --timestamping https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
```

Create directories for TLS certs

```
mkdir -p pki/{admin,api,ca,clients,controller,proxy,scheduler,service-account,users}
```
Setting TLS attributes

```
TLS_C="CN"
TLS_OU="Hardenedlinux Kubernetes"
```

#### Generate the CA (Certificate Authority) config files & certificates

```
cat > pki/ca/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```

```
cat > pki/ca/ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "Hardenedlinux",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF


cfssl gencert -initca pki/ca/ca-csr.json | cfssljson -bare pki/ca/ca
```

#### Generate the admin user config files and certificates

```
cat > pki/admin/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "system:masters",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/admin/admin-csr.json | cfssljson -bare pki/admin/admin
```

####  Generate the worker(s) certs and keys

for each worker `worker-0, worker-1, worker-2`, we should manually set up following contents

```
EXTERNAL_IP=${YOU PUBLIC IP}
INTERNAL_IP=${YOU WORKER IP} #eg: 192.168.200.185
instance=worker-0 

cat > pki/clients/${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "system:nodes",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=${instance},${INTERNAL_IP},${EXTERNAL_IP} \
  -profile=kubernetes \
  pki/clients/${instance}-csr.json | cfssljson -bare pki/clients/${instance}
done
```

#### Generate the kube-controller-manager cert and key

```
cat > pki/controller/kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "system:kube-controller-manager",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/controller/kube-controller-manager-csr.json | cfssljson -bare pki/controller/kube-controller-manager
```

#### Generate the kube-proxy cert and key

```
cat > pki/proxy/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "system:node-proxier",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/proxy/kube-proxy-csr.json | cfssljson -bare pki/proxy/kube-proxy
```

#### Generate the scheduler cert and key

```
cat > pki/scheduler/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "system:kube-scheduler",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/scheduler/kube-scheduler-csr.json | cfssljson -bare pki/scheduler/kube-scheduler
```

#### Generate the api-server cert and key

The KUBERNETES_PUBLIC_ADDRESS will be the IP/VIP/Pool IP of the load balancer that will direct all traffic to the controller nodes. In our case it’s 192.168.200.190

NOTE: The — ‘hostname=’ line may need adjusting if you have different IPs for your controllers.


```
KUBERNETES_PUBLIC_ADDRESS=192.168.200.190


cat > pki/api/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "Kubernetes",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=10.32.0.1,192.168.200.180,192.168.200.181,192.168.200.182,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  pki/api/kubernetes-csr.json | cfssljson -bare pki/api/kubernetes
```

#### Generate the service-account cert and key

```
cat > pki/service-account/service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "O": "Kubernetes",
      "OU": "${TLS_OU}"
    }
  ]
}
EOF
cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/service-account/service-account-csr.json | cfssljson -bare pki/service-account/service-account
```

#### Copy the certs

To worker

```
for instance in worker-0 worker-1 worker-2; do
  scp pki/ca/ca.pem pki/clients/${instance}-key.pem pki/clients/${instance}.pem ${instance}:~/
done
```

To controller

```
for instance in controller-0 controller-1 controller-2; do
  scp pki/ca/ca.pem pki/ca/ca-key.pem pki/api/kubernetes-key.pem pki/api/kubernetes.pem pki/service-account/service-account-key.pem pki/service-account/service-account.pem ${instance}:~/
done
```

### Generate kubeconfigs and encryption key

Get a directory created so you can drop all the configuration files in there.

```
mkdir configs
```

#### Generate Worker kubeconfigs

KUBERNETES_PUBLIC_ADDRESS=192.168.200.190

```
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster hardenedlinux-kubernetes \
    --certificate-authority=pki/ca/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=configs/clients/${instance}.kubeconfig
kubectl config set-credentials system:node:${instance} \
    --client-certificate=pki/clients/${instance}.pem \
    --client-key=pki/clients/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=configs/clients/${instance}.kubeconfig
kubectl config set-context default \
    --cluster=hardenedlinux-kubernetes \
    --user=system:node:${instance} \
    --kubeconfig=configs/clients/${instance}.kubeconfig
kubectl config use-context default --kubeconfig=configs/clients/${instance}.kubeconfig
done
```

#### Generate kube-proxy kubeconfig

```
kubectl config set-cluster hardenedlinux-kubernetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig
kubectl config set-credentials system:kube-proxy \
  --client-certificate=pki/proxy/kube-proxy.pem \
  --client-key=pki/proxy/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig
kubectl config set-context default \
  --cluster=hardenedlinux-kubernetes \
  --user=system:kube-proxy \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=configs/proxy/kube-proxy.kubeconfig
```

#### Generate kube-controller-manager kubeconfig

```
kubectl config set-cluster hardenedlinux-kubernetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig
kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=pki/controller/kube-controller-manager.pem \
  --client-key=pki/controller/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig
kubectl config set-context default \
  --cluster=hardenedlinux-kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=configs/controller/kube-controller-manager.kubeconfig
```

#### Generate kube-scheduler kubeconfig

```
kubectl config set-cluster hardenedlinux-kubernetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig
kubectl config set-credentials system:kube-scheduler \
  --client-certificate=pki/scheduler/kube-scheduler.pem \
  --client-key=pki/scheduler/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig
kubectl config set-context default \
  --cluster=hardenedlinux-kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig
kubectl config use-context default --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig
```

#### Generate admin user kubeconfig

```
kubectl config set-cluster hardenedlinux-kubernetes \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/admin/admin.kubeconfig
kubectl config set-credentials admin \
  --client-certificate=pki/admin/admin.pem \
  --client-key=pki/admin/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/admin/admin.kubeconfig
kubectl config set-context default \
  --cluster=hardenedlinux-kubernetes \
  --user=admin \
  --kubeconfig=configs/admin/admin.kubeconfig
kubectl config use-context default --kubeconfig=admin.kubeconfig
```

#### Move all kubeconfig

```
for instance in worker-0 worker-1 worker-2; do
  scp configs/clients/${instance}.kubeconfig configs/proxy/kube-proxy.kubeconfig ${instance}:~/
done
for instance in controller-0 controller-1 controller-2; do
  scp configs/admin/admin.kubeconfig configs/controller/kube-controller-manager.kubeconfig configs/scheduler/kube-scheduler.kubeconfig ${instance}:~/
done
```

#### Generating the data encryption key and config

This will be used for encrypting data between nodes.

```
mkdir data-encryption
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > data-encryption/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

push the encryption config file to controller

```
for instance in controller-0 controller-1 controller-2; do
  scp data-encryption/encryption-config.yaml ${instance}:~/
done
```
### Configuring Controllers

#### Setting up ETCD

Download etcd file

```
wget -q --show-progress --https-only --timestamping "https://github.com/coreos/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz"
tar -xvf etcd-v3.3.13-linux-amd64.tar.gz
mv etcd-v3.3.13-linux-amd64/etcd* /usr/local/bin/
```

#### Configuring the ETCD server

Change enp1s0 to your interface name.
Following setup should perform every controller node

```
mkdir -p /etc/etcd /var/lib/etcd
mv * ~/
cp ~/ca.pem ~/kubernetes-key.pem ~/kubernetes.pem /etc/etcd/
```

```
INTERNAL_IP=$(ip addr show enp1s0 | grep -Po 'inet \K[\d.]+') #THIS controller's internal IP
ETCD_NAME=controller-0
```

Create the service file

```
cat <<EOF | tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos
[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://192.168.200.180:2380,controller-1=https://192.168.200.181:2380,controller-2=https://192.168.200.182:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

#### Start the service

```
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

#### Test etcd

```
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem


##Returns

8f96a718a46f8769, started, controller-2, https://192.168.200.182:2380, https://192.168.200.182:2379
a3825c01b40c365f, started, controller-1, https://192.168.200.181:2380, https://192.168.200.181:2379
b9f73f8da6b4eff4, started, controller-0, https://192.168.200.180:2380, https://192.168.200.180:2379
```


#### Setting up the K8S brains

Download binaries

```
mkdir -p /etc/kubernetes/config

wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
```

#### Configure the api server

```
mkdir -p /var/lib/kubernetes/
cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
```

Create the service

```
cat <<EOF | tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://192.168.200.180:2379,https://192.168.200.181:2379,https://192.168.200.182:2379 \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

#### Configure the controller manager

```
cp ~/kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Create the service

```
cat <<EOF | tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --allocate-node-cidrs=true \\
  --node-cidr-mask-size=24 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --cert-dir=/var/lib/kubernetes \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

#### Configure the scheduler

```
cp ~/kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Create the yaml config files

```
cat <<EOF | tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

configure the service

```
cat <<EOF | tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

#### Start the services 

```
systemctl daemon-reload
systemctl enable kube-apiserver kube-controller-manager kube-scheduler
systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

#### Setup the HTTP health checks

Since the /healthz check sits on port 6443, and you’re not exposing that, you need to to nginx installed as a proxy (or any other proxy service you wish of course).

```
apt install -y nginx

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;
location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

rm /etc/nginx/sites-enabled/default
mv kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
systemctl restart nginx
```
#### Verify all is healthy

```
kubectl get componentstatuses --kubeconfig admin.kubeconfig
```

check the nginx is working

```
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz

##Returns

HTTP/1.1 200 OK
Server: nginx/1.10.3
Date: Wed, 08 May 2019 07:40:12 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 2
Connection: keep-alive
X-Content-Type-Options: nosniff
```

#### Configure the RBAC

Only on one of the controllers

```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

### Configuring the load balancer in front of apiserver

We using nginx as kube-api server frontend lord balancer

#### Install Nginx

```
apt install nginx -y
```

Add following content in `/etc/nginx/nginx.conf`

```
stream {
    upstream kubernetes {
        server 192.168.200.180:6443;
        server 192.168.200.181:6443;
        server 192.168.200.182:6443;
    }

    server {
        listen 6443;
        listen 443;
        proxy_pass kubernetes;
    }
}
```

### Configuring the workers

Download the worker releated binaries

```
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.14.0/crictl-v1.14.0-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.7.5/cni-plugins-amd64-v0.7.5.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.6/containerd-1.2.6.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubelet
```

Create directories

```
mkdir -p \
 /etc/cni/net.d \
 /opt/cni/bin \
 /var/lib/kubelet \
 /var/lib/kube-proxy \
 /var/lib/kubernetes \
 /var/run/kubernetes
```

Install all 

```
mv runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 runsc
mv runc.amd64 runc
chmod +x kubectl kube-proxy kubelet runc runsc
mv kubectl kube-proxy kubelet runc runsc /usr/local/bin/
tar -xvf crictl-v1.14.0-linux-amd64.tar.gz -C /usr/local/bin/
tar -xvf cni-plugins-amd64-v0.7.5.tgz  -C /opt/cni/bin/
tar -xvf containerd-1.2.6.linux-amd64.tar.gz -C /
```

#### CNI Networking

on every worker node, run following setup

for example:

worker-0 POD_CIDR=10.200.0.0/24
worker-1 POD_CIDR=10.200.1.0/24
worker-2 POD_CIDR=10.200.2.0/24

create the CNI bridge network config file

on worker-0

```
POD_CIDR=10.200.0.0/24

cat <<EOF | tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

loopback config

```
cat <<EOF | tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
```

Setting forward

```
modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
```


add ipv4 forward=1 option and add `net.bridge.bridge-nf-call-iptables = 1` in `/etc/sysctl.conf`
```
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables = 1
```
and perform change.

```
sysctl -p
```


#### Containerd setup

```
mkdir -p /etc/containerd/
cat << EOF | tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
    [plugins.cri.containerd.gvisor]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
EOF
```
create containerd service

```
cat <<EOF | tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target
[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
[Install]
WantedBy=multi-user.target
EOF
```

Note: if your server have some connective problem with google releated server, you should add a proxy on service file

for example:

```
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target
[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
Environment="HTTP_PROXY=http://192.168.200.185:8123/"
Environment="HTTPS_PROXY=http://192.168.200.185:8123/"
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
[Install]
WantedBy=multi-user.target
```

So when you pull images from k8s.gcr.io will be no problem.

#### Configure kubelet

Copy/Move files

```
cp ~/${HOSTNAME}-key.pem ~/${HOSTNAME}.pem /var/lib/kubelet/
cp ~/${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
cp ~/ca.pem /var/lib/kubernetes/
```

Generate configs

```
cat <<EOF | tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
```

Create service

```
cat <<EOF | tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service
[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

kube-proxy configs and service

```
cp kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

cat <<EOF | tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF
cat <<EOF | tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

Disable swap

```
swapoff -a

and comment out the swap section in  /etc/fstab
```

#### Start the service

```
systemctl daemon-reload
systemctl enable containerd kubelet kube-proxy systemd-resolved
systemctl start containerd kubelet kube-proxy systemd-resolved
```

### Configure DNS

on controller node
```
cat > coredns.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: coredns
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:coredns
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  - services
  - pods
  - namespaces
  verbs:
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:coredns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
- kind: ServiceAccount
  name: coredns
  namespace: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          upstream
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/name: "CoreDNS"
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
    spec:
      serviceAccountName: coredns
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      containers:
      - name: coredns
        image: coredns/coredns:1.3.1
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
      dnsPolicy: Default
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "CoreDNS"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.32.0.10
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF
```
Install CoreDNS
```
kubectl apply -f coredns.yaml
```

### Install CNI Plugin

Install Flannel

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```



Reference: 

http://www.opus1.com/www/whitepapers/pki-whatisacert.pdf   
https://medium.com/@DrewViles/kubernetes-the-hard-way-on-bare-metal-vms-fdb32bc4fed0   
https://containerd.io/   
