#!/bin/sh

# Install dart from the stable channel
sudo apt-get update
sudo apt-add-repository ppa:hachre/dart
sudo apt-get update
sudo apt-get install dartsdk -y

# Install apache benchmark, conntrack, curl
sudo apt-get install apache2-utils conntrack curl -y

# Install Java 8
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install oracle-java8-installer -y

# Install ruby and ppbench
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
sudo chmod o+w /usr/local/rvm/gems/* --recursive
bundle install --gemfile=./ppbench/Gemfile

# Install docker
wget -qO- https://get.docker.com/ | sh

# Install weave
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/weave

# Install ping and pong and dependencies
pub install

# Report finished installation calling the start script
./start.sh