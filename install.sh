#!/bin/sh

# Script to install dart sdk on a linux ubuntu system
apt-get update
apt-add-repository ppa:hachre/dart
apt-get install dartsdk

# Install
pub get