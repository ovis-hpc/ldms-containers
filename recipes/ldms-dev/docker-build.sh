#!/bin/bash

D=$(dirname $0)
cd $D
NAME=ovishpc/ldms-dev

echo "Building Docker Image: ${NAME}"
docker build -t ${NAME} .
