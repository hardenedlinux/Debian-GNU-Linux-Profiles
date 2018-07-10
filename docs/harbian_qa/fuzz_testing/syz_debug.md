# Kernel debug tool with syzkaller  
In this docutmentation, we will introduce some tools or cmdline to help you to debug with the syzkaller.
1. Check the booting and running of QEMU and extend the syscall. 
2. Then, you may need to check the syscall ran by syzkaller or the kernel reaction triggered by syzkaller. I use systemtap to detect the syscall running and KGDB to analyse the code path of kernel triggered by syscall. 
3. In some case you may be interested in the coverage of fuzzer. syzkaller use the KCOV interface to record coverage information. 

## Check VM  
The following cmdline can help you to exclude the error of syzkaller running:
```  
syz-manager -config configure.json --debug
```  
The option --debug will show off the activity of syz-executor. Run the following on your host:
```
ps -aux|grep qemu
```
You may get some output like:
```  
 qemu-system-x86_64 -m 2048 -net nic -net user,host=10.0.2.10,hostfwd=tcp::15965-:22 -display none -no-reboot -enable-kvm -hda /root/linux_img/syzkalls.img -snapshot -initrd initrd.img -kernel bzImage -append console=ttyS0 vsyscall=native rodata=n root=/dev/sda1
```  
This cmdline can display the QEMU option specified by syz-manager, some inappropriate options may cause the fault of syz-manager. You can modify the options and run it individually to check it. Some options specified in you configure and the other default options are located in syzkaller/vm/qemu/qemu.go. Try to modify it and rebuild to fit you mechine environment.

* I met a VM boot error because of no sound device, use [this patch as a example](delete_qemu_default_option.diff) of how to modify source.

## Check ssh to remote(VM)
In many case, you may need to check the running of the VM. Run on the following cmdline on your host:
```  
ps -aux|grep qemu
```  
find out the option like:
```  
hostfwd=tcp::$(PORT)-:22
```  
Then, run:
```  
ssh -p $(PORT) root@127.0.0.1
```  
The systemtap depend on the right running of ssh( syzkaller also).

## Extern the syscall
In my cause, I only use syzkaller on Linux/X86_64.After writing you syscall discription to $(SYZKALLER)/sys/linux/*.txt, you can run:
```  
make HOSTOS=linux HOSTARCH=amd64 TARGETOS=linux TARGETARCH=amd64 SOURCEDIR=$(YOUR_KERNEL_SOURCE_DIR) extract
make HOSTOS=linux HOSTARCH=amd64 TARGETOS=linux TARGETARCH=amd64 SOURCEDIR=$(YOUR_KERNEL_SOURCE_DIR) generate
make HOSTOS=linux HOSTARCH=amd64 TARGETOS=linux TARGETARCH=amd64 SOURCEDIR=$(YOUR_KERNEL_SOURCE_DIR) -jN
```  
That will rebuild syzkaller with you own syscall. Then, scp binary to your VM.

## Moniter remote(VM) with systemtap
I use systemtap to verify if the code is reachable after fuzzer execute. You can extend other features by writing your own stap script. [Here is a tutorial](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/docs/harbian_qa/systemtap.md) of systemtap the remote/virtual machine, [this is a example]() of show how much times the fuzzer triggered a kernel handle function.

## KGDB single step analysis
To run KGDB with QEMU, the cmdline option of QEMU need some modify, add the following option to `qemu_args` configuration parameter of manager config file:
```
  "vm": [
    ...
    "count": 1,
    "qemu_args": "-gdb tcp::1234"
  ]
```  
then run it on your host:
```  
gdb -q build_tree/vmlinux 
Reading symbols from build_tree/vmlinux...done.
(gdb) target remote : 1234
```  
You may need debug the kernel module, first, ssh to VM, print the sections:
```  
cat /sys/module/$(YOUR_MODULE)/sections/.text /sys/module/$(YOUR_MODULE)/sections/.data /sys/module/$(YOUR_MODULE)/sections/.bss
```  
add debug file to gdb:
```  
add-symbol-file /$(YOUR_BUILD_TREE)/$(YOUR_MODULE)/$(YOUR_MODULE).ko $(ADDR_OF_TEXT) -s data $(ADDR_OF_DATA) -s bss $(ADDR_OF_BSS)
```  
Now, you can add break point to kernel modules.
I use KGDB to analys the code path of kernel triggered by syzkaller. Note that `-gdb` option may affect the count of VMs, just use it when you extern your own system calls.

## KCOV
Syzkaller use the KCOV collect the information of coverage, every instance will initial KCOV interface, KCOV interface locate in /sys/kernel/debug/kcov, enable/disable it by using ioctl. Implement is in executor/executor_linux.cc
xecutor/executor_linux.cc:a set of cover_* functions.
Note that full debug information need the right vmlinux specified by syz-manager configure. You can get the coverage of the fuzzer by accessing the server of syzkaller:
```  
http://127.0.0.1:$(PORT)/cover
```  
The KCOV will show the covered branch with different color. The coverage of kernel modules is not mentioned.

## Syzkaller and snadbox
Syzkaller with sandbox enable may block syscalls which is not mentioned in configure file, but syzkaller's repro may depend on it.
The implement of sandbox is in xecutor/executor_linux.cc. Setuid mode use unshare and namespace mode use clone.
