echo "PostgreSQL install .../"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-11 libpq-dev postgresql-server-dev-all

cd ~/src
git clone https://github.com/0xxon/zeek-postgresql.git
cd zeek-postgresql
./configure --bro-dist=../zeek-3.0.0
make && sudo make install
sudo zeek -N Johanna::PostgreSQL


mkdir ~/src/fuzzy-hash
cd ~/src/fuzzy-hash
git clone https://github.com/ssdeep-project/ssdeep.git
cd ssdeep
./bootstrap
./configure
make
sudo make install

cd ~/src/fuzzy-hash
git clone https://github.com/trendmicro/tlsh.git
wget https://github.com/trendmicro/tlsh/archive/v3.4.5.tar.gz
tar xvf v3.4.5.tar.gz
cd tlsh-3.4.5
./make.sh
cd ~/src/fuzzy-hash/tlsh-3.4.5
sudo cp lib/lib* /usr/local/lib
cd /usr/local/lib
##https://github.com/J-Gras/bro-fuzzy-hashing/issues/2 
sudo rm -rd libtlsh.so.0
sudo ln -s libtlsh.so libtlsh.so.0
sudo ldconfig

cd ~/src/fuzzy-hash
git clone https://github.com/J-Gras/bro-fuzzy-hashing.git
cd bro-fuzzy-hashing
mkdir tlsh
cp -r ~/src/fuzzy-hash/tlsh-3.4.5/include/* tlsh/.
./configure --with-tlsh=../tlsh/include --bro-dist=$HOME/src/zeek-3.0.0
make
sudo make install
sudo zeek -N JGras::FuzzyHashing




cd ~/src
git clone https://github.com/corelight/bro-community-id.git
cd bro-community-id/
./configure --bro-dist=../zeek-3.0.0
make
sudo make install
cd ..

###
git clone https://github.com/CommunityBro/mqtt_analyzer.git
cd mqtt_analyzer
./configure --bro-dist=$HOME/src/zeek-3.0.0
make
sudo make install

cd ..
###
sudo apt-get install libnghttp2-dev
git clone https://github.com/MITRECND/bro-http2.git
git clone https://github.com/bagder/libbrotli.git
cd libbrotli
./autogen.sh
./configure.ac
./configure
make
sudo make install
cd ..
cd bro-http2/
./configure --bro-dist=$HOME/src/zeek-3.0.0
make
sudo make install


#
echo '@load packages' | sudo tee --append /usr/local/zeek/share/zeek/site/local.zeek
echo '@load /usr/local/zeek/lib/zeek/plugins/mitrecnd_HTTP2/scripts/http2/' | sudo tee --append /usr/local/zeek/share/zeek/site/local.zeek

echo '@load /usr/local/zeek/lib/zeek/plugins/mitrecnd_HTTP2/scripts/http2/intel' | sudo tee --append /usr/local/zeek/share/zeek/site/local.zeek
