#!/bin/bash

# http://www.tldp.org/LDP/abs/html/parameter-substitution.html
health_host=${HEALTH_CHECK_HOST:-www.google.com}

if ! ping -c 1 "${health_host}" > /dev/null 2>&1; then
    echo "Network down"
    exit 1
else
    echo "Network up"
    exit 0
fi
