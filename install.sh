#!/bin/sh

# Update package lists
sudo apt-get update

# Install conntrack, curl
sudo apt-get install conntrack curl -y

# Install ruby and ppbench
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby
source $HOME/.rvm/scripts/rvm
bundle install --gemfile=./ppbench/Gemfile

# Install docker
curl -sSL https://get.docker.com/gpg | sudo apt-key add -
curl -sSL https://get.docker.com/ | sudo sh

# Install weave
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/weave

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