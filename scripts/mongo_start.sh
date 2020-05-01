sudo apt update && sudo apt install -y mongodb
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongodb.conf
sudo systemctl restart mongodb