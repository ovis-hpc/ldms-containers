#!/bin/bash
#
# NOTE: This script copies '../ldms-agg/ovis' (ldms+sos), then install 'numsos'
# on top of it.

LOG() {
	echo $(date +"%F %T") "$@"
}

set -e

D=$(dirname $0)
IMG=ovishpc/ovis-centos-build
NUMSOS_REV=${NUMSOS_REV:-dsos_support}
ODIR=${D}/.ovis
AGG_OVIS_DIR="${D}/../ldms-agg/.ovis"
CONT=ldms-ui-build

[[ -d "${AGG_OVIS_DIR}" ]] || {
	LOG "'${AGG_OVIS_DIR}' not found, please build ovis for ldms-agg first"
	exit -1
}

if [[ -d ${ODIR} ]]; then
	rm -rf ${ODIR}
fi
cp -a "${AGG_OVIS_DIR}" "${ODIR}"

CFLAGS=( -O2 )

OPTIONS=(
	--prefix=/opt/ovis
	--with-sos=/opt/ovis
)

PREFIX_UI=/opt/ovis/ui

# Using copy-in / copy-out as a work around of the issue raised by UID mapping

# bring up the build container
docker run -it --rm -d --name ${CONT} --hostname ${CONT} ${IMG} /bin/bash

atexit() {
	docker kill ${CONT}
}
trap atexit EXIT

# copy the prerequisites
docker cp ${ODIR} ${CONT}:/opt/ovis

# must remove the ${ODIR}; otherwise, the copy-out below will copy
# ${CONT}:/opt/ovis to ${ODIR}/ovis
rm -rf ${ODIR}

# execute the build
{ cat <<EOF
set -e
set -x

cd ~

. /opt/ovis/etc/profile.d/set-ovis-variables.sh

#### NUMSOS ####
mkdir numsos
pushd numsos
git init .
git remote add github https://github.com/nick-enoent/numsos
git fetch github ${NUMSOS_REV}
git checkout FETCH_HEAD
./autogen.sh
mkdir -p build
pushd build
../configure ${OPTIONS[@]} PYTHON=python3 CFLAGS="${CFLAGS[*]}"
make
make install
popd
popd


#### sosdb-ui ####
git clone https://github.com/nick-enoent/sosdb-ui
pushd sosdb-ui
./autogen.sh
mkdir -p build
pushd build
../configure --prefix ${PREFIX_UI}
make
make install
popd
popd

#### sosdb-grafana ####
git clone https://github.com/nick-enoent/sosdb-grafana
pushd sosdb-grafana
./autogen.sh
mkdir -p build
pushd build
../configure --prefix ${PREFIX_UI}
make
make install
popd
popd

EOF
} | docker exec -i ldms-ui-build "/bin/bash"

docker cp ${CONT}:/opt/ovis ${ODIR}
