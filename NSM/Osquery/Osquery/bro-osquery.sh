echo"#if got this isuee with pip
#File "/usr/bin/pip", line 9, in <module>
#from pip import main
#ImportError: cannot import name main
 run hash -d pip "


sudo pip install --user --upgrade pip
hash -d pip
pip install --user --upgrade pip
sudo apt-get install ruby-dev build-essential doxygen
#acquire the fpm package itself by typing:
# ensure you have installed broker, if not then run ELK_INSTALL.sh
sudo gem install fpm

git clone --recursive https://github.com/iBigQ/osquery
cd osquery
make deps
SKIP_BRO=False make && sudo make install

sudo cp osqueryd.service /etc/systemd/system/

sudo mkdir /var/osquery/
sudo mkdir /etc/osquery/
## copy configuration files and send bro_ip to init file
sudo cp ./tools/deployment/osquery.bro.example.conf /etc/osquery/osquery.conf
sudo sed -i -e '/"bro_ip":/s/.*/"bro_ip": "'"${bro_ip}"'",/' /etc/osquery/osquery.conf


##load Bro-osquery script to framworkds [[https://www.bro.org/sphinx/quickstart/index.html#telling-bro-which-scripts-to-load][Quick Start Guide — Bro 2.6 documentation]]

sudo sh -c 'echo "@load packages" >> /usr/local/bro/share/bro/site/local.bro'
sudo broctl deploy

##check whereis osqueryd, adding osqueryd service .
sudo systemctl daemon-reload
sudo systemctl enable osqueryd
sudo systemctl start osqueryd
echo "if you can't loaded serice, plz check osqueryd dir-path. then modify sudo emacs /etc/init.d/osqueryd find in if [ -z $EXEC ]; then EXEC=/usr/local/bin/osqueryd; "
