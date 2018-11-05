# CBMC for kernel testcase
[CBMC](http://www.cs.cmu.edu/~modelcheck/cbmc/) is a Bound Model Checker for C and C++ programs. It can use to verify array bounds(buffer overflows), pointer safety, exception and testcase generation. Actually, CBMC invoke preprocesser and then analyse the syntax tree. And it finally generate the result which include several function-level testcases from the static analysis.
In my case, I need a tool which can automatically generate test case for any kernel functions. But CBMC is designed for user-space program. In this documentation, I will share a way to use CBMC to generate kernel function testcase to you. It is not the only way to do this.

## CBMC on debian9
### Install
```  
apt install cbmc
```  
### Build by yourself
Customizing CBMC is need for fitting kernel. Build it from source by:
```  
apt install maven
make -C src minisat2-download
make -C jbmc/src setup-submodules
make -C src CXX="g++" -j2
make -C unit CXX="g++" -j2
make -C jbmc/src CXX="g++" -j2
make -C jbmc/unit CXX="g++" -j2
```  

## CBMC for kernel
### DDVerify
[DDVerify](http://www.cprover.org/ddverify/) is tool for checking Linux device drivers for specific bugs. DDVerify use CBMC/SATABS as its core. Because CBMC is designed for user-space program, to analyse the kernel module, DDVerify try to make a module looks like a user-space program. You have to move the kernel code and header used by your module from kernel tree. A driver sample 'cs5535_gpio' under DDVerify src, we can run:
```  
bin/ddverify --cbmc --ddv-path ./ --driver-type char case_studies/char/cs5535_gpio/cs5535_gpio.c --module-init cs5535_gpio_init --module-exit cs5535_gpio_cleanup
```  
Then, you will find a '__main.c' file and a 'ddv_cbmc' file under the '--ddv-path'. '__main.c' specify the entry of the module, and 'ddv_cbmc' is a script directly use the command 'cmbc' to analyse the driver code.
Inspired by DDVerify, I try to extract the compiler command from kernel module build. And then use CBMC analyse the module code directly.

### kernel build & GCC options

#### Extract the compile command from kernel module build
Add the this line to Makefile under your kernel build tree:
```  
MAKEFLAGS += -n
```  
Run 'make' to build you out-of-tree kernel module. In my case, the output is:  
```  
gcc -Wp,-MD,/root/kprobe/.ioctl.o.d  -nostdinc -isystem /usr/lib/gcc/x86_64-linux-gnu/8/include -I/root/linux-source-4.17/arch/x86/include -I./arch/x86/include/generated  -I/root/linux-source-4.17/include -I./include -I/root/linux-source-4.17/arch/x86/include/uapi -I./arch/x86/include/generated/uapi -I/root/linux-source-4.17/include/uapi -I./include/generated/uapi -include /root/linux-source-4.17/include/linux/kconfig.h -include /root/linux-source-4.17/include/linux/compiler_types.h  -I/root/kprobe -I/root/kprobe -D__KERNEL__ -DCONFIG_CC_STACKPROTECTOR -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -fshort-wchar -Werror-implicit-function-declaration -Wno-format-security -std=gnu89 -fno-PIE -DCC_HAVE_ASM_GOTO -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -mno-avx -m64 -falign-jumps=1 -falign-loops=1 -mno-80387 -mno-fp-ret-in-387 -mpreferred-stack-boundary=3 -mskip-rax-setup -mtune=generic -mno-red-zone -mcmodel=kernel -funit-at-a-time -DCONFIG_X86_X32_ABI -DCONFIG_AS_CFI=1 -DCONFIG_AS_CFI_SIGNAL_FRAME=1 -DCONFIG_AS_CFI_SECTIONS=1 -DCONFIG_AS_FXSAVEQ=1 -DCONFIG_AS_SSSE3=1 -DCONFIG_AS_CRC32=1 -DCONFIG_AS_AVX=1 -DCONFIG_AS_AVX2=1 -DCONFIG_AS_AVX512=1 -DCONFIG_AS_SHA1_NI=1 -DCONFIG_AS_SHA256_NI=1 -pipe -Wno-sign-compare -fno-asynchronous-unwind-tables -mindirect-branch=thunk-extern -mindirect-branch-register -DRETPOLINE -fno-delete-null-pointer-checks -Wno-frame-address -Wno-format-truncation -Wno-format-overflow -Wno-int-in-bool-context -O2 --param=allow-store-data-races=0 -Wframe-larger-than=2048 -fstack-protector-strong -Wno-unused-but-set-variable -Wno-unused-const-variable -fno-var-tracking-assignments -g -pg -mfentry -DCC_USING_FENTRY -Wdeclaration-after-statement -Wno-pointer-sign -fno-strict-overflow -fno-merge-all-constants -fmerge-constants -fno-stack-check -fconserve-stack -Werror=implicit-int -Werror=strict-prototypes -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -fmacro-prefix-map=/root/linux-source-4.17/= -Wno-packed-not-aligned -fsanitize=kernel-address -fasan-shadow-offset=0xdffffc0000000000 --param asan-globals=1 --param asan-instrumentation-with-call-threshold=10000 --param asan-stack=1 --param asan-instrument-allocas=1 -fsanitize-address-use-after-scope -fsanitize-coverage=trace-pc -fsanitize-coverage=trace-cmp  -DMODULE  -DKBUILD_BASENAME='"ioctl"' -DKBUILD_MODNAME='"ioctl"' -c -o /root/kprobe/.ioctl.o /root/kprobe/ioctl.c
```  
'/root/kprobe/ioctl.c' is my module code. '/root/linux-source-4.17' is the kernel source code.

#### Add GCC options for CBMC
CBMC use gcc as preprocesser. But CBMC seems not to support gcc option '-include' which used by kernel module build. Modify this line to src/cbmc/cbmc_parse_options.h:
```  
-  "D:I:(c89)(c99)(c11)(cpp98)(cpp03)(cpp11)" 
+  "D:I:(include):(c89)(c99)(c11)(cpp98)(cpp03)(cpp11)" 
```  
There are also several special options should be used, we hardcode to the command generated by CBMC:
```  
--- a/src/ansi-c/c_preprocess.cpp
+++ b/src/ansi-c/c_preprocess.cpp
@@ -527,6 +529,14 @@ bool c_preprocess_gcc_clang(
   else
     argv.push_back("gcc");
 
+  /* add option by me */
+  argv.push_back("-Wp,-MD,/root/kprobe/.ioctl.o.d");
+  argv.push_back("-isystem /usr/lib/gcc/x86_64-linux-gnu/8/include");
+  argv.push_back("-fno-PIE");
+  argv.push_back("-fno-strict-aliasing");
+  argv.push_back("-fno-common");
```  
### A kernel module testcase generation
Then run the command like:
```  
cbmc ../../kprobe/ioctl.c -gcc -cover mcdc -LP64 -arch x86_64 --c11  --unwind 4 --unwindset 4 -I/root/linux-source-4.17/arch/x86/include -I/root/syz-4.17/arch/x86/include/generated -I/root/linux-source-4.17/include -I/root/syz-4.17/include -I/root/linux-source-4.17/arch/x86/include/uapi -I/root/syz-4.17/arch/x86/include/generated/uapi -I/root/linux-source-4.17/include/uapi -I/root/syz-4.17/include/generated/uapi -include /root/linux-source-4.17/include/linux/kconfig.h -include /root/linux-source-4.17/include/linux/compiler_types.h -I/root/kprobe -I/root/kprobe -D__KERNEL__ -DCONFIG_CC_STACKPROTECTOR -DCC_HAVE_ASM_GOTO -DCONFIG_X86_X32_ABI -DCONFIG_AS_CFI=1 -DCONFIG_AS_CFI_SIGNAL_FRAME=1 -DCONFIG_AS_CFI_SECTIONS=1 -DCONFIG_AS_FXSAVEQ=1 -DCONFIG_AS_SSSE3=1 -DCONFIG_AS_CRC32=1 -DCONFIG_AS_AVX=1 -DCONFIG_AS_AVX2=1 -DCONFIG_AS_AVX512=1 -DCONFIG_AS_SHA1_NI=1 -DCONFIG_AS_SHA256_NI=1 -DRETPOLINE -DCC_USING_FENTRY -DMODULE -DKBUILD_BASENAME='"ioctl"' -DKBUILD_MODNAME='"ioctl"'  --function etx_ioctl
```  
The result:
```  
# Some output is hidden
...

Test suite:
case:
file=((struct file {...}, cmd=549216u, arg=0ul
case:
file=((struct file {...}, cmd=1074291041u, arg=0ul
case:
file=((struct file {...}, cmd=2148032866u, arg=0ul

...
```  

### Other
* CBMC testcase for pointer is wrong
* Dynamic data analysis is impossible
