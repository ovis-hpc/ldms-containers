#!/bin/bash

set -e

D=$(dirname $0)
cd ${D}

docker build -t ovishpc/ldms-ui .
