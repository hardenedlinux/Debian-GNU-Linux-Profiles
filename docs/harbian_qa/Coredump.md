# Core dump for Debian 9
## Tools install
You can run the following cmdline to install:  
```
apt install kdump-tools crash kexec-tools makedumpfile `uname -r`-dbg
```  
- kdump will be called and then dump the memory when your kernel was crash.  
- makedump will be call by kdump to make a specify format file which can be read by debug tool.
- kexec can reboot a kernel bypass BIOS
- \`uname -r`-dbg is the kernel with debug information, locate in /usr/lib/debug
- crash is a debug tool

## Configuration
### Kdump configuration
First, we should enable kdump when the kernel was crash:  
```
~# nano /etc/default/kdump-tools 
...
USE_KDUMP=1
...
KDUMP_COREDIR="/var/crash"
KDUMP_FAIL_CMD="reboot -f"
...
```
- USE_KDUMP should be enable, so the kdump will be called when kernel crashed.
- KDUMP_COREDIR="/var/crash" will determine where the dumpfile was locate in.
- KDUMP_FAIL_CMD is the action after dump finish.

### Grub configuration
Change the cmdline as following:
```
~# nano /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet crashkernel=128M"
```
- crashkernel determine the memory reseve for kernel, more information can be found in kernel's documentation Documentation/admin-guide/kernel-parameters.txt

Now, update you grub:  
`update-grub`
reboot your machine.

### Test
Run the follow cmdline the kernel will be crashed:
`echo c > /proc/sysrq-trigger`
After reboot, you can find a dumpfile under `/var/crash`( determine by KDUMP_COREDIR).
Try to use the dumpfile with a debug tool:
```
root@debian:~# crash /usr/lib/debug/vmlinux-4.9.0-3-amd64 /var/crash/201706061104/dump.201706061104 

crash 7.1.7
...
Copyright (C) 1999, 2000, 2001, 2002  Mission Critical Linux, Inc.
 
GNU gdb (GDB) 7.6
Copyright (C) 2013 Free Software Foundation, Inc.
...

WARNING: kernel relocated [600MB]: patching 76353 gdb minimal_symbol values

      KERNEL: /usr/lib/debug/vmlinux-4.9.0-3-amd64                     
    DUMPFILE: /var/crash/201706061104/dump.201706061104  [PARTIAL DUMP]
        CPUS: 1
        DATE: Tue Jun  6 11:04:09 2017
      UPTIME: 00:04:20
LOAD AVERAGE: 0.11, 0.13, 0.05
       TASKS: 376
    NODENAME: debian
     RELEASE: 4.9.0-3-amd64
     VERSION: #1 SMP Debian 4.9.25-1 (2017-05-02)
     MACHINE: x86_64  (2399 Mhz)
      MEMORY: 2 GB
       PANIC: "sysrq: SysRq : Trigger a crash"
         PID: 1091
     COMMAND: "bash"
        TASK: ffff9731b903e240  [THREAD_INFO: ffff9731b903e240]
         CPU: 0
       STATE: TASK_RUNNING (SYSRQ)
```
Now you can use debug tools, for example:
```
crash> bt
PID: 1091   TASK: ffff9731b903e240  CPU: 0   COMMAND: "bash"
 #0 [ffffbf46823afc30] machine_kexec at ffffffffa6851e58
 #1 [ffffbf46823afc88] __crash_kexec at ffffffffa6903389
 #2 [ffffbf46823afd48] crash_kexec at ffffffffa69034a8
 #3 [ffffbf46823afd60] oops_end at ffffffffa6828973
 #4 [ffffbf46823afd80] no_context at ffffffffa685f421
 #5 [ffffbf46823afde0] async_page_fault at ffffffffa6e05548
    [exception RIP: sysrq_handle_crash+18]
    RIP: ffffffffa6c1cd42  RSP: ffffbf46823afe90  RFLAGS: 00010282
    RAX: 000000000000000f  RBX: 0000000000000063  RCX: 0000000000000000
    RDX: 0000000000000000  RSI: ffff9731bfc0de28  RDI: 0000000000000063
    RBP: ffffffffa74b9b80   R8: 0000000000000001   R9: 0000000000007170
    R10: 0000000000000001  R11: 0000000000000001  R12: 0000000000000004
    R13: 0000000000000000  R14: 0000000000000000  R15: 0000000000000002
    ORIG_RAX: ffffffffffffffff  CS: 0010  SS: 0018
 #6 [ffffbf46823afe90] __handle_sysrq at ffffffffa6c1d461
 #7 [ffffbf46823afeb8] write_sysrq_trigger at ffffffffa6c1d89b
 #8 [ffffbf46823afec8] proc_reg_write at ffffffffa6a7042d
 #9 [ffffbf46823afee0] vfs_write at ffffffffa6a01f30
#10 [ffffbf46823aff10] sys_write at ffffffffa6a03312
#11 [ffffbf46823aff50] system_call_fast_compare_end at ffffffffa6e0413b
    RIP: 00007ff49c9f2760  RSP: 00007fffbb3972e8  RFLAGS: 00000246
    RAX: ffffffffffffffda  RBX: 0000000000000000  RCX: 00007ff49c9f2760
crash> 
```
Here is a call trace print by command `bt`.
