#!/bin/bash

echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4

#Installing software

sudo apt update && sudo apt upgrade -y
sudo apt install mongodb -y

#Configuring MongoDB config

sudo sed -i 's/bind_ip = 127.0.0.1/bind_ip = 0.0.0.0/g' /etc/mongodb.conf

sudo systemctl restart mongodb