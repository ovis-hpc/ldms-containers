#!/bin/bash

set -e

D=$(dirname $0)
# work in the top src directory
cd ${D}/../
SDIR=${PWD}

X=ldms-dev
echo "==== $X ===="
${SDIR}/recipes/${X}/docker-build.sh

echo "==== build ovis ===="
${SDIR}/scripts/build-ovis-binaries.sh

echo "==== build dsosds ===="
${SDIR}/scripts/build-dsosds.sh

for X in ldms-{samp,agg,maestro,ui,grafana} ; do
	echo "==== $X ===="
	${SDIR}/recipes/${X}/docker-build.sh
done
