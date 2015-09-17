#!/bin/sh

# Installs Golang and pingpong-go on system under test

# Install Golang
sudo apt-get update
sudo apt-get install golang -y

# Install pingpong-go
export GOPATH=$PWD
go get github.com/gorilla/mux
go install pingpong