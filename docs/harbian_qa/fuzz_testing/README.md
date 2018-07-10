## syzkaller
Our community HardenedLinux wrote some documentations for syzkaller. 
This markdown arti will introduce these documentations. 

* [Syzkaller](syzkaller_general.md) tutorial( some configures need to be updated for new version syzkaller)

* [A crash demo](syzkaller_crash_demo.md), use syzkaller to detect an kernel overflow bug

* [Some kernel debug tools](syz_debug.md) are powerful to verify the hit of kernel. It help you to extend syscalls for syzkaller. 
Running syzkaller with KGDB or remote systemtap can be found in this.

* [In this directory](syz_for_ceph), as an example, I extend some syscalls for cephfs driver( ceph_iops/fops). 
And I try to verify the hit of kernel code by a (stap script)[auto_stap.py].

* [This documentation](syz_analysis.md) is the note of reading syzkaller code( "/**/" is added by me). 
Hope it can be helpful to someone who needs analyze or modify the syzkaller code. 
I am a fresh hand of golang. If there are something wrong, your correction will be very appreciate.

* [Some patch for custom syzkaller](patch). 
