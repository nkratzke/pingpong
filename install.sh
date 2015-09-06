#!/bin/sh

# Install dart from the stable and official channel
sudo apt-get update
sudo apt-get install apt-transport-https
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart -y

# Install apache benchmark, conntrack, curl
sudo apt-get install apache2-utils conntrack curl -y

# Install Java 8
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update
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

# Install pingpong-dart
/usr/lib/dart/bin/pub install

# Install pingpong-java
mkdir pingpong-java/bin
javac pingpong-java/src/*.java -d pingpong-java/bin

# Report finished installation calling the start script
./start.sh