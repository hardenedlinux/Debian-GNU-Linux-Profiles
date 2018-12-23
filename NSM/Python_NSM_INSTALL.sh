mkdir ~/src/nsm-plugin
cd ~/src/bro-plugin
wget https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh
sudo bash Anaconda3-5.2.0-Linux-x86_64.sh -b  -p /opt/anaconda/
sudo ln -s /opt/anaconda/bin/conda /usr/bin/
conda create --name python3.6 python=3.6
pip install --upgrade pip
conda install matplotlib pyspark docopt jinja2
sudo apt-get install python-tk
pip install jupyte bat
sudo apt-get install python-broccoli
sudo apt-get install broccoli
sudo apt-get install bison
wget https://www.bro.org/downloads/binpac-0.48.tar.gz
tar -xvf binpac-0.48.tar.gz
cd binpac-0.48/
./configure
make
sudo make install
cd ..
sudo pip install docopt jinji2
git clone https://github.com/grigorescu/binpac_quickstart.git
#Suricata
##Updating rules
sudo apt-get install python-yaml
sudo -H pip installl --pre --upgrade suricata-update


