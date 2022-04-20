#!/bin/bash

set -e

D=$(realpath $(dirname 0))
cd ${D}

if [[ ! -d dsosds ]]; then
	git clone https://github.com/nick-enoent/dsosds
fi

docker build -t ovishpc/ldms-grafana .
