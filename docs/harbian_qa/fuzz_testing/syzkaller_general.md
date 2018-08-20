# Kernel QA with syzkaller and qemu 
This guide will contain of three partitation. 
- Build syzkaller
- Install and configure a VM with syzakaller support
- Modify a fit configure

## install golang and build syzkaller
### download and decompress 
`wget https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz`  
`tar -xvzf go1.8.1.linux-amd64.tar.gz -C /home/root/go`  
After that, the golang compiler will locate at /home/root/go. 

### Add line to bashrc  
Add the follow-up option to  ~/.bashrc  
- The path of golang compiler pack:  

`export GOROOT=/home/root/go`  
`export PATH=$GOROOT/bin:$PATH`  
- The diryory golang work in:  

`export GOPATH=/home/root/syzkalls/`  
- Syzkaller binary located at:  

`export PATH=/home/root/syzkalls/bin:$PATH`  
The $(GOROOT) is the directory of golang compiler binary. When you run "go" on your machine, the basic work directory is $GOPATH. Final option is where the syzkaller binary where we will use. Both of them can be modified as your willing.  

### Download the syz source and build
`go get -u -d -v github.com/google/syzkaller/...`  
After a long time for downloading, run:  
`cd $GOPATH/src/github.com/google/syzkaller`  
`make -j4`  
`cp $GOPATH/src/github.com/google/syzkaller/bin $GOPATH/ -af`  
After that, you will find syz-* executable under the dirtory $(GOPATH)/bin.  

## Install vm with syzkaller support  
### Install a vm on qemu  
`qemu-img create /PATH/TO/YOUR/VM_HDA $(SIZE)G`  
This cmd will create a image "/PATH/TO/YOUR/VM_HDA" with size "$(SIZE)G"  

`qemu-system-x86_64 -m 4096 -hda /PATH/TO/YOUR/VM_HDA -enable-kvm -cdrom /PATH/TO/YOUR/IMG -boot d`  
-cdrom is the livecd iso dowload from net  
- sshd should be enable when installed  

<b>Run VM with sshd:</b>  

`qemu-system-x86_64 -m 4096 -hda /PATH/TO/YOUR/VM_HDA --enable-kvm -net nic -net user,host=10.0.2.10,hostfwd=tcp::$(SSH_PORT)-:22`  
$(SSH_PORT) can be specify as your willing.  

### Set VM login without password  
<b>run in localhost with a qemu running:</b>  
`ssh-keygen -t rsa`  
this cmdline will generate two keys, public key id_isa.pub and pravite id_isa  
`scp id_rsa.pub -P $(SSH_PORT) root@vm:/root/.ssh/id_isa.pub`  
copy public key to VM.  
### Edit sshd configure on your VM  
<b>login to vm guest by ssh:</b>  
`ssh -p $(SSH_PORT) root@127.0.0.1`  
<b>check option flowing:</b>  
`nano /etc/ssh/sshd_config`  
```
PermitRootLogin without-password

RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile	/root/.ssh/id_rsa.pub

RhostsRSAAuthentication yes
PermitEmptyPasswords no
PasswordAuthentication no

UsePAM no
```  
run`sudo /etc/init.d/ssh restart`restart the sshd.  

### Verify the public key login is ok  
<b>Run the flowing cmdline on localhost:</b>  
`qemu-system-x86_64 -m 4096 -hda /PATH/TO/YOUR/VM_HDA --enable-kvm -net nic -net user,host=10.0.2.10,hostfwd=tcp::23505-:22`  
Try to ssh to VM:  
`ssh -p $(SSH_PORT)  -i ssh_key/id_rsa root@127.0.0.1 -v`  

### Copy syzkaller binary to vm  
`scp -P $(SSH_PORT) -i ~/.ssh/id_rsa  -r $(GOPATH)/bin root@127.0.0.1:/root/bin`  
<b>Add PATH to environment in vm:</b>  
`export PATH=/home/root/bin:$PATH`  

## Run syzkaller with custom kernel
### Check the configure option follow-up
you can simplely make defconfig and then modify the option you need.
For code coverage collection:
```
CONFIG_KCOV=y
CONFIG_KCOV_INSTRUMENT_ALL=y
CONFIG_DEBUG_FS=y
```
To show code coverage in web interface:
```
CONFIG_DEBUG_INFO=y
```
For namespace sandbox:
```
CONFIG_NAMESPACES=y
CONFIG_USER_NS=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
```

KASAN for use-after-free and out-of-bounds detection:
```
CONFIG_KASAN=y
CONFIG_KASAN_INLINE=y
```
Any other debugging configs, the more the better, here are some that proved to be especially useful:
```
CONFIG_LOCKDEP=y
CONFIG_PROVE_LOCKING=y
CONFIG_DEBUG_ATOMIC_SLEEP=y
CONFIG_PROVE_RCU=y
CONFIG_DEBUG_VM=y
```
Disable the following configs:  
```
# CONFIG_RANDOMIZE_BASE is not set
```
Increase RCU stall timeout to reduce false positive rate:  
```
CONFIG_RCU_CPU_STALL_TIMEOUT=60
```
Try the follow-up cmdline to test:  
`qemu-system-x86_64 -m 4096 -hda /PATH/TO/YOUR/VM_HDA --enable-kvm -net nic -net
-kernel /PATH/TO/KERNEL/arch/x86_64/boot/bzImage -initrd
/PATH/TO/INITRD/initrd.img -append root=/dev/sda1 user,host=10.0.2.10,hostfwd=tcp::$(SSH_PORT)-:22`  

### Run syzkaller with a generial configure  
config.json for syz-maneger  
```
{
	"http": "127.0.0.1:50000",                        http server specify
	"workdir": "/home/bins/syzkaller/log",            workdir contain of log ...
	"kernel": "/CUSTOM/BUILD/linux/arch/x86/boot/bzImage",  VM kernel specify
	"initrd": "/PATH/TO/initrd.img"，         Vm initrd specify
	"vmlinux": "/PATH/TO/your/vmlinux",               vmlinux for debug
	"image": "/PATH/TO/your/hda",          VM's hard disk
	"syzkaller": $(GOPATH),                             syzkaller work dirtory
	"type": "qemu",                                      VM's type
        "sshkey":"/path/to/.ssh/id_rsa",               key forssh to VM
	"count": 3,                                          VM count
	"procs": 1,                                          processer count
        "cpu": 1,
	"mem": 1024,                                         memory size
        "bin": "/usr/bin/qemu-system-x86_64",           path to qemu
        "cmdline":"console=ttyS0 vsyscall=native rodata=n oops=panic panic_on_warn=1 panic=-1 ftrace_dump_on_oops=orig_cpu earlyprintk=serial slub_debug=UZ root=/dev/sda1",
                                                         VM cmdline
        "enable_syscalls": [
               ],
        "disable_syscalls": [
               "keyctl",
               "add_key",
               "request_key"
               ],
        "suppressions": [
               "some know bug"
               ]
}
```
Then, run the syz-maneger with configure file.  
`syz-manager -config config.json`  
Then open your browser and enter 127.0.0.1：50000, there is a monitor of all test VM you run.  
