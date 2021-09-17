#!/bin/bash

echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4


sudo -c export INITIAL_IP
sudo echo 'INITIAL_IP='${INITIAL_IP}''>> /etc/environment
sudo -c export NODE_ENV
sudo echo 'NODE_ENV='${NODE_ENV}''>> /etc/environment 
sudo -c export JWT
sudo echo 'JWT='${JWT}''>> /etc/environment
sudo -c export PORT
sudo echo 'PORT='${PORT}''>> /etc/environment
sudo -c export MONGO_URI
sudo echo 'MONGO_URI='${MONGO_URI}''>> /etc/environment
sudo -c export INITIAL_USERNAME
sudo echo 'INITIAL_USERNAME='${INITIAL_USERNAME}''>> /etc/environment
sudo -c export INITIAL_EMAIL
sudo echo 'INITIAL_EMAIL='${INITIAL_EMAIL}''>> /etc/environment
sudo -c export INITIAL_PASSWORD
sudo echo 'INITIAL_PASSWORD='${INITIAL_PASSWORD}''>> /etc/environment

sudo env > /root/env.tmp

#Installing software

sudo apt update && sudo apt upgrade -y
sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
sudo apt -y install nodejs -y
sudo npm install pm2@latest -g
sudo apt install apache2 -y

#Clonning software repositiries

cd /home/ubuntu
sudo bash -c 'git clone https://github.com/theyurkovskiy/digichlist-api.git'
sudo bash -c 'git clone https://github.com/theyurkovskiy/digichlist-Admin-UI.git'
sudo bash -c 'git clone https://github.com/YapieRT/confs'

#Updating apache2 conf

sudo rm /etc/apache2/apache2.conf
sudo cp /home/ubuntu/confs/apache2.conf /etc/apache2/apache2.conf
sudo a2enmod rewrite

sudo service apache2 restart

#Editing admin routes in source code for adding first admin user
sudo sed -i 's/passport\./\/\/passport\./g' /home/ubuntu/digichlist-api/routes/admin.routes.js 


#Configuring BE
cd digichlist-api
sudo npm install
sudo pm2 start server.js --name digichlist-api

#Waiting for API to start
sleep 10

#Adding admin user to api server
sudo curl --header "Content-Type: application/json" --request POST --data '{"email":"'${INITIAL_EMAIL}'","password":"'${INITIAL_PASSWORD}'","username":"'${INITIAL_USERNAME}'"}' http://127.0.0.1:5000/api/admin/registration

#Stopping application
sudo pm2 stop digichlist-api

#Removing comments from admin routes source code
cd ..
sudo sed -i 's/\/\/passport\./passport\./g' /home/ubuntu/digichlist-api/routes/admin.routes.js

#Starting BE
cd digichlist-api
sudo pm2 start server.js --name digichlist-api
cd ..

#Changing WEBUI BASEURL
sudo sed -i 's/https:\/\/digichlist-api.herokuapp.com\/api\//http:\/\/'${INITIAL_IP}':5000\/api\//g' /home/ubuntu/digichlist-Admin-UI/src/environments/environment.prod.tsx
sudo sed -i 's/https:\/\/digichlist-api.herokuapp.com\/api\//http:\/\/'${INITIAL_IP}':5000\/api\//g' /home/ubuntu/digichlist-Admin-UI/src/environments/environment.tsx


#Building FE
cd digichlist-Admin-UI
sudo npx browserslist@latest --update-db
sudo npm install caniuse-lite
sudo npm install
sudo npm run build 

#Publishing FE
sudo rm -rf /var/www/html/*
sudo mv ./build/ /var/www/html -T
sudo chown -R www-data:www-data /var/www/html
sudo cp /home/ubuntu/confs/.htaccess /var/www/html/.htaccess

#Adding startup command for application in case of reboot
sudo bash -c 'echo "@reboot /usr/bin/pm2 start /home/ubuntu/digichlist-api/server.js --name digichlist-api" >> /etc/crontab'
