# Installing Bro-Osquery on Hosts #

### Compile bro-featured Osquery
Osquery cannot be built as root! Make sure you run these commands as regular user.
 
**1. Install basic requirements**  
> sudo apt-get install sudo make python ruby git bash curl

**2. Clone osquery fork**  
> cd /usr/local/src  
> sudo git clone --recursive https://github.com/iBigQ/osquery.git  
> sudo chown -R $USER:root /usr/local/src/osquery  
> cd ./osquery

**3. Prepare systems**  
This installs software packets using your packet manager to satisfy all system dependencies to compile osquery. You might want to skip this step and fall back in case step 4) fails.
> make sysprep

**4. Place osquery dependencies**  
This installs dependencies locally into a custom directory, i.e., */usr/local/osquery/*. No worries, this does not mess up with your system libraries.
> make deps  
> ./tools/provision.sh install osquery/osquery-local/caf  
> ./tools/provision.sh install osquery/osquery-local/broker

**5. Compile and install binaries**  
> SKIP_BRO=False make && sudo make install  
> sudo mkdir /var/osquery  
> sudo mkdir /etc/osquery

**6. Place init and configuration files**  
> sudo cp ./tools/deployment/osqueryd.initd /etc/init.d/osqueryd  
> sudo cp ./tools/deployment/osquery.bro.example.conf /etc/osquery/osquery.conf  
> export bro_ip="127.0.0.1" # replace by your Bro IP  
> sudo sed -i -e '/"bro_ip":/s/.*/"bro_ip": "'"${bro_ip}"'",/' /etc/osquery/osquery.conf

**7. Enable and start osquery**
> sudo systemctl enable osqueryd  
> sudo systemctl start osqueryd
