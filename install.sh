#!/bin/sh

# Commands to install dart sdk on a linux ubuntu system
apt-add-repository ppa:hachre/dart -y
apt-get update
apt-get install dartsdk -y

# Commands to install apache benchmark on a linux ubuntu system
apt-get install apache2-utils -y

# Install pingpong and dependencies
pub get

# Report finished installation
echo "Now you can run 'dart bin/ping.dart' to start the ping server"
echo "or you can run 'dart bin/pong.dart' to start the pong server."
echo "Furthermore, you can run 'run.sh' to benchmark your pingpong deployment."
