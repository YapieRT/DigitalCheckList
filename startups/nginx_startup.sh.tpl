#!/bin/bash

echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4

#Installing software

sudo apt update && sudo apt upgrade -y
sudo apt install nginx -y

#Adding route for connecting to database server
/usr/bin/sudo bash -c "echo ${DB_SERVER} database >> /etc/hosts"
/usr/bin/sudo bash -c "echo ${FIRST_APP_SERVER} database >> /etc/hosts"
/usr/bin/sudo bash -c "echo ${SECOND_APP_SERVER} database >> /etc/hosts"

#Configuring NGINX config

sudo cp /home/ubuntu/nginx.conf /etc/nginx/

sudo systemctl reload nginx.service