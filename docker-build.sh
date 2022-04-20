#!/bin/bash

set -e

DIRS=(
	ldms-base ldms-samp ldms-agg ldms-ui ldms-grafana
)

DOCKER_BUILD=docker-build.sh

for D in ${DIRS[@]}; do
	[[ -f ${D}/${DOCKER_BUILD} ]] || continue
	echo "==== $D ===="
	pushd ${D}
	./${DOCKER_BUILD}
	popd
done
