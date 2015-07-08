#!/bin/bash

# Run the experiment against the following host
URL="http://$1:8080/ping"
echo "Running benchmark agains $URL"

# Each experiment should be done with following amount of concurrent users.
USER=50

# Repeat each benchmarking run 20 times
for ((round=1; round<=20; round++))
do

  # Small message sizes (10, 20, ... 100) bytes
  for ((LEN=10; LEN<100; LEN=LEN+10))
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # Sub kilobyte message sizes (100, 200, ..., 1000) bytes
  for ((LEN=100; LEN<1000; LEN=LEN+100))
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # kilobyte message sizes (1000, 2000, ..., 10000) bytes
  for ((LEN=1000; LEN<10000; LEN=LEN+1000))
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # 10 kByte message sizes (10kB, 20kB, ..., 300kB)
  for ((LEN=10000; LEN<300000; LEN=LEN+10000))
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

  # 100kByte messages sizes (300kB, 400kB, ..., 1000kB)
  for ((LEN=300000; LEN<=1000000; LEN=LEN+100000))
  do
    ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
  done

done
