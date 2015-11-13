#!/bin/bash

# Script to start the ping and pong services on hosts under test.
#

# Passed command line parameters 
# 
mode=$1
service=$2
pongip=$3

# Prints usage information
#
function usage {
	echo "'start.sh bare pong-{lang}' starts the pong server in bare mode"
	echo "'start.sh bare ping-{lang} <pongip>' starts the ping server in bare mode"
	echo "'start.sh docker pong-{lang}' starts the pong server as docker container"
	echo "'start.sh docker ping-{lang} <pongip>' starts the ping server as docker container"
	echo "'start.sh weave pong-{lang}' starts the pong server as docker container and connects it to a weave SDN network"
	echo "'start.sh weave ping-{lang} <pongip>' starts the ping server as docker container and connects it to a weave SDN network"
	echo "'start.sh calico pong-{lang}' starts the pong server as docker container and connects it to a Calico SDN network"
	echo "'start.sh calico ping-{lang} <pongip>' starts the ping server as docker container and connects it to a Calico SDN network"
    echo ""
	echo "{lang} can be one of the following: java, dart, go, ruby"
}

# Starts ping and pong services in bare mode
#
function bare {
	case "$service" in
	pong-dart) dart pingpong-dart/bin/pong.dart --port=8080 ;;
	ping-dart) dart pingpong-dart/bin/ping.dart --port=8080 --url="http://$pongip:8080" ;;
	
	pong-java) java -cp pingpong-java/bin Pong 8080 ;;
	ping-java) java -cp pingpong-java/bin Ping 8080 $pongip 8080 ;;
	
	pong-go)   $PWD/pingpong-go/bin/pingpong -asPong ;;
	ping-go)   $PWD/pingpong-go/bin/pingpong -asPing -pongHost $pongip -pongPort 8080 ;;

	pong-ruby) source $HOME/.rvm/scripts/rvm && cd $PWD/pingpong-ruby/bin && ./start.rb pong ;;
	ping-ruby) source $HOME/.rvm/scripts/rvm && cd $PWD/pingpong-ruby/bin && ./start.rb ping --ponghost $pongip --pongport 8080 ;;
	
	*)         echo "Unknown service $service" 
	           usage ;;
	esac
}

# Starts ping and pong services as docker containers
#
function docker {
	case "$service" in
	pong-dart) sudo docker build -t ppdart pingpong-dart/
	           sudo docker run -d -p 8080:8080 --name pong ppdart --asPong --port=8080
	           ;;
		  	
	ping-dart) sudo docker build -t ppdart pingpong-dart/
	           sudo docker run -d -p 8080:8080 --name ping ppdart --asPing --port=8080 --url="http://$pongip:8080"
		       ;;

    pong-java) sudo docker build -t ppjava pingpong-java/
	           sudo docker run -d -p 8080:8080 --name pong ppjava Pong 8080
			   ;;
		  
    ping-java) sudo docker build -t ppjava pingpong-java/
	           sudo docker run -d -p 8080:8080 --name ping ppjava Ping 8080 $pongip 8080
			   ;;
			   
	pong-go)   sudo docker build -t ppgo pingpong-go/
	           sudo docker run -d -p 8080:8080 --name pong ppgo -asPong
			   ;;
			  
	ping-go)   sudo docker build -t ppgo pingpong-go/
	           sudo docker run -d -p 8080:8080 --name ping ppgo -asPing -pongHost $pongip -pongPort 8080
	           ;;

	pong-ruby) sudo docker build -t ppruby pingpong-ruby/
	           sudo docker run -d -p 8080:8080 --name pong ppruby pong
			   ;;
			  
	ping-ruby) sudo docker build -t ppruby pingpong-ruby/
	           sudo docker run -d -p 8080:8080 --name ping ppruby ping --ponghost $pongip -pongport 8080
	           ;;
			   
	*)         echo "Unknown service $service" 
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
		       sudo weave run --with-dns 10.2.1.2/16 --name=ping -d -p 8080:8080 ppdart --asPing --port=8080 --url="http://10.2.1.1:8080"
		       ;;
		  
	pong-java) sudo weave launch --ipalloc-range 10.2.0.0/16
	   		   sudo docker build -t ppjava pingpong-java/
	           sudo weave run --with-dns 10.2.1.1/16 --name=pong -d -p 8080:8080 ppjava Pong 8080
	           ;;

    ping-java) sudo weave launch $pongip --ipalloc-range 10.2.0.0/16
	           sudo docker build -t ppjava pingpong-java/
	           sudo weave run --with-dns 10.2.1.2/16 --name=ping -d -p 8080:8080 ppjava Ping 8080 10.2.1.1 8080
			   ;;
			   
	pong-go)   sudo weave launch --ipalloc-range 10.2.0.0/16
	           sudo docker build -t ppgo pingpong-go/
			   sudo weave run --with-dns 10.2.1.1/16 --name=pong -d -p 8080:8080 ppgo -asPong
			   ;;
			   
	ping-go)   sudo weave launch $pongip --ipalloc-range 10.2.0.0/16
			   sudo docker build -t ppgo pingpong-go/
			   sudo weave run --with-dns 10.2.1.2/16 --name=ping -d -p 8080:8080 ppgo -asPing -pongHost 10.2.1.1 -pongPort 8080
			   ;;

	pong-ruby)   sudo weave launch --ipalloc-range 10.2.0.0/16
	           sudo docker build -t ppruby pingpong-ruby/
			   sudo weave run --with-dns 10.2.1.1/16 --name=pong -d -p 8080:8080 ppruby pong
			   ;;
			   
	ping-ruby)   sudo weave launch $pongip --ipalloc-range 10.2.0.0/16
			   sudo docker build -t ppruby pingpong-ruby/
			   sudo weave run --with-dns 10.2.1.2/16 --name=ping -d -p 8080:8080 ppruby ping --ponghost 10.2.1.1 --pongport 8080
			   ;;
			   
	*)         echo "Unknown service $service" 
	           usage
	           ;;
		   
	esac
}

# !!! UNDER CONSTRUCTION !!!

# Starts ping and pong services as docker containers 
# attached to a calico SDN (CIDR 10.2.0.0/16)
# Pong gets IP 10.2.1.1
# Ping gets IP 10.2.1.2
#
# !!! UNDER CONSTRUCTION !!! 
#
function calico {

	# load modules, enable IP forwarding
    sudo modprobe xt_set
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sysctl -w net.ipv6.conf.all.forwarding=1

	# start etcd service and calico depending being ping or pong
	if [ -n "$pongip" ]; 
	then 
		# We are the pong host
	    NODE_IP=`hostname -i`
		# Start etcd
		etcd -listen-client-urls="http://0.0.0.0:2379" \
		     -advertise-client-urls="http://$NODE_IP:2379" \
			 > /dev/null 2>&1 &
		
		# Start calico
		sudo calicoctl node
		sudo calicoctl pool add 10.2.0.0/16 --ipip --nat-outgoing
		sudo calicoctl profile add PROF_PINGPONG
	else
		# We are the ping host
		sudo ETCD_AUTHORITY=$pongip:2379 calicoctl node		
	fi	

	case "$service" in
	pong-dart) sudo docker build -t ppdart pingpong-dart/
	           sudo docker run -d -p 8080:8080 --name pong ppdart --asPong --port=8080
             sudo calicoctl container add pong 10.2.1.1
             sudo calicoctl container pong profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.1:8080 > /dev/null 2>&1 &
	           ;;
		  	
	ping-dart) sudo docker build -t ppdart pingpong-dart/
	           sudo docker run -d -p 8080:8080 --name ping ppdart --asPing --port=8080 --url="http://10.2.1.1:8080"
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container add ping 10.2.1.2
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container ping profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.2:8080 > /dev/null 2>&1 &
		       ;;

    pong-java) sudo docker build -t ppjava pingpong-java/
	           sudo docker run -d -p 8080:8080 --name pong ppjava Pong 8080
             sudo calicoctl container add pong 10.2.1.1
             sudo calicoctl container pong profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.1:8080 > /dev/null 2>&1 &
			   ;;
		  
    ping-java) sudo docker build -t ppjava pingpong-java/
	           sudo docker run -d -p 8080:8080 --name ping ppjava Ping 8080 10.2.1.1 8080
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container add ping 10.2.1.2
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container ping profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.2:8080 > /dev/null 2>&1 &
			   ;;
			   
	pong-go)   sudo docker build -t ppgo pingpong-go/
	           sudo docker run -d -p 8080:8080 --name pong ppgo -asPong
             sudo calicoctl container add pong 10.2.1.1
             sudo calicoctl container pong profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.1:8080 > /dev/null 2>&1 &
			   ;;
			  
	ping-go)   sudo docker build -t ppgo pingpong-go/
	           sudo docker run -d -p 8080:8080 --name ping ppgo -asPing -pongHost 10.2.1.1 -pongPort 8080
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container add ping 10.2.1.2
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container ping profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.2:8080 > /dev/null 2>&1 &
	           ;;

	pong-ruby) sudo docker build -t ppruby pingpong-ruby/
	           sudo docker run -d -p 8080:8080 --name pong ppruby pong
             sudo calicoctl container add pong 10.2.1.1
             sudo calicoctl container pong profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.1:8080 > /dev/null 2>&1 &
     		   ;;
			  
	ping-ruby) sudo docker build -t ppruby pingpong-ruby/
	           sudo docker run -d -p 8080:8080 --name ping ppruby ping --ponghost 10.2.1.1 -pongport 8080
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container add ping 10.2.1.2
             sudo ETCD_AUTHORITY=$pongip:2379 calicoctl container ping profile append PROF_PINGPONG
             # start socat since port forwarding doesn't work
             # socat TCP4-LISTEN:8080,fork TCP4:10.2.1.2:8080 > /dev/null 2>&1 &
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
	calico) calico ;;
	*)      usage ;;
esac
