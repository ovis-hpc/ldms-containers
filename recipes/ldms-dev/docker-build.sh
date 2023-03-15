#!/bin/bash

D=$(dirname $0)
cd $D
NAME=ovishpc/ldms-dev
source ../../config.sh

[[ -z "${BUILD_TAG}" ]] || NAME="${NAME}:${BUILD_TAG}"

echo "Building Docker Image: ${NAME}"
docker build -t ${NAME} .
