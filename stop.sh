#!/bin/sh

#
# Stops running ping/pong/SDN services on ping or pong host under test.
# Should be called after a ppbench run on siege host completes.
#

echo "Stopping pong if running"
sudo docker stop pong || true
sudo docker rm pong || true

echo "Stopping ping if running"
sudo docker stop ping || true
sudo docker rm ping || true

echo "Stopping weave if running"
sudo weave stop || true

echo "Stopping calico if running"
sudo calicoctl node stop --force || true
sudo kill `pidof etcd` || true
