# Make syzkaller corpus selective

## Patch
* Coverage filter in syz-fuzzer/syz-executor
* Address region of kernel function
* Coverage of function and ID track 
* Tool for rebuilding corpus.db
* Extract syscall name from prog
* Change your fuzzer

## Coverage filter && Address of kernel function
As a coverage-guide fuzzer, syzkaller collect progs which trigger a new coverage. These progs are called corpus. So, coverage filter is actually used to determin which progs can be put into corpus. In syzkaller, after check the new coverage triggered, triageInput will minimize the prog. A prog maybe cut to several progs. Every prog trigger one or more coverage. There are three kinds of filter in our customize syzkaller( object code is what we want to test): 
* New coverage and object code are in the same prog. But it maybe cut to two progs after minimize. It means that not everyone of corpus will hit object code. [Here is a patch implement this filter in syz-fuzzer.](coverage_filter_infuzz.patch)
* New coverage and object code are in the same prog which can't be minimized. It make sure that the all the progs will hit the object code. [Here is a patch implement this kind of filter in syz-executor](coverage_filte.patch).
* New coverage and code coverage are in the same syscall. It means that only new coverage and object code appear in the same call stack, prog can be put into corpus. Actually modifying first patch can easily implement this filter

Because both syz-fuzzer and syz-excutor know nothing about target kernel binary, these filters filter coverage by address region. [Here is a tool help you list the region of a kernel function by scaning vmlinux](fun2addr.go).
In fact, the above filter is very crude. In practic, using and combining different kinds of filter( include blacklist) is more useful in different purpos fuzzer. 


## Corpus id track && syz-redb corpus
Syzkaller has web infterfaces. We extern a [corpus ids track](coverage_and_track_corpus_ids_by_funcname.patch) base on it. It can help you find out all the progs that trigger a special kernel function you want to test. Using this infterface with [syz-redb](syz-redb.go) help you easily rebuild a samll and directional corpus test you want. This is called corpus selective. 

## Extract syscall name from prog
This [tool](extract_syscall_names_from_prog.py) help you extract all the syscalls name from a set of prog. Reconfigure you syz-manager can be easier.

## Change you fuzzer algorithm
Change the Prog interface 'Mutate' to customize your prog generation.

## Use these tools to ...?
I'm not creative, it may be used as following. After a long time exploring of kernel path, We may have a large and general corpus. If you modify some code in kernel. And need to use syzkaller to test these code. First, you can use corpus id track pick out those progs hit the code you modify( a set of kernel function). Then, rebuild your corpus.db. Finally, extract syscall from this prog and fill in the config.json for syz-maneger( You may need more other syscalls check by yourself). So, you can build your partial test quickly. 
It also can be used as a auto-poc tool of kernel vulnerabilty, especailly for different version kernel. Analyse the crash log( call stack) and vulnerability report( include poc or reproduce), pickout all the prog can hit these code, crash may happen.
