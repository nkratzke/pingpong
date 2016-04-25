#!/bin/bash

# Update package lists
sudo apt-get update

# Install conntrack, curl
sudo apt-get install conntrack curl -y

# Install ruby and ppbench
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby
source $HOME/.rvm/scripts/rvm 
cd ppbench
bundle install 
rake install
cd ..

# Install docker
curl -sSL https://get.docker.com/gpg | sudo apt-key add -
curl -sSL https://get.docker.com/ | sudo sh

# Install weave
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/weave

# Install calico, etcd and prerequisites
sudo apt-get install ipset iptables socat -y
sudo wget http://www.projectcalico.org/latest/calicoctl -O /usr/local/bin/calicoctl
sudo chmod a+x /usr/local/bin/calicoctl
sudo docker pull calico/node:latest

sudo mkdir -p /opt/etcd/
sudo curl -L  https://github.com/coreos/etcd/releases/download/v2.2.1/etcd-v2.2.1-linux-amd64.tar.gz -o /opt/etcd/etcd.tar.gz
sudo tar xzvf /opt/etcd/etcd.tar.gz -C /opt/etcd/
sudo cp /opt/etcd/etcd-*/etcd* /usr/local/bin/

# Install all language modules
for module in pingpong-*;
do
	echo "Installing $module"
	cd $module
	./install.sh
	cd ..
done

# Report finished installation calling the start script
./start.sh