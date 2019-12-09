
deb http://deb.debian.org/debian unstable main
sudo apt-get update
sudo apt-get -y install gcc-multilib libmpc-dev libgmp-dev libmpfr-dev clang llvm-dev gcc-8 g++-8
sudo apt-get install ninja-build


cd ~/src
https://github.com/actor-framework/actor-framework/archive/0.17.3.tar.gz
tar -xvf 0.17.3.tar.gz
cd actor-framework-0.17.3
./configure
cd build
make -j 4
sudo make install 

####################################################################################################################################################################################################
# /bin/bash                                                                                                                                                                                        #
# sudo apt update                                                                                                                                                                                  #
# sudo apt install -y -V apt-transport-https curl gnupg lsb-release                                                                                                                                #
# sudo tee /etc/apt/sources.list.d/backports.list <<APT_LINE                                                                                                                                       #
# deb http://deb.debian.org/debian $(lsb_release --codename --short)-backports main                                                                                                                #
# APT_LINE                                                                                                                                                                                         #
# sudo curl --output /usr/share/keyrings/apache-arrow-keyring.gpg https://dl.bintray.com/apache/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-keyring.gpg                        #
# sudo tee /etc/apt/sources.list.d/apache-arrow.list <<APT_LINE                                                                                                                                    #
# deb [arch=amd64 signed-by=/usr/share/keyrings/apache-arrow-keyring.gpg] https://dl.bintray.com/apache/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/ $(lsb_release --codename --short) main #
# deb-src [signed-by=/usr/share/keyrings/apache-arrow-keyring.gpg] https://dl.bintray.com/apache/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/ $(lsb_release --codename --short) main        #
# APT_LINE                                                                                                                                                                                         #
# curl https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -                                                                                                                             #
# sudo tee /etc/apt/sources.list.d/llvm.list <<APT_LINE                                                                                                                                            #
# deb http://apt.llvm.org/$(lsb_release --codename --short)/ llvm-toolchain-$(lsb_release --codename --short)-7 main                                                                               #
# deb-src http://apt.llvm.org/$(lsb_release --codename --short)/ llvm-toolchain-$(lsb_release --codename --short)-7 main                                                                           #
# APT_LINE                                                                                                                                                                                         #
# sudo apt update                                                                                                                                                                                  #
# sudo apt install -y -V libarrow-dev # For C++                                                                                                                                                    #
# sudo apt install -y -V libarrow-glib-dev # For GLib (C)                                                                                                                                          #
# sudo apt install -y -V libarrow-flight-dev # For Flight C++                                                                                                                                      #
# sudo apt install -y -V libplasma-dev # For Plasma C++                                                                                                                                            #
# sudo apt install -y -V libplasma-glib-dev # For Plasma GLib (C)                                                                                                                                  #
# sudo apt install -y -V libgandiva-dev # For Gandiva C++                                                                                                                                          #
# sudo apt install -y -V libgandiva-glib-dev # For Gandiva GLib (C)                                                                                                                                #
# sudo apt install -y -V libparquet-dev # For Apache Parquet C++                                                                                                                                   #
# sudo apt install -y -V libparquet-glib-dev # For Apache Parquet GLib (C)                                                                                                                         #
####################################################################################################################################################################################################


## https://tutorials.technology/tutorials/21-how-to-compile-and-install-arrow-from-source-code.html
cd ~/src


sudo apt remove -y libcurl4
sudo apt-get install libcurl4-openssl-dev

wget https://cmake.org/files/v3.16/cmake-3.16.0.tar.gz
tar xf cmake-3.16.0.tar.gz
cd cmake-3.16.0
./bootstrap --system-curl
./configure
make
sudo make install
..

git clone https://github.com/apache/thrift.git
cd thrift
./bootstrap.sh
./configure --without-php_extension --without-tests --without-qt4
make
sudo make install
..



#################################################################################################################
# sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_regex.a /usr/lib/x86_64-linux-gnu/libboost_regex-mt.a           #
# sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_system.a /usr/lib/x86_64-linux-gnu/libboost_system-mt.a         #
# sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_filesystem.a /usr/lib/x86_64-linux-gnu/libboost_filesystem-mt.a #
#################################################################################################################


wget http://apache-mirror.8birdsvideo.com/arrow/arrow-0.15.1/apache-arrow-0.15.1.tar.gz
tar -xvf apache-arrow-0.15.1.tar.gz
cd apache-arrow-0.15.1/cpp
th
cmake ..
make -j 4
sudo make install


sudo apt-get -y install g++ libboost-all-dev libncurses5-dev wget
sudo apt-get -y install libtool flex bison pkg-config g++ libssl-dev automake
conda install cython numpy
git clone https://github.com/tenzir/vast.git --recurse-submodules
cd vast
export CXX=/usr/bin/clang++-8
export CC=/usr/bin/gcc-9
git submodule update --recursive --init
./configure --with-caf=../actor-framework/build
cd build
make -j 8
sudo make install
sudo ldconfig


vast -e localhost:42000 export -e 10 ascii :addr in 10.0.0.0/8
