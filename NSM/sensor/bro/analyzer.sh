mkdir ~/src/fuzzy-hash
cd ~/src/fuzzy-hash
git clone https://github.com/ssdeep-project/ssdeep.git
cd ssdeep
./bootstrap
./configure
make
sudo make install
cd ..
sudo apt-get install libtlsh-dev
git clone https://github.com/trendmicro/tlsh.git
cd tlsh
./make.sh
cd build
cd release
make
sudo make install
cd ~/src/fuzzy-hash
git clone https://github.com/J-Gras/bro-fuzzy-hashing.git
cd brp-fuzzy-hashing
cp -r ~/src/fuzzy-hash/tlsh/include  .
./configure
make
sudo make install
bro -NN JGras::FuzzyHashing
