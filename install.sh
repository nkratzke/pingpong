#!/bin/sh

# Commands to set up and install dart from the stable channel
sudo apt-get update
sudo apt-add-repository ppa:hachre/dart
sudo apt-get update
apt-get install dart-sdk -y

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
