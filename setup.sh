#!/bin/bash

IMAGE_TAG='docker-torrent-client'
IMAGE_OS='ubuntu'

docker build --no-cache -t "${IMAGE_TAG}-${IMAGE_OS}" -f Dockerfile.${IMAGE_OS} app

OPT="--cap-add=NET_ADMIN -d \\ \n"
# Check if Docker IPv6 is enabled
ipv6_enabled=$(docker network ls --filter Driver="bridge"  --format "{{.IPv6}}")

# Disable IPv6 if Docker doesn't support it
if [[ "${ipv6_enabled}" == "false" ]]; then
    OPT+="\t--sysctl net.ipv6.conf.all.disable_ipv6=0 \\ \n"
fi

# DNS IPs
OPT+="\t\t--dns 8.8.8.8 \\ \n \t--dns 8.8.4.4 \\ \n"

# Volume mount for Data
OPT+="\t\t-v ~/Downloads/uTorrent/data/:/data \\ \n"

# OpenVPN username and password
OPT+="\t\t-e OPENVPN_USERNAME=<username> \\ \n"
OPT+="\t\t-e OPENVPN_PASSWORD=<password> \\ \n"

# Docker Image to run
OPT+="\t\t${IMAGE_TAG}-${IMAGE_OS}:latest \n"

# Run this command to start the docker
printf "docker run ${OPT}"
