##Silk
cd ~/src
mkdir silk
cd silk

wget http://tools.netsa.cert.org/releases/silk-3.16.1.tar.gz
tar -xvf silk-3.16.1.tar.gz

tar -xvf silk-3.16.1.tar.gz
cd silk-3.16.1
./configure \
    --with-libfixbuf=/usr/local/lib/pkgconfig/ \
    --with-python \
    --enable-ipv6
make && sudo make install
cd ..
sudo mkdir /data/
sudo mkdir /data/silk.conf
sudo cp /usr/local/share/silk/*-silk.conf /data/silk.conf

##libfixbuf
wget http://tools.netsa.cert.org/releases/libfixbuf-1.8.0.tar.gz

tar -zxvf libfixbuf-1.8.0.tar.gz
cd libfixbuf-1.8.0
./configure && make
sudo make install
cd ..
##YAF
wget http://tools.netsa.cert.org/releases/yaf-2.9.3.tar.gz
tar -zxvf yaf-2.9.3.tar.gz
cd yaf-2.9.3
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
./configure --enable-applabel
make
sudo make install
cd ..

