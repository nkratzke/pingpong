#!/bin/sh

# Install dart from the stable channel
sudo apt-get update
sudo apt-add-repository ppa:hachre/dart
sudo apt-get update
sudo apt-get install dartsdk -y

# Install apache benchmark, conntrack
sudo apt-get install apache2-utils conntrack -y

# Install docker
wget -qO- https://get.docker.com/ | sh

# Install weave
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/weave

# Install ping and pong and dependencies
pub install

# Report finished installation calling the start script
./start.sh