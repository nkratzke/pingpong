#!/bin/bash

# Script to start the ping and pong services
#
# 'start.sh bare pong' starts the pong server in bare mode
# 'start.sh bare ping <pongip>' starts the ping server in bare mode
# 'start.sh docker pong' starts the pong server as docker container
# 'start.sh docker ping <pongip>' starts the ping server as docker container
# 'start.sh weave pong' starts the pong server as docker container and connects it to a weave network
# 'start.sh weave ping <pongip> <ponghostip>' starts the ping server as docker container and connects it to a weave network

mode=$1
service=$2
pongip=$3
ponghostip=$4

function bare {
	case "$service" in
	pong) sudo dart bin/pong.dart --port=8080 ;;
	ping) sudo dart bin/ping.dart --port=8080 --url="http://$pongip:8080" ;;
	
	pong-java) sudo java -cp pingpong-java/bin Pong 8080 ;;
	ping-java) sudo java -cp pingpong-java/bin Ping 8080 $pongip 8080 ;;
	
	esac
}

function docker {
	case "$service" in
	pong) sudo docker build -t pingpong .
	      sudo docker run -d -p 8080:8080 pingpong --asPong --port=8080
	      ;;
	
	ping) sudo docker build -t pingpong .
	      sudo docker run -d -p 8080:8080 pingpong --asPing --port=8080 --url="http://$pongip:8080"
		  ;;
	esac
}

function weave {
	case "$service" in
	pong) sudo weave launch && sudo weave launch-dns
	      sudo docker build -t pingpong .
		  sudo weave run --with-dns --name=pong -d -p 8080:8080 pingpong --asPong --port=8080
		  ;;
	
	ping) sudo weave launch "$ponghostip" && sudo weave launch-dns
	      sudo docker build -t pingpong .
		  sudo weave run --with-dns --name=ping -d -p 8080:8080 pingpong --asPing --port=8080 --url="http://$pongip:8080"
		  ;;	
	esac
}

function usage {
	echo "'start.sh bare {lang}_pong' starts the pong server in bare mode"
	echo "'start.sh bare {lang}_ping <pongip>' starts the ping server in bare mode"
	echo "'start.sh docker {lang}_pong' starts the pong server as docker container"
	echo "'start.sh docker {lang}_ping <pongip>' starts the ping server as docker container"
	echo "'start.sh weave {lang}_pong' starts the pong server as docker container and connects it to a weave SDN network"
	echo "'start.sh weave {lang}_ping <pongip> <ponghostip>' starts the ping server as docker container and connects it to a weave SDN network"
    echo ""
	echo "{lang} can be one of the following: java, dart"
}

case "$mode" in
bare)   bare ;;
docker) docker ;;
weave)  weave ;;
*)      usage ;;
esac