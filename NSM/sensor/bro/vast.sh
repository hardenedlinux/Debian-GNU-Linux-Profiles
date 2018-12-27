
deb http://deb.debian.org/debian unstable main
sudo apt-get update
sudo apt-get -y install gcc-multilib libmpc-dev libgmp-dev libmpfr-dev clang llvm-dev gcc-8 g++-8
sudo apt-get install ninja-build
git clone https://github.com/actor-framework/actor-framework.git
cd actor-framework/
./configure
cd build
make -j 4
sudo make install 

git clone https://github.com/vast-io/vast.git
cd vast
export CXX=/usr/bin/clang++-8
export CXX=/usr/bin/g++-8
export CC=/usr/bin/g++-8

./configure --with-caf=../actor-framework/build
cd build
make -j 8
sudo make install
sudo ldconfig


vast -e localhost:42000 export -e 10 ascii :addr in 10.0.0.0/8
