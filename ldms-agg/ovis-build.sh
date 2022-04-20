#!/bin/bash
#
# build ovis binaries for `sampler` containers using `ovishpc/ovis-centos-build`
# docker image.

set -e

D=$(dirname $0)
. ${D}/../config.sh
IMG=ovishpc/ovis-centos-build
OVIS_REV=${OVIS_REV:-OVIS-4}
OVIS_REPO=${OVIS_REPO:-https://github.com/ovis-hpc/ovis}
SOS_REV=${SOS_REV:-SOS-5}
SOS_REPO=${SOS_REPO:-https://github.com/ovis-hpc/sos}
ODIR=${D}/.ovis
CONT=ldms-agg-build # container for building ovis

LOG(){
	echo "$(date +'%F %T')" "$@"
}

if [[ -d ${ODIR} ]]; then
	rm -rf ${ODIR}
fi

CFLAGS=( -O2 )

OPTIONS=(
	--prefix=/opt/ovis
	--enable-python
	--enable-etc
	--enable-munge

	# samplers for testing
	--enable-zaptest
        --enable-ldms-test
        --enable-test_sampler
        --enable-list_sampler
        --enable-record_sampler
        --enable-tutorial-sampler
        --enable-tutorial-store

	--enable-sos
	--with-sos=/opt/ovis
	--enable-store-app
)

{ cat <<EOF
set -e
set -x
cd ~

#### SOS ####
mkdir sos
pushd sos
git init .
git remote add github ${SOS_REPO}
git fetch github ${SOS_REV}
git checkout FETCH_HEAD
./autogen.sh
mkdir build
pushd build
../configure --prefix=/opt/ovis CFLAGS="${CFLAGS[*]}"
make
make install
popd

#### OVIS ####
mkdir ovis
pushd ovis
git init .
git remote add github ${OVIS_REPO}
git fetch github ${OVIS_REV}
git checkout FETCH_HEAD
./autogen.sh
mkdir build
pushd build
../configure ${OPTIONS[@]} CFLAGS="${CFLAGS[*]}"
make
make install
popd

chown ${UID}:${UID} -R /opt/ovis
EOF
} | docker run -i --name ${CONT} --hostname ${CONT} \
	${IMG} "/bin/bash"

atexit() {
	docker rm ${CONT}
}
trap atexit EXIT

if (( $? )); then
	LOG "ldms-agg/ovis-build.sh FAILED!!!"
	exit -1
fi

SRC="${CONT}:/opt/ovis"
DST="${ODIR}"
LOG "Copying ${SRC} to ${DST}"
docker cp ${SRC} ${DST}
RC=$?
LOG "Exiting, rc: ${RC}"
