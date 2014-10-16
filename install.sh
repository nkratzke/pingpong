#!/bin/sh

# Commands to set up and install dart from the stable channel
sudo apt-get update
sudo apt-get install apt-tansport-https
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
apt-get install dart -y

# Commands to install apache benchmark
apt-get install apache2-utils -y

# Install ping and pong and dependencies
pub install
pub global activate ping
pub global activate pong

# Report finished installation
echo "Now you can run 'ping' to start the ping server"
echo "or you can run 'pong' to start the pong server."
echo "Furthermore, you can run 'run.sh' to benchmark your pingpong deployment."
