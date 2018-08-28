# Syzkaller Setup: Ubuntu16.04 host, QEMU vm, x86-64 kernel

## Introduction

These are the instructions on how to fuzz the x86-64 kernel in a QEMU with Ubuntu 16.04 on the host machine and Debian Wheezy in the QEMU instances.

This guide will contain of three partitation. 
- Build syzkaller by golang
- Build to-be-fuzzed kernel
- run to-be-fuzzed kernel by QEMU with compiled kernel and provided .img file

## Build syzkaller by golang

### deploy golang 

``` 
wget https://storage.googleapis.com/golang/go1.10.3.linux-amd64.tar.gz
tar -xvzf go1.10.3.linux-amd64.tar.gz -C /home/root/go
```
And the golang compiler will locate at /home/root/go. 

**NOTE:** For China, use the following links or other links which can be accessed (tested on the stable version of go1.10.3). So the code will be:
```
wget https://studygolang.com/dl/golang/go1.10.3.linux-amd64.tar.gz
tar -xvzf go1.10.3.linux-amd64.tar.gz -C /home/root/go
```

### Add line to bashrc (for better understanding of deployment)
Add the follow-up option to  ~/.bashrc  

- The path of golang compiler pack:  
`export GOROOT=/home/root/go`  
`export PATH=$GOROOT/bin:$PATH`  
- The directory that golang work in:  
`export GOPATH=/home/root/syzkalls/`  
- Syzkaller binary located at:  
`export PATH=/home/root/syzkalls/bin:$PATH`  

The $(GOROOT) is the directory of golang compiler binary. When you run "go" on your machine, the basic work directory is $GOPATH. Final option is where the syzkaller binary where we will use. Both of them can be modified as your willing.  

### Download the syzkaller source and build

`go get -u -d -v github.com/google/syzkaller/...`  
**NOTE**: maybe use "git clone" in shell is also OK.
After a long time for downloading, run:  

``` bash
cd $GOPATH/src/github.com/google/syzkaller
make -j4
cp $GOPATH/src/github.com/google/syzkaller/bin $GOPATH/ -af
```
After that, you will find syz-* executable under the dirtory $(GOPATH)/bin.  

## Build to-be-fuzzed kernel

### Build to-be-fuzzed kernel by recent GCC version

- deploy recent GCC

> Since syzkaller requires coverage support in GCC, we need to use a recent GCC version[1].

In this paper, the version used for build kernel is GCC8.3, but the other newest version should be ok.

- Change the version of GCC:
```
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install gcc-8
```
Check the version of GCC:
```bash
gcc --version
```

- Download kernel, change .config file and make
Checkout the lasted Linux kernel source:
``` bash
git clone https://github.com/torvalds/linux.git $KERNEL
```
[For China researcher uses the following link to download the repository:]
```
git clone https://mirrors.tuna.tsinghua.edu.cn/git/linux.git
```

Generate default configs:
``` bash
cd $KERNEL
make defconfig
make kvmconfig
```

Now we need to enable some config options required for syzkaller. Edit `.config` file manually:
```
vi .config
```
and enable
**[required]**
```
CONFIG_KCOV=y
CONFIG_DEBUG_INFO=y
CONFIG_KASAN=y
CONFIG_KASAN_INLINE=y
```

OR

**[recommended]** 

To enable coverage collection, which is extremely important for effective fuzzing:
```
CONFIG_KCOV=y
CONFIG_KCOV_INSTRUMENT_ALL=y
CONFIG_KCOV_ENABLE_COMPARISONS=y
CONFIG_DEBUG_FS=y
```
To show code coverage in web interface:
```
CONFIG_DEBUG_INFO=y
```
For detection of enabled syscalls and kernel bitness:
```
CONFIG_KALLSYMS=y
CONFIG_KALLSYMS_ALL=y
```
For `namespace` sandbox:
```
CONFIG_NAMESPACES=y
CONFIG_USER_NS=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
```
Enable `KASAN` for use-after-free and out-of-bounds detection:
```
CONFIG_KASAN=y
CONFIG_KASAN_INLINE=y
```
For testing with fault injection enable the following configs (syzkaller will pick it up automatically):
```
CONFIG_FAULT_INJECTION=y
CONFIG_FAULT_INJECTION_DEBUG_FS=y
CONFIG_FAILSLAB=y
CONFIG_FAIL_PAGE_ALLOC=y
CONFIG_FAIL_MAKE_REQUEST=y
CONFIG_FAIL_IO_TIMEOUT=y
CONFIG_FAIL_FUTEX=y
```
Any other debugging configs, the more the better, here are some that proved to be especially useful:
```
CONFIG_LOCKDEP=y
CONFIG_PROVE_LOCKING=y
CONFIG_DEBUG_ATOMIC_SLEEP=y
CONFIG_PROVE_RCU=y
CONFIG_DEBUG_VM=y
CONFIG_REFCOUNT_FULL=y
CONFIG_FORTIFY_SOURCE=y
CONFIG_HARDENED_USERCOPY=y
CONFIG_LOCKUP_DETECTOR=y
CONFIG_SOFTLOCKUP_DETECTOR=y
CONFIG_HARDLOCKUP_DETECTOR=y
CONFIG_DETECT_HUNG_TASK=y
CONFIG_WQ_WATCHDOG=y
```
Increase RCU stall timeout to reduce false positive rate:
```
CONFIG_RCU_CPU_STALL_TIMEOUT=60
```
more info see this config doc: https://github.com/google/syzkaller/edit/master/docs/linux/kernel_configs.md.


- Build the kernel with previously built GCC:
```
make -j4
```
**NOTE:** maybe you should check and select y/n or 1 or 2 when the begining of make process.

Now check the exsistance of `vmlinux` (kernel binary) at and `bzImage` (packed kernel image):
``` bash
ls $KERNEL/vmlinux
ls $KERNEL/arch/x86/boot/bzImage 
```

## Run to-be-fuzzed kernel by QEMU and download .img file

### Get the .img file to run kernel on QEMU

Install debootstrap:
``` bash
sudo apt-get install debootstrap
```
Use [this script](https://github.com/google/syzkaller/blob/master/tools/create-image.sh) to create a minimal Debian-wheezy Linux image (about 2G).
The result should be `$IMAGE/wheezy.img` disk image and ssh-key(wheezy.id_rsa and wheezy.id_rsa.pub) for ssh connection between host and vm.

## Deploy QEMU with to-be-fuzzed kernel and .image

Install `QEMU`:
``` bash
sudo apt-get install kvm qemu-kvm
```
Make sure the kernel boots and `sshd` starts:
``` bash
qemu-system-x86_64 \
  -kernel $KERNEL/arch/x86/boot/bzImage \
  -append "console=ttyS0 root=/dev/sda debug earlyprintk=serial slub_debug=QUZ"\
  -hda $IMAGE/wheezy.img \
  -net user,hostfwd=tcp::10021-:22 -net nic \
  -enable-kvm \
  -nographic \
  -m 2G \
  -smp 2 \
  -pidfile vm.pid \
  2>&1 | tee vm.log
```
The expected console output is:
```
early console in setup code
early console in extract_kernel
input_data: 0x0000000005d9e276
input_len: 0x0000000001da5af3
output: 0x0000000001000000
output_len: 0x00000000058799f8
kernel_total_size: 0x0000000006b63000

Decompressing Linux... Parsing ELF... done.
Booting the kernel.
[    0.000000] Linux version 4.12.0-rc3+ ...
[    0.000000] Command line: console=ttyS0 root=/dev/sda debug earlyprintk=serial
...
[ ok ] Starting enhanced syslogd: rsyslogd.
[ ok ] Starting periodic command scheduler: cron.
[ ok ] Starting OpenBSD Secure Shell server: sshd.
```

After that you should be able to ssh to QEMU instance in another terminal:
``` bash
ssh -i $IMAGE/ssh/id_rsa -p 10021 -o "StrictHostKeyChecking no" root@localhost
```
If this fails with "too many tries", ssh may be passing default keys before
the one explicitly passed with `-i`. Append option `-o "IdentitiesOnly yes"`.

To kill the running QEMU instance:
``` bash
kill $(cat vm.pid)
```

## Run syzkaller and fuzz

Create a manager config like the following in syzkaller directory, replacing the environment
variables `$GOPATH`, `$KERNEL` and `$IMAGE` with their actual **[ABSOLUTE PATH]**.
```
{
	"target": "linux/amd64",
	"http": "127.0.0.1:56741",
	"workdir": "$GOPATH/src/github.com/google/syzkaller/workdir",
	"kernel_obj": "$KERNEL",
	"image": "$IMAGE/wheezy.img",
	"sshkey": "$IMAGE/ssh/id_rsa",
	"syzkaller": "$GOPATH/src/github.com/google/syzkaller",
	"procs": 8,
	"type": "qemu",
	"vm": {
		"count": 4,
		"kernel": "$KERNEL/arch/x86/boot/bzImage",
		"cpu": 2,
		"mem": 2048
	}
}
```

Run syzkaller manager:
``` bash
./bin/syz-manager -config=my.cfg
```

Now syzkaller should be running, you can check manager status with your web browser at `127.0.0.1:56741`.
If you get issues after `syz-manager` starts, consider running it with the `-debug` flag.
Also see [this page](https://github.com/google/syzkaller/blob/master/docs/troubleshooting.md) for troubleshooting tips.

## REFERENCES

1. [Setup: Ubuntu host, QEMU vm, x86-64 kernel](https://github.com/google/syzkaller/blob/master/docs/linux/setup_ubuntu-host_qemu-vm_x86-64-kernel.md)
2. [Kernel QA with syzkaller and qemu](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/harbian_qa/fuzz_testing/syzkaller_general.md)

