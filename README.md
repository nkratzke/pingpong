pingpong
========

A distributed HTTP-based and REST-like ping-pong system for test and benchmarking purposes.

The intended usage of this package is to run two hosts which are queried (benchmarked) by a third host (the _siege_). 
Host 1 runs a _ping_ service querying a _pong_ service (on host 2) for the answer. 
_Ping_ and _pong_ build a very simple distributed system communicating via a simple HTTP based resource API.

<img src="experiment.png" width=100%>

From a benchmark host (this is called the _siege_ host) _ppbench_ is run againt host 1. 
_Ping_ host 1 has to interact with _pong_ host 2 to answer the request. 
The interaction between both hosts is very simple. 
Whenever host 1 (_ping_) is asked to deliver a document for '/ping/{n}' this request is passed forward to host 2 (_pong_). 
Host 2 (_pong_) returns the answer which is formed of a message "pooooong" where the message is as long in 
bytes as the number '{nr}' provided with the query. 

So we (or better _ppbench_) can vary the message size 
(and therefore the network load) between _ping_ (host 1) and _pong_ (host 2).

This setting shall be used to analyse the impact of infrastructures where _ping_ and _pong_ services are running on. 
The deployment above stays the same for every experiment. 
Just the underlying infrastructure of _ping_ and _pong_ changes. 

- _Ping_ and _Pong_ might be realized in different programming languages.
- _Ping_ and _Pong_ might be deployed on different virtual machine types.
- _Ping_ and _Pong_ might be deployed on different IaaS infrastructures.
- _Ping_ and _Pong_ might be deployed in a containerized form.
- _Ping_ and _Pong_ might be connected with an overlay network.
- and so on 

Therefore variations of benchmark results can be assigned to above mentioned changes in infrastructure.

## Set up a benchmark experiment

To do a benchmark you have to set up a _siege_, a _ping_ and a _pong_ host. 
We assume these are Linux hosts with git, apt-get and curl installed. 
Install this package on all of this three hosts by running following commands.

```
git clone https://github.com/nkratzke/pingpong.git
cd pingpong
sudo sh ./install.sh
```

This will install necessary dependencies. These include:

- Dart SDK
- Docker
- Docker overlay network Weave.
- Ruby runtime and development environment
- Golang SDK
- Java SDK
- ppbench (as benchmarking and analyzing front end)

It is possible to run the _Ping_ and _Pong_ service as a Docker container 
and as a Docker container connected to a Weave SDN network. 

### On the pong host: Set up the _pong service_

First step is to start the _pong_ service on the _pong_ host. This will start the _pong_ service on the host on port 8080.
You have three options to start the _pong_ service:

#### Run a bare pong service

```
pong:$ ./start.sh bare pong
```

You want to check wether the _pong_ service is working correctly by checking that 

```
pong:$ curl http://localhost:8080/pong/5
```

answers with 'poong'.

#### Run a dockerized pong service

```
pong:$ ./start.sh docker pong
```

This will build the ping pong image if necessary. So start up may take some time.
You can check whether the pong service is running:

```
sudo docker ps
```

You want to check wether the _pong_ service is working correctly by checking that 

```
pong:$ curl http://localhost:8080/pong/5
```

answers with 'poong'.

Please figure out the IP adress or DNS name of your pong host. We will refer to it as <code>&lt;ponghostip&gt;</code>. 

#### Run a dockerized pong service connected to a weave network

```
pong:$ ./start.sh weave pong
```

This will build the ping pong image as well as the necessary weave containers if necessary. 
So start up may take some time (longer than docker start up above).
You can check whether the pong service is running:

```
sudo docker ps
```

You can check whether this container was successfully added to the weave network.

```
sudo weave status
```

should return something like that

```
weave router 1.0.1
Our name is 6a:15:b5:bf:ba:00(ip-172-31-9-17)

...

Peers:
6a:15:b5:bf:ba:00(ip-172-31-9-17) (v8) (UID 17688622006055783656)
   -> 6a:58:56:7b:86:a7(ip-172-31-14-183) [172.31.14.183:40353]
6a:58:56:7b:86:a7(ip-172-31-14-183) (v2) (UID 4488684819840626089)
   -> 6a:15:b5:bf:ba:00(ip-172-31-9-17) [172.31.9.17:6783]

...

weave DNS 1.0.1
Listen address :53
Fallback DNS config &{[172.31.0.2] [eu-central-1.compute.internal] 53 1 5 2}

Local domain weave.local.
Interface &{13 65535 ethwe b2:b7:ad:19:b4:34 up|broadcast|multicast}
Zone database:
81cac0157b0e: pong.weave.local.[10.128.0.2]
```

You want to check wether the _pong_ service is working correctly by checking that 

```
pong:$ curl http://localhost:8080/pong/5
```

answers with 'poong'.

Please figure out the IP adress or DNS name of your pong host. We will refer to it as <code>&lt;ponghostip&gt;</code>.
Please figure out the SDN IP adress or SDN DNS name of your pong container. We will refer to it as <code>&lt;pongsdnip&gt;</code>.

### On the ping host: Set up the _ping service_

Second step is to start the _ping_ service on the _ping_ host. This will start the _ping_ service on the host on port 8080.
You will have to provide the _ping_ service where it will find its _pong_ service by providing <code>&lt;pongip&gt;</code> 
what you have figured out for the _pong_ service above.

You have three options to do this:

#### Run a bare ping service

```
pong:$ ./start.sh bare ping <ponghostip>
```

You want to check wether the _ping_ service is working correctly by checking that 

```
ping:$ curl http://localhost:8080/ping/5
```

answers with 'poong'.

#### Run a dockered ping service

```
pong:$ ./start.sh docker ping <ponghostip>
```

This will build necessary images. So startup may take some time.

You want to check wether the _ping_ service is working correctly by checking that 

```
ping:$ curl http://localhost:8080/ping/5
```

answers with 'poong'.

#### Run a dockered ping service attached to weave network

```
pong:$ ./start.sh weave ping <pongsdnip> <ponghostip>
```

This will build necessary images and will connect to the SDN network established by the pong host.
So startup may take some time.

You want to check wether the _ping_ service is working correctly by checking that 

```
ping:$ curl http://localhost:8080/ping/5
```

answers with 'poong'.


### On the siege host: set up and run apachebench

Third step you should run the benchmark to figure out the answer performance of your ping-pong system. On your _siege_ 
host you will find a <code>run.sh</code> script to start your benchmark. 

```
./run.sh <pinghostip>
```

The <code>run.sh</code> script provides more parameters to vary your experiments. You can change 

- the amount of concurrent messages,
- the message sizes,
- and how often each benchmark run per message size should be executed.

All benchmark results are written into a file <code>apachebench.log</code>. This log file can be processed by <code>bin/analyze.dart</code> to generate a csv file which is better suited to be imported into databases or statistical tools like R.

The following line converts experiment data (apachebench log format), tag it with a name (here 'Reference') and convert it into a csv file. You can use tags to distinguish different experiments for analysis.

```
dart bin/analyze.dart --tag Reference apachebench.log > reference.csv
```