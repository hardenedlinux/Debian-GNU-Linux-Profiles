
# Table of Contents

1.  [Topology](#org561a0b3)
2.  [ELK materials](#orga6e6c8c)
    1.  [Basic ELK<sub>System</sub> installation](#org257d396)
        1.  [[Doc] Debian-GNU-Linux-Profiles/ELK<sub>with</sub><sub>bro</sub><sub>ID</sub><sub>doc.mkd</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](#org8a629f6)
        2.  [[Install] Debian-GNU-Linux-Profiles/ELK<sub>INSTALL.sh</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](#orgd15dd10)
        3.  [[Conf] Debian-GNU-Linux-Profiles/NSM/ELK/conf at master · hardenedlinux/Debian-GNU-Linux-Profiles](#orgb095e29)
        4.  [[plugin] Debian-GNU-Linux-Profiles/NSM/ELK/plugin at master · hardenedlinux/Debian-GNU-Linux-Profiles](#org2dd4d8e)
    2.  [Bro-script Repo](#org5081011)
        1.  [hardenedlinux/hardenedlinux-bro-script](#org07e974f)
    3.  [Bro-Components](#org00c8c02)
        1.  [Bro-osquery](#org9f40226)
        2.  [Pdns](#org1840c3b)
        3.  [Debugging-bro-script](#org34b6654)
        4.  [Quickly bro-script-test-environment](#orgb3d0b09)
    4.  [Osquery-koild](#orgb3a5b73)
        1.  [Debian-GNU-Linux-Profiles/NSM/Osquery at master · hardenedlinux/Debian-GNU-Linux-Profiles](#orgbe74fba)
    5.  [Snort & suricata & Clamav](#org2f74597)
        1.  [[Install] Debian-GNU-Linux-Profiles/Sensor<sub>INSTALL.sh</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](#org1538867)
        2.  [[Doc]  Debian-GNU-Linux-Profiles/check<sub>list.org</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](#org1dd9957)
        3.  [[Demo-rules] Debian-GNU-Linux-Profiles/NSM/sensor/suricata/rules at master · hardenedlinux/Debian-GNU-Linux-Profiles](#org610c1f6)
    6.  [Silk](#org07673b2)
        1.  [[Doc] Debian-GNU-Linux-Profiles/SilkBasic.org at master · hardenedlinux/Debian-GNU-Linux-Profiles](#org75f2269)
        2.  [[Install] Debian-GNU-Linux-Profiles/Silk<sub>INSTALL.sh</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](#org43323d3)
    7.  [Vast](#org3f81081)
        1.  [[Ref] VAST - Home](#orged4ae17)
        2.  [[Install] Debian-GNU-Linux-Profiles/vast.sh at master · hardenedlinux/Debian-GNU-Linux-Profiles](#orgc0c81ba)


<a id="org561a0b3"></a>

# Topology

![img](docs/image/topo.png)


<a id="orga6e6c8c"></a>

# ELK materials

<div class="UML">
Alice -> Bob: Authentication Request
Bob &#x2013;> Alice: Authentication Response

</div>


<a id="org257d396"></a>

## Basic ELK<sub>System</sub> installation


<a id="org8a629f6"></a>

### [Doc] [Debian-GNU-Linux-Profiles/ELK<sub>with</sub><sub>bro</sub><sub>ID</sub><sub>doc.mkd</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/docs/ELK_with_bro_ID_doc.mkd)


<a id="orgd15dd10"></a>

### [Install] [Debian-GNU-Linux-Profiles/ELK<sub>INSTALL.sh</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/ELK_INSTALL.sh)


<a id="orgb095e29"></a>

### [Conf] [Debian-GNU-Linux-Profiles/NSM/ELK/conf at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/NSM/ELK/conf)


<a id="org2dd4d8e"></a>

### [plugin] [Debian-GNU-Linux-Profiles/NSM/ELK/plugin at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/NSM/ELK/plugin)


<a id="org5081011"></a>

## Bro-script Repo


<a id="org07e974f"></a>

### [hardenedlinux/hardenedlinux-bro-script](https://github.com/hardenedlinux/hardenedlinux-bro-script)


<a id="org00c8c02"></a>

## Bro-Components


<a id="org9f40226"></a>

### Bro-osquery

1.  [Install] [Debian-GNU-Linux-Profiles/bro-osquery.sh at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/Osquery/bro-osquery.sh)


<a id="org1840c3b"></a>

### Pdns

1.  [Install] [Debian-GNU-Linux-Profiles/bro-pkg&pdns.sh at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/sensor/bro/bro-pkg%2526pdns.sh)


<a id="org34b6654"></a>

### Debugging-bro-script

1.  [Doc] [Debian-GNU-Linux-Profiles/bro-debug.org at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/sensor/bro/bro-debug.org)


<a id="orgb3d0b09"></a>

### Quickly bro-script-test-environment

1.  [Doc] [Debian-GNU-Linux-Profiles/bro<sub>script.md</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/sensor/bro/bro_script.md)


<a id="orgb3a5b73"></a>

## Osquery-koild


<a id="orgbe74fba"></a>

### [Debian-GNU-Linux-Profiles/NSM/Osquery at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/NSM/Osquery)


<a id="org2f74597"></a>

## Snort & suricata & Clamav


<a id="org1538867"></a>

### [Install] [Debian-GNU-Linux-Profiles/Sensor<sub>INSTALL.sh</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/sensor/Sensor_INSTALL.sh)


<a id="org1dd9957"></a>

### [Doc] [ Debian-GNU-Linux-Profiles/check<sub>list.org</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/sensor/suricata/check_list.org)


<a id="org610c1f6"></a>

### [Demo-rules] [Debian-GNU-Linux-Profiles/NSM/sensor/suricata/rules at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/tree/master/NSM/sensor/suricata/rules)


<a id="org07673b2"></a>

## Silk


<a id="org75f2269"></a>

### [Doc] [Debian-GNU-Linux-Profiles/SilkBasic.org at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/silk/SilkBasic.org)


<a id="org43323d3"></a>

### [Install] [Debian-GNU-Linux-Profiles/Silk<sub>INSTALL.sh</sub> at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/silk/Silk_INSTALL.sh)


<a id="org3f81081"></a>

## Vast


<a id="orged4ae17"></a>

### [Ref] [VAST - Home](http://vast.io/)


<a id="orgc0c81ba"></a>

### [Install] [Debian-GNU-Linux-Profiles/vast.sh at master · hardenedlinux/Debian-GNU-Linux-Profiles](https://github.com/hardenedlinux/Debian-GNU-Linux-Profiles/blob/master/NSM/sensor/bro/vast.sh)

