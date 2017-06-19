# Syzkaller crash DEMO
There are three steps in this guide:
- Adding rules for causing heap overflow into syzkaller and rebuilding it
- Compiling kernel with heap overflow code
- Running syzkaller to hunt the bug

## Add test rules to syzkaller  
The rule is written on the *.txt file under the directory $(SYZKALLER_SOURCE)/sys/. It will be translated to *.const file under the same directory by syz-exract. Then we can rebuild syzkaller with new rule.

### The grammar of *.txt  
```
open$proc(file ptr[in, string["/proc/test"]], flags flags[proc_open_flags], mode flags[proc_open_mode]) fd
...
proc_open_flags = O_RDONLY, O_WRONLY, O_RDWR, O_APPEND, FASYNC, O_CLOEXEC, O_CREAT, O_DIRECT, O_DIRECTORY, O_EXCL, O_LARGEFILE, O_NOATIME, O_NOCTTY, O_NOFOLLOW, O_NONBLOCK, O_PATH, O_SYNC, O_TRUNC, \__O_TMPFILE
proc_open_mode = S_IRUSR, S_IWUSR, S_IXUSR, S_IRGRP, S_IWGRP, S_IXGRP, S_IROTH, S_IWOTH, S_IXOTH
```

A declaration of a system call contain of system call name, argument and return value, the format of system call name show as following:  
`SyscallName$Type`  
The "SyscallName" before '$' is the name of system call, the interface provided by kernel, the "Type" after '$' is the specific type of the system call. In my example here:  
`open$proc`  
It means the system call "open" with a limited tpye "proc", the name is determined by the writer, the limit is determined by the follow-up argument, the format of the arguement as follow:  
`ArgumentName ArgumentType[Limit]`  
ArgumentName is the name of Argument, and ArgumentType is the type of it. In my example, there are several types of argument just like string, flags, etc. The "[Limit]" will limit the value of the argument, syzkaller will generate a random value if it's not specific.  
```
mode flags[proc_open_mode]
proc_open_mode = ...
```
In our example, the argument "mode" with tpye "flags" would pick out a number of value from “proc_open_mode = ......”.  
At the end of declaration is the return value. In my example "fd" is the description of file.  
Some general declaration of system call is writen down in source tree $(SYZKALLER_SOURCE)/sys/sys.txt.  
- More infomation about programer can be found   https://github.com/google/syzkaller/tree/master/sys/README.md  

In my example, heap overflow can be touch off by writing to /proc/test. So, we should limit the argument "file" in "open" to "/proc/test", others can referen the sys.txt.

### Rebuild syzkaller  
cd into source tree $(SYZKALLER_SOURCE), run:
```
make clean
make bin/syz-extract
bin/syz-extract -arch amd64 -linux /PATH/TO/LINUX/SOURCE sys/YourRule.txt
make all
```
"syz-extract":-arch is the Architecture of you test machine, -linux is the kernel build tree will be test.  
### Copy the binary to test machine  
run your virtual machine, then cd into your syzkaller build dirtory run：
`scp -P $(YOUR_PORT) -i ~/.ssh/rsa -r syzkaller/bin root@127.0.0.1:$(YOUR_PATH)`  
- $(YOUR_PORT) specific by your qemu flags
- $(YOUR_PATH) should be added to environment on your VM.

## Kernel module with overflow
We will write a kernel module with heap overflow, the module provides a proc filesystem interface under /proc/test, the fileoperations of /proc/test will call the funtion with heap overflow:
```
static struct file_operations a = {
                                .open = proc_open,
                                .read = proc_read,
                                .write = proc_write,
};
```
there is only one function was shown here( with heap overflow code), full code is attached under the same directory(modules initlization, compiling will not be discussed in this article):
```
static ssize_t proc_write (struct file *proc_file, const char __user *proc_user, size_t n, loff_t *loff)
{
    char *c = kmalloc(512, GFP_KERNEL);

   copy_from_user(c, proc_user, 4096);
    printk(DEBUG_FLAG":into write!\n");
    return 0;
}
```
Put the module code into kernel build tree and build with kernel. To verify if the module was loaded, you can run this in your VM:  
`ls /proc/test`  

## Modify config file and run syzkaller  
In order to test fileoperatiosn, enable these options in configuration:
```
"enable_syscalls": [
                "open$proc",
                "read$proc",
                "write$proc",
                "close$proc"
],
```
Then run the syzkaller:  
`bin/syz-manager -config /PATH/TO/YOUR/CONFIG  -v 10`  
Open your browser and enter 127.0.0.1:50000, after a minute:  
The crash log can be shown as following：
```
PROC_DEV:into open!
==================================================================
BUG: KASAN: slab-out-of-bounds in copy_from_user arch/x86/include/asm/uaccess.h:698 [inline] at addr ffff88003c1f5e20
BUG: KASAN: slab-out-of-bounds in proc_write+0x64/0x90 drivers/mod_test/test.c:45 at addr ffff88003c1f5e20
Write of size 4096 by task syz-executor0/2569
CPU: 0 PID: 2569 Comm: syz-executor0 Not tainted 4.11.0-rc8+ #23
Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS 1.10.2-1 04/01/2014
Call Trace:
 __dump_stack lib/dump_stack.c:16 [inline]
 dump_stack+0x95/0xe8 lib/dump_stack.c:52
 kasan_object_err+0x1c/0x70 mm/kasan/report.c:164
 print_address_description mm/kasan/report.c:202 [inline]
 kasan_report_error mm/kasan/report.c:291 [inline]
 kasan_report+0x252/0x510 mm/kasan/report.c:347
 check_memory_region_inline mm/kasan/kasan.c:326 [inline]
 check_memory_region+0x13c/0x1a0 mm/kasan/kasan.c:333
 kasan_check_write+0x14/0x20 mm/kasan/kasan.c:344
 copy_from_user arch/x86/include/asm/uaccess.h:698 [inline]
 proc_write+0x64/0x90 drivers/mod_test/test.c:45
 proc_reg_write+0xf6/0x180 fs/proc/inode.c:230
 __vfs_write+0x10b/0x560 fs/read_write.c:508
 vfs_write+0x187/0x520 fs/read_write.c:558
 SYSC_write fs/read_write.c:605 [inline]
 SyS_write+0xd4/0x1a0 fs/read_write.c:597
 entry_SYSCALL_64_fastpath+0x18/0xad
RIP: 0033:0x450a09
RSP: 002b:00007ff6efd15b68 EFLAGS: 00000216 ORIG_RAX: 0000000000000001
RAX: ffffffffffffffda RBX: 00000000006f8000 RCX: 0000000000450a09
RDX: 0000000000000090 RSI: 0000000020d09000 RDI: 0000000000000005
RBP: 0000000000000046 R08: 0000000000000000 R09: 0000000000000000
R10: 0000000000000000 R11: 0000000000000216 R12: 0000000000000000
R13: 00007ffc210fd8ff R14: 00007ff6efd16700 R15: 0000000000000000
Object at ffff88003c1f5e20, in cache kmalloc-512 size: 512
...
Dumping ftrace buffer:
   (ftrace buffer empty)
Kernel Offset: disabled
```
This is the call trace printed by kernel when kernel crashes, we can find it is a heap overflow in Sproc_write+0x64/0x90 drivers/mod_test/test.c:45.
