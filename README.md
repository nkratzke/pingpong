pingpong
========

A Ping Pong Server for test and benchmarking purposes of http requests.

The intended usage of this package is to run two hosts. Host 1 runs a ping server questioning a pong server (on host 2) for the answer. Ping and pong build a very simple distributed system.

Siege (Benchmark Host) <-> __Ping (Host 1) <-> Pong (Host 2)__

From a benchmark host (this is called the siege host) a benchmark (e.g. apachebench) is run againt host 1. Host 1 has to interact with host 2 to answer the request. The interaction between both hosts is very simple. Whenever host 1 (ping) is asked to deliver a document for /ping/<nr> this request is passed forward to host 2 (pong). Host 2 (pong) returns the answer which is formed of a message "pooooong" where the message has as many o's as the number (so the answer has a variable length according to the request).

So the following answers would be generated for following requests by host 2:

- GET /pong/1 returns "pong"
- GET /pong/5 returns "pooooong"
- GET /pong/10 returns "poooooooooong"
- and so on

So we can vary the message size (and therefore the network load) between host 1 and host 2.

This setting shall be used to analyse the impact of infrastructures where host 1 and host 2 are running on. The deployment above stays the same for every experiment. Just the underlying infrastructure of host 1 and host 2 changes. Thererfore variations of benchmark results can be assigned to changing infrastructures.

For example you could be interested of the impact by several deployment strategies. IaaS cloud service providers normally provide options to deploy hosts into the same zone, into the same region or even into different regions. Normally network performance decreases from within zone to cross-zone and to cross-region. But how big is this impact?

To figure this out you can derive several experiments for example with Amazon Web Services EC2 service.

- Your reference data could be to deploy host 1, host 2 into the same AWS availability zone (assumed to show best network performance).
- Your first experiment could be to deploy host and host 2 into different availability zones to measure a cross-zone impact of deployments (assumed to show middle network performance).
- Your second experiment could be to deploy host 1 and host 2 into different regions to measure a cross-region impact of deployments (assumed to show worst network performance).

In order to get fair results you should deploy the benchmark host and host 1 always into the same zone.
