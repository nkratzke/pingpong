#!/bin/bash

# Script to start the ping and pong services
#

# Passed command line parameters 
# 
mode=$1
service=$2
pongip=$3
#ponghostip=$4

# Prints usage information
#
function usage {
	echo "'start.sh bare pong-{lang}' starts the pong server in bare mode"
	echo "'start.sh bare ping-{lang} <pongip>' starts the ping server in bare mode"
	echo "'start.sh docker pong-{lang}' starts the pong server as docker container"
	echo "'start.sh docker ping-{lang} <pongip>' starts the ping server as docker container"
	echo "'start.sh weave pong-{lang}' starts the pong server as docker container and connects it to a weave SDN network"
	echo "'start.sh weave ping-{lang} <pongip>' starts the ping server as docker container and connects it to a weave SDN network"
    echo ""
	echo "{lang} can be one of the following: java, dart, go"
}

# Starts ping and pong services in bare mode
#
function bare {
	case "$service" in
	pong-dart) sudo dart bin/pong.dart --port=8080 ;;
	ping-dart) sudo dart bin/ping.dart --port=8080 --url="http://$pongip:8080" ;;
	
	pong-java) sudo java -cp pingpong-java/bin Pong 8080 ;;
	ping-java) sudo java -cp pingpong-java/bin Ping 8080 $pongip 8080 ;;
	
	pong-go)   sudo $PWD/pingpong-go/bin/pingpong -asPong
	ping-go)   sudo $PWD/pingpong-go/bin/pingpong -asPing -pongHost $pongip -pongPort 8080
	
	*)         echo "Unknown service $service" 
	           usage ;;
	esac
}

# Starts ping and pong services as docker containers
#
function docker {
	case "$service" in
	pong-dart) sudo docker build -t pingpong pingpong-dart/
	           sudo docker run -d -p 8080:8080 ppdart --asPong --port=8080
	           ;;
		  	
	ping-dart) sudo docker build -t pingpong pingpong-dart/
	           sudo docker run -d -p 8080:8080 ppdart --asPing --port=8080 --url="http://$pongip:8080"
		       ;;

    pong-java) sudo docker build -t ppjava pingpong-java/
	           sudo docker run -d -p 8080:8080 ppjava Pong 8080
			   ;;
		  
    ping-java) sudo docker build -t ppjava pingpong-java/
	           sudo docker run -d -p 8080:8080 ppjava Ping 8080 $pongip 8080
			   ;;
			   
	pong-go)  sudo docker build -t ppgo pingpong-go/
	          sudo docker run -d -p 8080:8080 ppgo -asPong
			  ;;
			  
	ping-go)  sudo docker build -t ppgo pingpong-go/
	          sudo docker run -d -p 8080:8080 ppgo -asPing -pongHost $pongip -pongPort 8080
	          ;;
			   
	*)        echo "Unknown service $service" 
	          usage
	          ;;
	esac
}

# Starts ping and pong services as docker containers 
# attached to a weave SDN (CIDR 10.2.0.0/16)
# Pong gets IP 10.2.1.1
# Ping gets IP 10.2.1.2
#
function weave {
	case "$service" in
	pong-dart) sudo weave launch --ipalloc-range 10.2.0.0/16
	           sudo docker build -t ppdart pingpong-dart/
		       sudo weave run --with-dns 10.2.1.1/16 --name=pong -d -p 8080:8080 ppdart --asPong --port=8080
		       ;;
		  			   
	ping-dart) sudo weave launch $pongip --ipalloc-range 10.2.0.0/16
	           sudo docker build -t ppdart pingpong-dart/
		       sudo weave run --with-dns 10.2.1.2/16 --name=ping -d -p 8080:8080 ppdart --asPing --port=8080 --url="http://$pongip:8080"
		       ;;
		  
	pong-java) sudo weave launch --ipalloc-range 10.2.0.0/16
	   		   sudo docker build -t ppjava pingpong-java/
	           sudo weave run --with-dns 10.2.1.1/16 --name=pong -d -p 8080:8080 ppjava Pong 8080
	           ;;

    ping-java) sudo weave launch $pongip --ipalloc-range 10.2.0.0/16
	           sudo docker build -t ppjava pingpong-java/
	           sudo weave run --with-dns 10.2.1.2/16 --name=ping -d -p 8080:8080 ppjava Ping 8080 10.2.1.1 8080
			   ;;
			   
	pong-go)   sudo weave launch --ipalloc-rang 10.2.0.0/16
	           sudo docker build -t ppgo pingpong-go/
			   sudo weave run --with-dns 10.2.1.1/16 --name=pong -d -p 8080:8080 ppgo -asPong
				
	ping-go)   sudo weave launch $pongip --ipalloc-range 10.2.0.0/16
			   sudo docker build -t ppgo pingpong-go/
			   sudo weave run --with-dns 10.2.1.2/16 --name=ping -d -p 8080:8080 ppgo -asPing -pongPort 8080
							  
    stop)      sudo docker stop pong
	           sudo docker stop ping
			   sudo weave stop
			   ;;
			   
	*)         echo "Unknown service $service" 
	           usage
	           ;;
		   
	esac
}


case "$mode" in
bare)   bare ;;
docker) docker ;;
weave)  weave ;;
*)      usage ;;
esac