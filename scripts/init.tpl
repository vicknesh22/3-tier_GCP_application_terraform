sudo apt-get update
sudo apt-get install -y git
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt-get install -y nodejs
git clone https://github.com/vicknesh22/todo_node_app.git
sleep 5
cd /todo_node_app
sudo sed -i 's/localhost/${db_internal_ip}/g' config/database.js
sleep 5
npm install
node server.js