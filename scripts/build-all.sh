#!/bin/bash

set -e

D=$(dirname $0)
# work in the top src directory
cd ${D}/../
SDIR=${PWD}

function dbuild() {
	local X=$1
	echo "==== $X ===="
	${SDIR}/recipes/${X}/docker-build.sh
}

dbuild "ldms-dev"
dbuild "ldms-dev-alma"

echo "==== build ovis ===="
${SDIR}/scripts/build-ovis-binaries.sh

echo "==== build dsosds ===="
${SDIR}/scripts/build-dsosds.sh

for X in ldms-{samp,agg,storage,maestro,ui,grafana} ; do
	dbuild "${X}"
done
