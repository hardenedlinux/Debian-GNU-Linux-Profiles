# Syzkaller + Kernel function fail-injection

## Summary
Actually, kernel control flow is driven by syscalls' arguments. Although syzkaller use syscalls describe affectively, it is still difficult to confirm the relationship between syscalls' arguments and kernel control flow because of the long code path. That means we can hardly use syscalls to hit specify code. For special testing, we should:
1. Customize syzkaller for special testing:  
This will guide your syzkaller to hit specific code region, but it is can't change kernel control flow initiatively.
2. Kernel function level fail-injection:  
After guide syzkaller to hit specific code region, using kernel function hook as kernel fail-injection could change the kernel control flow initiatively. Although it will break the integrity of kernel control flow, may somethings intersting happen? 

All of these is for special testing, not for general case.

## Customize syzkaller
To guide syzkaller to hit the specific code region. There are several ways:
1. Specify syscalls for subsystem test
2. [Corpus selective](corpus_selective.md)( by coverage)
3. Run a [semi-fixed or fixed syscalls sequence](https://github.com/hardenedlinux/community-QA/blob/master/syz_patch/insert_beginning.patch)

## Kernel function level fail-injection
Kernel fault-injection can change the kernel control flow more directly. Syzkaller already use kernel fail-injection frame, but it is for general case, isn't base on specific kernel code. I use ftrace as a kernel function hook that can inject true/false data to kernel in function level. Usually, data in kernel function level means argument and retval of kernel function.
### Ftrace hook
[Here is a sample code](https://github.com/hardenedlinux/community-QA/blob/master/syz_patch/tp_repair.c) which can hijack tcp_setsockopt, change it arguments tp->repair. 
Usage:
```  
insmod tp_repair.ko obj_ppid=$$
```  
We use 'ppid' but not 'pid' to confirm the object process because syzkaller use pid namespace. To install module automatically when executor start, modify:
```  
int wait_for_loop(int pid)
{
+       system("rmmod tp_repair");
+       debug("rmmod kfunch_ftrace\n");
        if (pid < 0)
                fail("sandbox fork failed");
        debug("spawned loop pid %d\n", pid);
+       char cmd[0x100];
+       sprintf(cmd, "insmod /root/kprobe/tp_repair.ko obj_ppid=%d", pid);
+       debug("Run cmd: %s\n", cmd);
+       system(cmd);
}
```  
You can inject arbitrary data into kernel function as your will.
Note: 
* real_\*/fh_\* declarations should match with object kernel function.
* Kernel function must can be found in symtab beacuse of using kallsyms_lookup_name to get address( If kernel disable KASLR, analyse address statically is ok).
* Fill different a&b in `if(rand%a < b)` to change the frequence of data injection. Don't inject data too frequently, else it may broken connection between guest and host.

## TODO
* Implement data generation in user space but not hardcode in kernel module help to generate data more diversely and flexibly.
* Collect inject data information and send to syzkaller for later log analysis. 
