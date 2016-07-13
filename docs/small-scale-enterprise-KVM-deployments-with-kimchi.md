## Small-scale Enterprise KVM Deployments With Kimchi
##### Copyright (c) TYA
##### Homepage: http://tya.company/

#####Kimchi Project Homepage: https://kimchi-project.github.io/kimchi/
   
#####Update Repositories
```
apt-get update
```


#####Download Binary Files
```
wget https://kimchi-project.github.io/wok/downloads/wok-2.2.0-0.noarch.deb
wget https://kimchi-project.github.io/gingerbase/downloads/ginger-base-2.2.0-0.noarch.deb
wget https://kimchi-project.github.io/ginger/downloads/ginger-2.2.0-0.noarch.deb
wget https://kimchi-project.github.io/kimchi/downloads/kimchi-2.2.0-0.noarch.deb
```

#####Install Binaries and Dependencies 
```
dpkg -i wok-2.2.0-0.noarch.deb
apt-get install -f -y
dpkg -i ginger-base-2.2.0-0.noarch.deb
apt-get install -f -y
dpkg -i ginger-2.2.0-0.noarch.deb
apt-get install -f -y
dpkg -i kimchi-2.2.0-0.noarch.deb
apt-get install -f -y
```


#####Enable Swap+Memory cgroup Support and Update Grub
```
perl -pi -e 's,GRUB_CMDLINE_LINUX="(.*)"$,GRUB_CMDLINE_LINUX="$1 cgroup_enable=memory swapaccount=1",' /etc/default/grub
update-grub2
```

#####Make the Systemd profiles Debian Compatible
```
sed -i -e 's/libvirt-bin.service/libvirtd.service/g' /etc/systemd/system/wokd.service.d/ginger.conf
sed -i -e 's/libvirt-bin.service/libvirtd.service/g' /etc/systemd/system/wokd.service.d/kimchi.conf
```

#####Add admin user into sudo group
```
apt-get install sudo -y
addgroup ${USER} sudo
```

#####Enable HTTPS ONLY
```
sed -e "s/#https_only.*$/https_only\ =\ true/" \
    -e "s/#ssl_cert.*$/ssl_cert\ =\ ${PATCH to your cert}/" \
    -e "s/#ssl_key.*$/ssl_key\ =\ ${PATCH to your key}/" \
    /etc/wok/wok.conf
```

#####Reload Services
```
systemctl daemon-reload
systemctl restart wokd
```





#####REPLACEMENT Aware
######If you wanna Copy and Paste this file to a bash scripts
######Replace ${USER}/ ${PATCH to your cert}/ ${PATCH to your key} to your own value
######sed '/```/d' small-scale-enterprise-KVM-deployments-with-kimchi.md
######mv small-scale-enterprise-KVM-deployments-with-kimchi.md small-scale-enterprise-KVM-deployments-with-kimchi.sh
######bash small-scale-enterprise-KVM-deployments-with-kimchi.md
