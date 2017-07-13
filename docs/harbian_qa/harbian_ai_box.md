## Deploy the CUDA/cuDNN/Tensorflow/Keras on Debian 9 with PaX/Grsecurity

* OS: GNU/Linux distro: Debian 9 Stretch
* Hardware: Intel(R) Xeon(R) CPU E3-1230 v5( Skylake), 8GB RAM, 500G SSD, GeForce GTX 970
* Kernel: [PaX/Grsecurity 4.9.x](https://github.com/minipli/linux-unofficial_grsec)
* Software: CUDAv8.0, cuDNNv6.0, Keras
* PaX/Grsecurity template:
  * [CUDA](https://github.com/hardenedlinux/hardenedlinux_profiles/blob/master/debian/config-4.9-grsec-cuda.template)
  * PAX_RANDMMAP flag
  * Disable GRKERNSEC_SYSFS_RESTRICT if your programs doesn't run as root, grsec_sysfs_restrict=0
  * Nvidia module is not compatible with the KERNEXEC 'or' method and RAP
  * "groupadd -g 1001 grsec; usermod -a -G grsec username" if the program need to access /proc

## Install nvidia-driver & CUDA
Add non-free repo:
<pre>
#cat /etc/apt/sources.list
## NVIDIA CUDA
deb  http://deb.debian.org/debian stretch main contrib non-free
deb-src  http://deb.debian.org/debian stretch main contrib non-free

deb  http://deb.debian.org/debian stretch-updates main contrib non-free
deb-src  http://deb.debian.org/debian stretch-updates main contrib non-free

deb http://security.debian.org/ stretch/updates main contrib non-free
deb-src http://security.debian.org/ stretch/updates main contrib non-free
</pre>

Install the Nvidia's driver and CUDA toolkit:
<pre>
apt-get install nvidia-cuda-dev nvidia-cuda-toolkit  nvidia-driver nvidia-kernel-dkms 
</pre>

The building stage of kernel module will fail and you should [apply this patch](https://github.com/hardenedlinux/hardenedlinux_profiles/blob/master/debian/grsec-nvidia-375.66.patch) to the LKM at first and then:
<pre>
dkms status
dkms autoinstall -m nvidia -v 375.66

# or remove: dkms remove -m nvidia -v 375.66 --al
</pre>

## Install the Tensorflow/cuDNN/Keras:

Install the required packages by Tensorflow:
<pre>
apt-get install -y libcupti-dev python-pip python-dev python-numpy python-scipy python-yaml libhdf5-serial-dev
</pre>

Download cuDNN( [v5.0](https://developer.nvidia.com/rdp/assets/cudnn-8.0-linux-x64-v5.0-ga-tgz) or [v6.0](https://developer.nvidia.com/compute/machine-learning/cudnn/secure/v6/prod/8.0_20170427/cudnn-8.0-linux-x64-v6.0-tgz)) and then install it:
<pre>
tar xvf cudnn-8.0-linux-x64-v6.0.tgz
mv cuda/include /usr/local/
mv cuda/lib64 /usr/local/
cd /usr/local/lib64
ln -s libcudnn.so.6.* libcudnn.so.5
</pre>

Install the Tensorflow:
<pre>
pip install tensorflow-gpu
</pre>

Install the Keras:
<pre>
git clone https://github.com/fchollet/keras.git
cd keras/
sudo python setup.py install
</pre>

## Validation:
<pre>
export LD_LIBRARY_PATH=/usr/local/lib64/
RUN THE TEST PROGRAM!
</pre>

## Benchark
You can [compile the tensorflow manually](https://www.tensorflow.org/install/install_sources) for running [cifar10 example](https://github.com/tobigithub/tensorflow-deep-learning/wiki/cifar10-example).


TODO:
   * ???

Welcome to contribute!

### Reference

[1] [PaX/Grsecurity](https://grsecurity.net/)

[2] [Keras](https://keras.io/#getting-started-30-seconds-to-keras)

[3] [Installing TensorFlow on Ubuntu](https://www.tensorflow.org/install/install_linux)

[4] [Debian NVIDIA Proprietary Driver](https://wiki.debian.org/NvidiaGraphicsDrivers)

[5] [NVIDIA CUDA Installation Guide for Linux](http://docs.nvidia.com/cuda/cuda-installation-guide-linux/#system-requirements)
