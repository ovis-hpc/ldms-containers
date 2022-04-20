#!/bin/bash
set -e

D=$(dirname $0)
cd ${D}
# Need the scripts here (cannot be a soft link) for docker build context
cp -rT ../scripts ./.scripts
docker build -t ovishpc/ldms-samp .
