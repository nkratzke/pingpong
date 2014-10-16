#!/bin/bash

# Run the experiment against

URL=http://my.host.com/ping

# Starts the experiment with following amount of concurrent users.
for USER in 50
do

  # each requesting messages of length (in bytes)
  for LEN in 10 50 100 500 1000 5000 10000 50000 100000 500000 1000000
  do

    # run each benchmark 10 times
    for round in $(seq 1 10)
    do
      ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
    done

  done

done
