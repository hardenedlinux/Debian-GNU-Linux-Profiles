### Build Hardware-Accelerated Media Server with ZFS


#### Environment

OS: Debian 10
Virtualization Environment: Proxmox LXC container 
Media Server: emby-server-4.4.3.0

Memory: 4 * 16GB DDR4 2333Mhz unbuffered ECC   
Reason: We want to run ZFS, so we need ECC Memory, and we need server or workstation MotherBoard to support it.   

CPU: Intel Xeon E3 1245 v6 with HD P630   
Reason: We want to using hardware acceleration to encode and decode videos, so we need a hardware acceleration device. 
We have Intel Server CPU with integrated graphics, Nvidia graphics card with nvenc/endec support and AMD Radeon 
graphics card with Video Coding Engine 3.4 and above. For Nvdia, the cheapest option is GeForce GT 1050, this is 
not a expensive card, but power consumption need 75W, and `Max concurrent encoding sessions` only `3`, But we can 
using Patch to bypass those session limit. link:https://github.com/keylase/nvidia-patch. For AMD， the cheapest 
option to meet our need is Radeon™ RX 460, which support Video Coding Engine 3.4 and the power consumption need about 65W. 
And they need one slot of pcie to install. So we choose intel integrated graphics. According to Intel Quick Sync Video 
wiki, we know the `Kaby Lake` platform can also do H265 8bit decode and encode acceleration. So we choose cheapest one of  Xeon E3-12x5 v6 series

MotherBoard: Supermicro X11SSH-LN4F (Intel C236 chipset)   
Reason: In order to support Intel quick sync, we need Intel C2*6 chipset.

SCSI controller: LSI 9300-8I (LSI SAS3008) HBA Mode    
Reason: HBA Mode for ZFS

Ethernet Adapter: Intel X520 Dual SFP+ (Intel 82599EB)   
Hard Drive: 24 * Dell 6T Enterprise Hard Disk   
Solid Drive: 1 * Intel S3710 400G (for System), 1 * Samsung SSD 850 EVO 1T (for ZFS cache)


#### Install Proxmox

Add an `/etc/hosts` entry for your IP address

for example my hostname is `nashost`
```
127.0.0.1	localhost
192.168.1.1	nashost

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Add the Proxmox VE repository:
```
echo "deb http://mirrors.ustc.edu.cn/proxmox/debian/pve/ buster pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
```
note: you could also using official repo: `http://download.proxmox.com/debian/pve`

Add Proxmox VE repository key:
```
wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg
chmod +r /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg  # optional, if you have a non-default umask
```

update repository and system

```
apt update && apt full-upgrade
```

Install the Proxmox VE packages
```
apt install proxmox-ve postfix open-iscsi
```

##### Network Configuration  

We can simply bridge the 10G ethernet adapter `enp1s0f0` by edit `/etc/network/interface`
```
auto lo
iface lo inet loopback

auto eno4
iface eno4 inet manual
        dns-nameservers 1.1.1.1

iface eno2 inet manual

iface eno3 inet manual

iface eno1 inet manual

auto enp1s0f0
iface enp1s0f0 inet manual

auto enp1s0f1
iface enp1s0f1 inet manual

auto vmbr0
iface vmbr0 inet static
        address 192.168.1.50/20
        gateway 192.168.1.1
        bridge-ports enp1s0f0
        bridge-stp off
        bridge-fd 0
```

##### Storage

Just using local storage `/var/lib/vz`

#### Configure ZFS

We have 24 drives 6T HDD, we plan to split 2 vdev of 12 drives raidz. 
Because if we configure only one vdev with 24 drives raidz2, the rebuild progress will take a lot time.

sd[a-x]: HDD
sdz: 1TB SSD Cache

```
zpool create data raidz sda sdb sdc sdd sde sdf sdg sdh sdi sdj sdk sdl
zpool add data raidz sdm sdn sdo sdp sdq sdr sds sdt sdu sdv sdw sdx
zpool add data cache sdz
```
check zpool
```
zpool status

  pool: data
 state: ONLINE
  scan: resilvered 0B in 0 days 00:00:00 with 0 errors on Tue Sep  1 18:15:48 2020
config:

	NAME        STATE     READ WRITE CKSUM
	data        ONLINE       0     0     0
	  raidz1-0  ONLINE       0     0     0
	    sda     ONLINE       0     0     0
	    sdb     ONLINE       0     0     0
	    sdc     ONLINE       0     0     0
	    sdd     ONLINE       0     0     0
	    sde     ONLINE       0     0     0
	    sdf     ONLINE       0     0     0
	    sdg     ONLINE       0     0     0
	    sdh     ONLINE       0     0     0
	    sdi     ONLINE       0     0     0
	    sdj     ONLINE       0     0     0
	    sdk     ONLINE       0     0     0
	    sdl     ONLINE       0     0     0
	  raidz1-1  ONLINE       0     0     0
	    sdm     ONLINE       0     0     0
	    sdn     ONLINE       0     0     0
	    sdo     ONLINE       0     0     0
	    sdp     ONLINE       0     0     0
	    sdq     ONLINE       0     0     0
	    sdr     ONLINE       0     0     0
	    sds     ONLINE       0     0     0
	    sdt     ONLINE       0     0     0
	    sdu     ONLINE       0     0     0
	    sdv     ONLINE       0     0     0
	    sdw     ONLINE       0     0     0
	    sdx     ONLINE       0     0     0
	cache
	  sdz       ONLINE       0     0     0

errors: No known data errors
```
Change ZFS record size

Because we using zfs to store media data, so we can change record size to higher value to gain better performance.
```
zfs set recordsize=1M data
```

create dataset

```
zfs create data/Entertainment
zfs create data/Entertainment/Videos
```

#### Install Intel Media Driver and Compile ffmpeg With VAAPI and QSV Support

Install prerequisites

```
apt install git build-essential autoconf cmake pkg-config libdrm-dev libgl1-mesa-glx libgl1-mesa-dev xorg xorg-dev openbox libsdl2-dev libtool nasm
```

Compile and install libva

```
cd ~/
git clone https://github.com/intel/libva
cd libva
./autogen.sh
make -j"$(nproc)"
make install
```

Compile and install gmmlib

```
cd ~/
git clone https://github.com/intel/gmmlib
cd gmmlib
mkdir build && cd build
cmake ..
make -j"$(nproc)"
make install
```

Compile and install media-driver
Manually compile media-driver to access full decoding/encoding feature （VP8, HEVC 8bit, Mpeg2 Encoding support）

```
cd ~/
git clone https://github.com/intel/media-driver
mkdir build_media
cd build_media
cmake ../media-driver
make -j"$(nproc)"
make install
```

Install vainfo
```
apt install vainfo
```

Using vainfo to check media-driver Version

```
export LIBVA_DRIVERS_PATH=/usr/local/lib/dri/
export LIBVA_DRIVER_NAME=iHD
vainfo

error: XDG_RUNTIME_DIR not set in the environment.
error: can't connect to X server!
libva info: VA-API version 1.9.0
libva info: User environment variable requested driver 'iHD'
libva info: Trying to open /usr/local/lib/dri//iHD_drv_video.so
libva info: Found init function __vaDriverInit_1_9
libva info: va_openDriver() returns 0
vainfo: VA-API version: 1.9 (libva 2.4.0)
vainfo: Driver version: Intel iHD driver for Intel(R) Gen Graphics - 20.3.pre (6f6cf2b4)
vainfo: Supported profile and entrypoints
      VAProfileNone                   :	VAEntrypointVideoProc
      VAProfileNone                   :	VAEntrypointStats
      VAProfileMPEG2Simple            :	VAEntrypointVLD
      VAProfileMPEG2Simple            :	VAEntrypointEncSlice
      VAProfileMPEG2Main              :	VAEntrypointVLD
      VAProfileMPEG2Main              :	VAEntrypointEncSlice
      VAProfileH264Main               :	VAEntrypointVLD
      VAProfileH264Main               :	VAEntrypointEncSlice
      VAProfileH264Main               :	VAEntrypointFEI
      VAProfileH264Main               :	VAEntrypointEncSliceLP
      VAProfileH264High               :	VAEntrypointVLD
      VAProfileH264High               :	VAEntrypointEncSlice
      VAProfileH264High               :	VAEntrypointFEI
      VAProfileH264High               :	VAEntrypointEncSliceLP
      VAProfileVC1Simple              :	VAEntrypointVLD
      VAProfileVC1Main                :	VAEntrypointVLD
      VAProfileVC1Advanced            :	VAEntrypointVLD
      VAProfileJPEGBaseline           :	VAEntrypointVLD
      VAProfileJPEGBaseline           :	VAEntrypointEncPicture
      VAProfileH264ConstrainedBaseline:	VAEntrypointVLD
      VAProfileH264ConstrainedBaseline:	VAEntrypointEncSlice
      VAProfileH264ConstrainedBaseline:	VAEntrypointFEI
      VAProfileH264ConstrainedBaseline:	VAEntrypointEncSliceLP
      VAProfileVP8Version0_3          :	VAEntrypointVLD
      VAProfileVP8Version0_3          :	VAEntrypointEncSlice
      VAProfileHEVCMain               :	VAEntrypointVLD
      VAProfileHEVCMain               :	VAEntrypointEncSlice
      VAProfileHEVCMain               :	VAEntrypointFEI
      VAProfileHEVCMain10             :	VAEntrypointVLD
      VAProfileHEVCMain10             :	VAEntrypointEncSlice
      VAProfileVP9Profile0            :	VAEntrypointVLD
      VAProfileVP9Profile2            :	VAEntrypointVLD
```

Compile and install libmfx(MediaSDK)

```
cd ~/
git clone https://github.com/Intel-Media-SDK/MediaSDK msdk
cd msdk
mkdir build && cd build
cmake ..
make -j"$(nproc)"
make install
```

Compile FFmpeg with vaapi and libmfx(qsv) support

```
cd ~/
git clone https://github.com/ffmpeg/ffmpeg
cd ffmpeg
export LIBVA_DRIVERS_PATH=/usr/local/lib/dri/
export LIBVA_DRIVER_NAME=iHD
export LD_LIBRARY_PATH=/opt/intel/mediasdk/lib/
export PKG_CONFIG_PATH=/opt/intel/mediasdk/lib/pkgconfig/
./configure --arch=x86_64  --enable-vaapi --enable-libmfx  --enable-libdrm
make -j"$(nproc)"
make install
```
now we can using ffmpeg to check hardware acceleration feature

```
ffmpeg -hwaccels

ffmpeg version N-98974-g2a19232c19 Copyright (c) 2000-2020 the FFmpeg developers
  built with gcc 8 (Debian 8.3.0-6)
  configuration: --arch=x86_64 --enable-vaapi --enable-libmfx
  libavutil      56. 58.100 / 56. 58.100
  libavcodec     58.101.101 / 58.101.101
  libavformat    58. 51.101 / 58. 51.101
  libavdevice    58. 11.101 / 58. 11.101
  libavfilter     7. 87.100 /  7. 87.100
  libswscale      5.  8.100 /  5.  8.100
  libswresample   3.  8.100 /  3.  8.100
Hardware acceleration methods:
vaapi
qsv
```
check qsv decoder

```
ffmpeg -decoders | grep qsv

ffmpeg version N-98974-g2a19232c19 Copyright (c) 2000-2020 the FFmpeg developers
  built with gcc 8 (Debian 8.3.0-6)
  configuration: --arch=x86_64 --enable-vaapi --enable-libmfx
  libavutil      56. 58.100 / 56. 58.100
  libavcodec     58.101.101 / 58.101.101
  libavformat    58. 51.101 / 58. 51.101
  libavdevice    58. 11.101 / 58. 11.101
  libavfilter     7. 87.100 /  7. 87.100
  libswscale      5.  8.100 /  5.  8.100
  libswresample   3.  8.100 /  3.  8.100
 V....D h264_qsv             H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 (Intel Quick Sync Video acceleration) (codec h264)
 V....D hevc_qsv             HEVC (Intel Quick Sync Video acceleration) (codec hevc)
 V....D mjpeg_qsv            MJPEG video (Intel Quick Sync Video acceleration) (codec mjpeg)
 V....D mpeg2_qsv            MPEG-2 video (Intel Quick Sync Video acceleration) (codec mpeg2video)
 V....D vc1_qsv              VC-1 video (Intel Quick Sync Video acceleration) (codec vc1)
 V....D vp8_qsv              VP8 video (Intel Quick Sync Video acceleration) (codec vp8)
 V....D vp9_qsv              VP9 video (Intel Quick Sync Video acceleration) (codec vp9)
```
check qsv encoder
```
ffmpeg -encoders | grep qsv

ffmpeg version N-98974-g2a19232c19 Copyright (c) 2000-2020 the FFmpeg developers
  built with gcc 8 (Debian 8.3.0-6)
  configuration: --arch=x86_64 --enable-vaapi --enable-libmfx
  libavutil      56. 58.100 / 56. 58.100
  libavcodec     58.101.101 / 58.101.101
  libavformat    58. 51.101 / 58. 51.101
  libavdevice    58. 11.101 / 58. 11.101
  libavfilter     7. 87.100 /  7. 87.100
  libswscale      5.  8.100 /  5.  8.100
  libswresample   3.  8.100 /  3.  8.100
 V..... h264_qsv             H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 (Intel Quick Sync Video acceleration) (codec h264)
 V..... hevc_qsv             HEVC (Intel Quick Sync Video acceleration) (codec hevc)
 V..... mjpeg_qsv            MJPEG (Intel Quick Sync Video acceleration) (codec mjpeg)
 V..... mpeg2_qsv            MPEG-2 video (Intel Quick Sync Video acceleration) (codec mpeg2video)
 V..... vp9_qsv              VP9 video (Intel Quick Sync Video acceleration) (codec vp9)
```

#### Emby server with LXC container

Login to proxmox web pannel to create a privilege container(uncheck the `unprivileaged container box`)
In my example the container id is `101`   

edit `/etc/pve/lxc/101.conf` add following contents to mount `/dev/dri/*` into container
```
lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file
lxc.mount.entry: /dev/dri/controlD64 dev/dri/controlD64 none bind,optional,create=file
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.cgroup.devices.allow: c 226:* rwm
```
add following contents to mount zfs dataset into container as emby library

```
mp0: /data/Entertainment/Videos,mp=/data/Entertainment/Videos
```

##### Install and configure emby-server

Start container and login

```
apt install vainfo
```
Install vainfo will also install free kernel version `media-driver`

```
vainfo 

error: XDG_RUNTIME_DIR not set in the environment.
error: can't connect to X server!
libva info: VA-API version 1.4.0
libva info: va_getDriverName() returns 0
libva info: Trying to open /usr/lib/x86_64-linux-gnu/dri/i965_drv_video.so
libva info: Found init function __vaDriverInit_1_4
libva info: va_openDriver() returns 0
vainfo: VA-API version: 1.4 (libva 2.4.0)
vainfo: Driver version: Intel i965 driver for Intel(R) Kaby Lake - 2.3.0
vainfo: Supported profile and entrypoints
      VAProfileMPEG2Simple            : VAEntrypointVLD
      VAProfileMPEG2Simple            : VAEntrypointEncSlice
      VAProfileMPEG2Main              : VAEntrypointVLD
      VAProfileMPEG2Main              : VAEntrypointEncSlice
      VAProfileH264ConstrainedBaseline: VAEntrypointVLD
      VAProfileH264ConstrainedBaseline: VAEntrypointEncSlice
      VAProfileH264ConstrainedBaseline: VAEntrypointEncSliceLP
      VAProfileH264Main               : VAEntrypointVLD
      VAProfileH264Main               : VAEntrypointEncSlice
      VAProfileH264Main               : VAEntrypointEncSliceLP
      VAProfileH264High               : VAEntrypointVLD
      VAProfileH264High               : VAEntrypointEncSlice
      VAProfileH264High               : VAEntrypointEncSliceLP
      VAProfileH264MultiviewHigh      : VAEntrypointVLD
      VAProfileH264MultiviewHigh      : VAEntrypointEncSlice
      VAProfileH264StereoHigh         : VAEntrypointVLD
      VAProfileH264StereoHigh         : VAEntrypointEncSlice
      VAProfileVC1Simple              : VAEntrypointVLD
      VAProfileVC1Main                : VAEntrypointVLD
      VAProfileVC1Advanced            : VAEntrypointVLD
      VAProfileNone                   : VAEntrypointVideoProc
      VAProfileJPEGBaseline           : VAEntrypointVLD
      VAProfileJPEGBaseline           : VAEntrypointEncPicture
      VAProfileVP8Version0_3          : VAEntrypointVLD
      VAProfileHEVCMain               : VAEntrypointVLD
      VAProfileHEVCMain10             : VAEntrypointVLD
      VAProfileVP9Profile0            : VAEntrypointVLD
      VAProfileVP9Profile2            : VAEntrypointVLD
```
we don't need hevc 8bit encoding in emby-server, because hevc 8bit encoding is so slow (low transcoding fps), and emby-server only support `h264` for encoding.
So free kernel version media-server is enough.

Download and Install emby-server
```
wget https://github.com/MediaBrowser/Emby.Releases/releases/download/4.4.3.0/emby-server-deb_4.4.3.0_amd64.deb
sudo dpkg -i emby-server-deb_4.4.3.0_amd64.deb
```
add emby to video group, so emby have permission to access /dev/dri/*
```
sudo usermod -a -G video emby
chown root:video /dev/dri/renderD128
```
check library path in container

```
mount | grep data
data/Entertainment/Videos on /data/Entertainment/Videos type zfs (rw,xattr,noacl)
```

We can enjoy emby-server from now.


Reference:

https://github.com/Intel-Media-SDK/MediaSDK/wiki/Build-and-use-ffmpeg-with-MediaSDK   
https://en.wikipedia.org/wiki/Intel_Quick_Sync_Video   
https://trac.ffmpeg.org/wiki/HWAccelIntro  
https://developer.nvidia.com/video-encode-decode-gpu-support-matrix   
https://github.com/obsproject/obs-amd-encoder/wiki/Hardware-Support   
https://en.wikipedia.org/wiki/Video_Coding_Engine   
https://www.elpamsoft.com/?p=Plex-Hardware-Transcoding   
https://forums.servethehome.com/index.php?threads/issue-with-e3-1245-v6-igpu-on-x11ssm-f.16819/   
