mkdir ~/src/fuzzy-hash
cd ~/src/fuzzy-hash
git clone https://github.com/ssdeep-project/ssdeep.git
cd ssdeep
./bootstrap
./configure
make
sudo make install
sudo apt-get install libtlsh-dev libfuzzy-dev
cd ~/src/fuzzy-hash
git clone https://github.com/trendmicro/tlsh.git
cd tlsh
./make.sh
cd build
cd release
make
sudo make install
cd ~/src/fuzzy-hash
git clone https://github.com/J-Gras/bro-fuzzy-hashing.git
cd bro-fuzzy-hashing
mkdir tlsh
cp -r ~/src/fuzzy-hash/tlsh/include/* tlsh/.
./configure
make
sudo make install
bro -NN JGras::FuzzyHashing




cd ~/src
git clone https://github.com/corelight/bro-community-id.git
cd bro-community-id/
./configure --bro-dist=../bro-2.6.1
make
sudo make install
cd ..

###
git clone https://github.com/CommunityBro/mqtt_analyzer.git
cd mqtt_analyzer
./configure --bro-dist=../../bro-2.6.1
make
sudo make install

cd ..
###
sudo apt-get install libnghttp2-dev
git clone https://github.com/MITRECND/bro-http2.git
git clone https://github.com/bagder/libbrotli.git
cd libbrotli
./configure.ac
./configure
make
sudo make install
cd ..
cd bro-http2/
sudo make install


#
echo '@load packages' | sudo tee --append /usr/local/bro/share/bro/site/local.bro
echo '@load /usr/local/bro/lib/bro/plugins/mitrecnd_HTTP2/scripts/http2/' | sudo tee --append /usr/local/bro/share/bro/site/local.bro

echo '@load /usr/local/bro/lib/bro/plugins/mitrecnd_HTTP2/scripts/http2/intel' | sudo tee --append /usr/local/bro/share/bro/site/local.bro
