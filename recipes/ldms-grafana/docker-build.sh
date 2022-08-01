#!/bin/bash

D=$(dirname $0)
cd $D
NAME=ovishpc/ldms-grafana

echo "Building Docker Image: ${NAME}"
docker build -t ${NAME} .
