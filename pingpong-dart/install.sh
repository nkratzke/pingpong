#!/bin/sh

# Installs Dart and pingpong-dart on system under test

# Install dart from the stable and official channel
sudo apt-get update
sudo apt-get install apt-transport-https
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart -y


# Install pingpong-dart
/usr/lib/dart/bin/pub install
