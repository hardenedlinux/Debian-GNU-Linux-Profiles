##Bro-Manager
sudo pip install bro-pkg
##Bro installation is owned by "root" user that was stored in /root/.bro-pkg
sudo bro-pkg autoconfig

sudo bro-pkg config script_dir
sudo bro-pkg config plugin_dir

sudo bro-pkg install https://github.com/hosom/bro-ja3
sudo bro-pkg install https://github.com/hosom/file-extraction
sudo bro-pkg install https://github.com/GTrunSec/bro-osquery-test.git
#create a bundle file which contains a snapshot of all currently installed packages:
sudo bro-pkg bundle bro-packages.bundle


sudo bro-pkg unbundle bro-packages.bundle


sudo broctl deploy



##pdns installing
wget https://dl.google.com/go/go1.11.2.linux-amd64.tar.gz
tar -xvf  go1.11.2.linux-amd64.tar.gz
sudo mv go /usr/local
echo "
export GOPATH="/home/gtrun/go"
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
export GOROOT="/usr/local/go"
"
git clone https://github.com/JustinAzoff/bro-pdns
cd bro-pdns
go build

echo "
export PDNS_STORE_TYPE="postgresql"
export PDNS_STORE_URI="postgres://pdns:foo@localhost/pdns?sslmode=disable"

# or 
export PDNS_STORE_TYPE="sqlite"
export PDNS_STORE_URI="/path/to/passivedns.sqlite"
"
