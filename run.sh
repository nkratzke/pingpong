#!/bin/bash

# Run the experiment against

URL=http://my.host.com/ping

# Starts the experiment with following amount of users.
for USER in 10 50 100 200 300 400 500
do

  # each requesting messages of length (in bytes)
  for LEN in 100 500 5000 10000 20000 40000 80000 160000
  do

    # run each benchmark 10 times
    for round in 1 2 3 4 5 6 7 8 9 10
    do
      ab -c $USER -n 1000 $URL/$LEN >> apachebench.log
    done

  done

done
