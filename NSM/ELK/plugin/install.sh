sudo pip install elastalert
elastalert-create-index
sudo mkdir -p /opt/elastalert/
sudo cp ./config.yaml /opt/elastalert/config.yaml
sudo cp -r ./rules /opt/elastalert/
sudo cp elastalert.service /lib/systemd/system/elastalert.service
sudo systemctl enable elastalert.service
sudo systemctl start elastalert.servic
