# ebpf for debian

## Kernel configure
Check if these configure are enable:
```  
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_NET_CLS_BPF=y
CONFIG_NET_ACT_BPF=y
CONFIG_BPF_JIT=y
CONFIG_HAVE_BPF_JIT=y
CONFIG_BPF_EVENTS=y
```  

## Package
```  
apt install libbpfcc python-bpfcc linux-headers-`uname -r`
```  
(Only testing has these packages.)
There are many [examples](https://github.com/iovisor/bcc.git) of ebpf. 
