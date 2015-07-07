#!/bin/bash

# Script to start the ping and pong services
#
# 'start.sh bare pong' starts the pong server in bare mode
# 'start.sh bare ping http://<pongip>:<pongport>' starts the ping server in bare mode
# 'start.sh docker pong' starts the pong server as docker container
# 'start.sh docker ping http://<pongip>:<pongport>' starts the ping server as docker container
# 'start.sh weave pong' starts the pong server as docker container and connects it to a weave network
# 'start.sh weave ping http://<weavepongip>:<pongport> ponghostip' starts the ping server as docker container and connects it to a weave network

mode=$1
service=$2
pongip=$3
ponghostip=$4

function bare {

	case "$1"
	pong) sudo dart bin/pong.dart --port=8080
	      ;;
	
	ping) sudo dart bin/ping.dart --port=8080 -url="http://$2:8080"
		  ;;
	esac
}

function docker {

	case "$1"
	pong) sudo docker build -t pingpong .
	      sudo docker run -d -p 8080:8080 pingpong --asPong --port=8080
	      ;;
	
	ping) sudo docker build -t pingpong .
	      sudo docker run -d -p 8080:8080 pingpong --asPing --port=8080 --url="http://$2:8080"
		  ;;
	esac
}

function weave {
	case "$1"
	pong) sudo weave launch && sudo weave launch-dns
	      sudo docker build -t pingpong .
		  sudo weave run --with-dns --name=pong -d -p 8080:8080 pingpong --asPong --port=8080
		  ;;
	
	ping) sudo weave launch "$4" && sudo weave launch-dns
	      sudo docker build -t pingpong .
		  sudo weave run --with-dns --name=ping -d -p 8080:8080 pingpong --asPing --port=8080 --url="http://$3:8080"
		  ;;	
	esac
}

case "$mode" in
bare)   bare(service, pongip)
        ;;
docker) docker(service, pongip)
        ;;
weave)  weave(service, pongsdnip, ponghostip)
        ;;
esac


