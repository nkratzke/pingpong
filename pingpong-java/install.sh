#!/bin/sh

# Installs Java and pingpong-java on system under test

# Install Java 8
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install oracle-java8-installer -y

# Install pingpong-java
mkdir -p bin
javac -d bin src/*.java