pingpong
========

A distributed HTTP-based and REST-like ping-pong system for test and benchmarking purposes.

The intended usage of this package is to run two hosts which are queried (benchmarked) by a third host (the _siege_). Host 1 runs a _ping_ service querying a _pong_ service (on host 2) for the answer. _Ping_ and _pong_ build a very simple distributed system.

<img src="experiment.png" width=100%>

From a benchmark host (this is called the _siege_ host) a benchmark (e.g. apachebench) is run againt host 1. _Ping_ host 1 has to interact with _pong_ host 2 to answer the request. The interaction between both hosts is very simple. Whenever host 1 (_ping_) is asked to deliver a document for '/ping/<nr>' this request is passed forward to host 2 (_pong_). Host 2 (_pong_) returns the answer which is formed of a message "pooooong" where the message is as long in bytes as the number '<nr>' provided with the query (so the answer message length can be specified by the _siege_ host to benchmark network performance of message sizes of varying length).

So the following answers would be generated for following requests by host 2:

- GET /pong/4 returns "pong"
- GET /pong/5 returns "poong"
- GET /pong/6 returns "pooong"
- and so on

So we can vary the message size (and therefore the network load) between _ping_ (host 1) and _pong_ (host 2).

This setting shall be used to analyse the impact of infrastructures where _ping_ and _pong_ services are running on. The deployment above stays the same for every experiment. Just the underlying infrastructure of _ping_ and _pong_ changes. Thererfore variations of benchmark results can be assigned to changing infrastructures.

## Set up a benchmark experiment

To do a benchmark you have to set up a _siege_, a _ping_ and a _pong_ host. We assume these are Linux hosts with git, apt-get, wget and curl installed. Install this package on all of this three hosts by running following commands.

```
git clone https://github.com/nkratzke/pingpong.git
cd pingpong
sudo sh ./install.sh
```

This will install dart runtime and development environment, apachebench, docker as well as the docker overlay network weave.

It is possible to run the _ping_ and _pong_ service as a docker container. Therefore you have to build a pingpong image on your _ping_ and _pong_ hosts, like that:

```
docker build -t pingpong github.com/nkratzke/pingpong
```

Please be aware, that the dockerized ping-pong system will not show the same performance like a "naked" run ping-pong system.

### On the pong host: Set up the _pong service_

First step is to start the _pong_ service on the _pong_ host. This will start the _pong_ service on the host on port 8080.

```
pong:$ sudo dart bin/pong.dart --port=8080
```

It is although possible to run the pong server as docker container (you will have performance impacts of about 10% to 20%):

```
pong:$ docker build -t pingpong github.com/nkratzke/pingpong
pong:$ docker run -d -p 8080:8080 pingpong --asPong --port=8080
```

You want to check wether the _pong_ service is working correctly by checking that 

```
pong:$ curl http://localhost:8080/pong/5
```

answers with 'poong'.

Please figure out the IP adress or DNS name the your pong host. We will refer to it as <code>&lt;pongip&gt;</code>. 

### On the ping host: Set up the _ping service_

Second step is to start the _ping_ service on the _ping_ host. This will start the _ping_ service on the host on port 8080.
You will have to provide the _ping_ service where it will find its _pong_ service by providing <code>&lt;pongip&gt;</code> and port number you have assigned to the _pong_ service above.

```
ping:$ sudo dart bin/ping.dart --port=8080 --url=http://<pongip>:8080
```

It is although possible to run the ping server as docker container (you will have performance impacts of about 10% to 20%):

```
pong:$ docker build -t pingpong github.com/nkratzke/pingpong
pong:$ docker run -d -p 8080:8080 pingpong --asPing --port=8080 --url=http://<pongip>:8080
```

You want to check wether the _ping_ service is started and able to communicate with the _pong_ service by checking that 

```
ping:$ curl http://localhost:8080/ping/5
```

answers with 'poong'.

Please figure out the IP adress or DNS name the your ping host. We will refer to it as <code>&lt;pingip&gt;</code>. 

### On the siege host: set up apachebench

Third step you should run the benchmark to figure out the answer performance of your ping-pong system. On your _siege_ host you will find a <code>run.sh</code> script to start your benchmark. You should replace <code>http://my.host.com/ping</code> with <code>http://&lt;pingip&gt;:8080/ping</code> to provide the script the correct ping service uri.

```
# You have to specify your ping host here!
URL=http://my.host.com/ping
```

The <code>run.sh</code> script provides more parameters to vary your experiments. You can change 

- the amount of concurrent messages,
- the message sizes,
- and how often each benchmark run per message size should be executed.

All benchmark results are written into a file <code>apachebench.log</code>. This log file can be processed by <code>bin/analyze.dart</code> to generate a csv file which is better suited to be imported into databases or statistical tools like R.

The following line converts experiment data (apachebench log format), tag it with a name (here 'Reference') and convert it into a csv file. You can use tags to distinguish different experiments for analysis.

```
dart bin/analyze.dart --tag=Reference apachebench.log > reference.csv
```

### Measuring the impact of SDN solutions

SDN solutions like weave show additional performance impacts. You can use this ping-pong system to measure this impact. Therefore you have

1. Create your SDN network (solution specific, for weave this works like [that](http://weave.works/guides/weave-docker-ubuntu-simple.html))
2. Attach your ping host container to the SDN network (solution specific, for weave this works like [that](http://weave.works/guides/weave-docker-ubuntu-simple.html))
3. Attach your pong host container to the SDN network (solution specific, for weave this works like [that](http://weave.works/guides/weave-docker-ubuntu-simple.html))
4. Run the benchmark script on the siege host as described above

