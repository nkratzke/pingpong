pingpong
========

A Ping Pong Server for test and benchmarking purposes.

The intended usage of this package is to run two hosts. Host 1 runs a ping server questioning a pong server (on host 2) for the answer. Ping and pong build a very simple distributed system.

Siege (Benchmark Host) <-> __Ping (Host 1) <-> Pong (Host 2)__

From a benchmark host (this is called the siege host) a benchmark (apachebench) is run againt host 1. Host 1 has to interact with host 2 to answer the request. The interaction between both hosts is very simple. Whenever host 1 (ping) is asked to deliver a document for /ping/<nr> this request is passed forward to host 2 (pong). Host 2 (pong) returns the answer which is formed of a message "pooooong" where the message has as many o's as the number (so the answer has a variable length according to the request).

So the following answers would be generated for following requests by host 2:

- GET /pong/1 returns "pong"
- GET /pong/5 returns "pooooong"
- GET /pong/10 returns "poooooooooong"
- and so on

So we can vary the message size (and therefore the network load) between host 1 and host 2.

This setting shall be used to analyse the impact of infrastructures where host 1 and host 2 are running on.
