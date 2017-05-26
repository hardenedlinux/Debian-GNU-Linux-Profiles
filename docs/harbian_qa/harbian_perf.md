## Benchmarking PaX/Grsecurity kernel on Debian GNU/Linux

How much percentage of CPU usage are you gonna spend on security? The trade-off between performance and security is an old topic. Some performance benchmark can help us decide how we use PaX/Grsecurity features in the situational hardening. The testing environment is:

GNU/Linux distro: Debian 9 Stretch
Hardware: Intel(R) Xeon(R) CPU E3-1230 v5( Skylake), 8GB RAM, one SSD
Kernel: [PaX/Grsecurity 4.9.x](https://github.com/minipli/linux-unofficial_grsec), thanks to minipli's matainence work.
Tools: ab, stress-ng, fio
Template:
  * [Critical](https://github.com/hardenedlinux/hardenedlinux_profiles/blob/master/debian/config-4.9-grsec-critical.template): With most of PaX/Grsecurity features enabled. It will be used to protect, e.g: Ceph controller, key mgt server, etc.
  * Generic: With some of PaX/Grsecurity features enabled to gain more performance.

Compare the test results with the original Debian GNU/Linux:

* params: --cpu 4 --io 2 --vm 2 --vm-bytes 2G --timeout 300s --metrics-brief
| stress-ng       | Template       | Perf impact         |
|:---------------:|:--------------:|:-------------------:|
| CPU          	  | Critical       | ~3%                 |
| I/O             | Critical       | ~28                 |
| VM              | Critical       | N/A                 |

* params: -n 700000 -c 100 http://127.0.0.1/test.php

| ab              | Template       | Perf impact         |
|:---------------:|:--------------:|:-------------------:|
| Time taken      | Critical       | ~4%                 |
| Req/s           | Critical       | ~4%                 |
| Transfer rate   | Critical       | ~4%                 |


The [fio config file](https://github.com/hardenedlinux/hardenedlinux_profiles/blob/master/qa_test/fio-async.job) is provided by Lance W/Zhao Yuhu( zyuhu@suse.com).

| fio                       | Template       | Debian 9       | PaX/Grsecurity |
|:-------------------------:|:--------------:|:--------------:|:--------------:|
| I/Os performed            | Critical       | 137074/26514   | 135043/24854   |
| Merges in IO sched        | Critical       | 1492/45812     | 153/34948      |
| Number of tickets         | Critical       | 659904/5671904 | 701448/8006316 |
| Time consumption in queue | Critical       | 6332904        | 8713144        |
| Disk utilization          | Critical       | 99.01%         | 98.34%


* params: make -j8 deb-pkg

| Kernel comliation | Template       | Debian 9    | PaX/Grsecurity |
|:-----------------:|:--------------:|:-----------:|:---------------:|
| real              | Critical       | 25m17.713s  | 27m37.922s     |
| usr               | Critical       | 170m16.332s | 177m11.980s    |
| sys               | Critical       | 7m45.016s   | 13m5.148s      |

TODO:
   * Other template

Welcome to contribute!

### Reference

[1] [PaX/Grsecurity](https://grsecurity.net/)

[2] [Evaluate grsec's performance hit](https://labs.riseup.net/code/issues/12110)
