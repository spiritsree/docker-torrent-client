#!/bin/bash

DOCKERIZE_VERSION='0.6.1'
echo "Installing required apps..."

mkdir -p /app/tmp
cd /app/tmp || exit 1

# Installing dockerize
curl -L https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz 2> /dev/null | tar -C /usr/local/bin -xzv
