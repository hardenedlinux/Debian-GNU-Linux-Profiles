# A example of fuzzing the ceph filesystem  

## Content  
1. [cephfs.txt](cephfs.txt) syscall description of syzkaller
2. [ceph_fops.stap](ceph_fops.stap),[ceph_iops.stap](ceph_iops.stap) script of systemtap, verify the hit of the ceph_*

## Step  
1. Add the extern syscalls description to syzkaller source code( sys/linux/cephfs.txt). In this example, we extern the syzkaller syscall to fuzz the file operations of ceph filesystem. Then, Rebuild it.
2. Enable these syscalls in you configure file
3. After sys-manager ran, run a systemtap script to verify the syzkaller really hit the object code:
```  
ps -aux|grep qemu|grep tcp
```  
Find out the ssh port, then:
```  
stap --remote=ssh://root@127.0.0.1:$(SSH_PORT) ceph_fops.stp
```  
Get print like this:  
```  
Stap start!
Open OK!
syz-executor0(1886) -> ceph_open
Write OK!
syz-executor0(1886) -> ceph_write_iter
Fsync OK!
syz-executor0(1886) -> ceph_fsync
Close OK!
syz-executor0(1886) -> ceph_release
llseek OK!
syz-executor0(1940) -> ceph_llseek
Flock OK!
syz-executor0(1961) -> ceph_flock
Mmap OK!
syz-executor0(1970) -> ceph_mmap
Splice read OK!
syz-executor0(2079) -> generic_file_splice_read
Read OK!
syz-executor0(2079) -> ceph_read_iter
Splice_write OK!
syz-executor0(2251) -> iter_file_splice_write
Ioctl OK!
syz-executor0(2653) -> ceph_ioctl
```  

* TODO:systemtap may be broken because of the crash of VM, you may need a automated script to rerun the systemtap with different $(PORT).

## Found bug  
[KASAN: use-after-free Read in set_page_dirty_lock](https://groups.google.com/forum/#!topic/syzkaller/w-u4MXthFoI): [fixed patch](https://www.google.com/url?q=https%3A%2F%2Fgithub.com%2Fceph%2Fceph-client%2Fcommit%2Fcfcd7a9e2d7faf5601b4731ea5a9eff7751981aa&sa=D&sntz=1&usg=AFQjCNHlwtgIgqDxoWkTpCrmDV1OfFlJ4Q)
