#!/bin/sh

# Script to install dart sdk on a linux ubuntu system
apt-add-repository ppa:hachre/dart -y
apt-get update
apt-get install dartsdk -y

# Install
pub get

echo "now you can run 'dart bin/ping.dart' to start the ping server
echo "or you can run 'dart bin/pong.dart' to start the pong server