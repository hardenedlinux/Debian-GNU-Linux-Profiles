# Custom syzkaller + UBSAN = Integer overflow detect

## List  
* Coverage_filter, keep the corpus focus on our object
* Insert_beginning, hardcode syscalls before the random syscalls generate by fuzzer.
* Build kernel with UBSAN enable.

## Step  
* Find out the mathematical operation that you want to QA. 
* Analyse the kernel code path to the object.
* Use [this patch](patch/coverage_filte.patch). Fill white_list with address of code path to object.
* Use [this patch](patch/insert_beginning.patch). Insert the syscalls at the beginning of 'prog' to reach the object.
* Run syz-manager.

## Example
I use syzkaller detect a UBSAN bug report:
```  
UBSAN: Undefined behaviour in /root/linux-source-4.16/net/ipv6/ip6_output.c:LINE
```  
Although kernel check the length after that. Means the bug is not a vulnerabilty. But the overflow is really happened. The overflow locate in the function `__ip6_append_data`. Suppose that we don't know the mathematical operation will overflow. We just want to verify if it will overflow in the mathematical operation in `__ip6_append_data`.

### Ayalyse the code path
We can find the `__ip6_append_data` can be reach as following:
```  
sys_sendto -> sock_sendmsg -> inet_sendmsg -> udpv6_sendmsg -> ip6_append_data -> __ip6_append_data
```  
In other case, you may need find out all the path about the object function in kernel( git grep?).  
The function is used to handle message appending from several 'sendto'. We can found setsockopt with option "UDP_CORK" can block the 'sendto' and append the later message at the end of origin message.
So, to reach `__ip6_append_data`, the userspace syscalls should be:
```  
socket(AF_INET6, SOCK_DGRAM, 0) -> setsockopt(*sk, SOL_UDP, UDP_CORK, &val, sizeof(int)) -> sendto(* , *, *, ) -> ...
```  

### Hardcode the path infomation to syzkaller
First use `nm` find out address of those kernel functions. Add them to white_list. The fuzzer will filter the coverage. The corpus only keep the 'prog' data relate to our object.  
Then, notice the `__ip6_appned_data` input only determine by several 'snedto' and their argument.
That means 'socket' and 'setsockopt' can be fixed at the beginning. So add them to 'syscallName'( prog/generation.go and prog/mutation.go）, like: 
```  
syscallName := []string{"socket$inet6", "setsockopt$inet6_UDP_CORK"}
```  
"setsockopt$inet6_UDP_CORK" add by myself: 
```  
setsockopt$inet6_UDP_CORK(fd sock_in6, level const[SOL_UDP], optname const[UDP_CORK], optval ptr[in, const[1, int32]], optlen len[optval])
```
Then enable these syscalls on .json and run syz-manager. The overflow will  be detect quickly.

## Result
| Option | Origin syzkaller | Custom syzkaller |
|--------|------------------|------------------|
| Time   | 8h( Only limit enable syscall) | < 20 min |
| Repro  | prog, prog2c can't reproduce | c prog, reproducible |  

Notice this documentation use in special case. Origin syzkaller is more general. This documentation only want to show the possible of
syzkaller.
