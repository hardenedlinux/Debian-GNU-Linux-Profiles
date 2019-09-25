## Using Local Persistent Volumes in Standalone Kubernetes Cluster

The Local Persistent Volumes feature has been promoted to GA in Kubernetes 1.14. At GA, Local Persistent Volumes do not support dynamic volume provisioning.

A local volume represents a mounted local storage device such as a disk, partition or directory.

Note: for Standalone Kubernetes Cluster, you should calculate your storage more carefully, because you can't easy expand your storage like normal cluster do. 

#### Create StorageClass

According to the [docs](https://kubernetes.io/docs/concepts/storage/storage-classes/#local), persistent local volumes require to have a binding mode of WaitForFirstConsumer. 

```
cat > storageClass.yaml << EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```
Create StorageClass

```
kubectl create -f storageClass.yaml
```
should output

```
storageclass.storage.k8s.io/my-local-storage created
```

#### Create Persistent Volume (for mounting a directory)

Because dynamic provisioning is not supported yet. we should manually create local persistent volume.


```
cat > persistentVolume.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/disk/vol1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - examplenode
EOF
```

you should replace `examplenode` with the name of your node. In my case, I should change it to `kubesa`

##### Create a directory

In this example, I simply create a directory in `/mnt/disk/` name `vol1`

```
DIRNAME="vol1"
mkdir -p /mnt/disk/$DIRNAME 
chmod 777 /mnt/disk/$DIRNAME
```

and create the Local Persistent Volume

```
kubectl create -f persistentVolume.yaml
```

#### Create Persistent Volume Claim (for mounting a directory)

```
cat > persistentVolumeClaim.yaml << EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: my-claim
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 5Gi
EOF

kubectl create -f persistentVolumeClaim.yaml
```
should output
```
persistentvolumeclaim/my-claim created
```

check the pv status

```
kubectl get pv

NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
local-pv   100Gi      RWO            Retain           Available           local-storage            52s
```

#### Create a POD with local persistent Volume

```
cat > http-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: www
  labels:
    name: www
spec:
  containers:
  - name: www
    image: nginx:alpine
    ports:
      - containerPort: 80
        name: www
    volumeMounts:
      - name: www-persistent-storage
        mountPath: /usr/share/nginx/html
  volumes:
    - name: www-persistent-storage
      persistentVolumeClaim:
        claimName: my-claim
EOF

kubectl create -f http-pod.yaml
```
then check the pv again

```
kubectl get pv

NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS    REASON   AGE
local-pv   100Gi      RWO            Retain           Bound    default/my-claim   local-storage            10m
```

And the pod is up and running

```
kubectl get pods
NAME     READY   STATUS    RESTARTS   AGE
www      1/1     Running   0          3m29s
```

Check if it works

we create a index.html file in our node
```
kubesa# echo "Hello local persistent volume" > /mnt/disk/vol1/index.html
```

and using curl to visit the web service
```
kubesa# POD_IP=$(kubectl get pod www -o yaml | grep podIP | awk '{print $2}'); curl $POD_IP
```

and return

```
Hello local persistent volume
```

#### Create Persistent Volume (for mounting a raw block device)

Create rar block volume persistent volume
```
cat > persistentVolumeBlock.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-block-pv
spec:
  capacity:
    storage: 900Gi
  volumeMode: Block
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /dev/sdc
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - examplenode
EOF

kubectl create -f persistentVolumeBlock.yaml
```
you should replace `examplenode` with the name of your node. In my case, I should change it to `kubesa`
In this example, our block that we prepare to mount is `/dev/sdc`

#### Create Persistent Volume Claim (for mounting a raw block device)

```
cat > persistentVolumeClaimBlock.yaml <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: my-block-claim
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-storage
  volumeMode: Block
  resources:
    requests:
      storage: 5Gi
EOF

kubectl create -f persistentVolumeClaimBlock.yaml
```
#### Create a POD with local persistent Volume (for raw block device)

```
cat > http-pod-block.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: www-block
  labels:
    name: www-block
spec:
  containers:
  - name: www-block
    image: centos
    securityContext:
      capabilities:
        add: ["SYS_RAWIO"]
    command: ["/bin/sh", "-c"]
    args: [ "tail -f /dev/null" ]
    ports:
      - containerPort: 80
        name: www-block
    volumeDevices:
      - name: block-data
        devicePath: /dev/xvda
  restartPolicy: Always
  volumes:
    - name: block-data
      persistentVolumeClaim:
        claimName: my-block-claim
EOF
```

And we can enter the `http-pod-block` to run some test with block device.

Note: for now, kubernetes bring rar block device support, it’s possible to do low-level actions on them from inside containers that wouldn’t be possible with file system volumes.

But:   
```
Also, while Kubernetes is guaranteed to deliver a block device to the container, there’s no guarantee that it’s actually a SCSI disk or any other kind of disk for that matter. The user must either ensure that the desired disk type is used with his pods, or only deploy applications that can handle a variety of block device types.
```


#### Reference:

https://kubernetes.io/docs/concepts/storage/storage-classes/#local   
https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/   
https://vocon-it.com/2018/12/20/kubernetes-local-persistent-volumes/   
https://kubernetes.io/docs/concepts/storage/volumes/#local   
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#raw-block-volume-support   
https://kubernetes.io/blog/2019/03/07/raw-block-volume-support-to-beta/   
