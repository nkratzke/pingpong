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

# Report finished installation
echo "Now you can run 'ping' to start the ping server"
echo "or you can run 'pong' to start the pong server."
echo "Furthermore, you can run 'run.sh' to benchmark your pingpong deployment."
