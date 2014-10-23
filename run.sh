#!/bin/bash

# Run the experiment against
# You have to specify your ping host here!
URL=http://my.host.com/ping

# Each experiment should be done with following amount of concurrent users.
USER=50

# Repeat each benchmarking run 20 times
for round in $(seq 1 20)
do

  # Small message sizes (10, 20, ... 100) bytes
  for LEN in $(seq 10 10 100)
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # Sub kilobyte message sizes (100, 200, ..., 1000) bytes
  for LEN in $(seq 100 100 1000)
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # kilobyte message sizes (1000, 2000, ..., 20000) bytes
  for LEN in $(seq 1000 1000 10000)
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # 10 kByte message sizes (10kB, 20kB, ..., 300kB)
  for LEN in $(seq 10000 10000 300000)
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # 100kByte messages sizes (300kB, 400kB, ..., 1000kB)
  for LEN in $(seq 300000 100000 1000000)
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

done
