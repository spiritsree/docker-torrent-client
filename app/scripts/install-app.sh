#!/bin/bash

DOCKERIZE_VERSION='0.6.1'

DOCKERIZE_IMAGE_URL="https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz"
COMBUSTION_IMAGE_URL="https://github.com/Secretmapper/combustion/archive/release.tar.gz"
TR_WEB_CONTROL_IMAGE_URL="https://github.com/ronggang/transmission-web-control/archive/master.tar.gz"
TR_WEB_HOME="/usr/share/transmission-ui"
TR_DEFAULT_WEB_HOME="/usr/share/transmission/web"

TMP_DIR="/opt/setup-dir"

mkdir -p "${TMP_DIR}"
pushd "${TMP_DIR}" > /dev/null || exit 1

# Installing dockerize
echo "**** install dockerize ****"
curl -sL "${DOCKERIZE_IMAGE_URL}" 2> /dev/null | tar -C /usr/local/bin -xz

mkdir -p "${TR_WEB_HOME}"

echo "**** install Combustion UI ****"
curl -sL "${COMBUSTION_IMAGE_URL}" -o combustion.tar.gz 2> /dev/null
tar xzf combustion.tar.gz --transform='s/^combustion-release/combustion/' -C "${TR_WEB_HOME}"

echo "**** install Transmission Web Control UI ****"
curl -sL "${TR_WEB_CONTROL_IMAGE_URL}" -o transmission-web-control.tar.gz 2> /dev/null
tar xzf transmission-web-control.tar.gz --transform='s/^transmission-web-control-master\/src/transmission-web-control/'
mv ./transmission-web-control "${TR_WEB_HOME}/"

# When using Transmission Web Control UI, it gives control to switch UI to original
# This will be broken if the below symlinks are missing
echo "**** fixing original UI when using Transmission Web Control UI ****"
ln -s "${TR_DEFAULT_WEB_HOME}/style" "${TR_WEB_HOME}/transmission-web-control/style"
ln -s "${TR_DEFAULT_WEB_HOME}/images" "${TR_WEB_HOME}/transmission-web-control/images"
ln -s "${TR_DEFAULT_WEB_HOME}/javascript" "${TR_WEB_HOME}/transmission-web-control/javascript"
ln -s "${TR_DEFAULT_WEB_HOME}/index.html" "${TR_WEB_HOME}/transmission-web-control/index.original.html"

popd > /dev/null || exit 1
rm -rf "${TMP_DIR}"
