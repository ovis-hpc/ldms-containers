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
ODIR=${D}/.ovis
CONT=ldms-samp-build # container for building ovis

LOG(){
	echo "$(date +'%F %T')" "$@"
}

if [[ -d ${ODIR} ]]; then
	rm -rf ${ODIR}
fi
# mkdir -p ${ODIR}

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
)

{ cat <<EOF
set -e
set -x
cd ~
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
EOF
} | docker run -i --name ${CONT} --hostname ${CONT} \
	${IMG} "/bin/bash"

atexit() {
	docker rm ${CONT}
}
trap atexit EXIT

if (( $? )); then
	LOG "ldms-samp/ovis-build.sh FAILED!!!"
	exit -1
fi

SRC="${CONT}:/opt/ovis"
DST="${ODIR}"
LOG "Copying ${SRC} to ${DST}"
docker cp ${SRC} ${DST}
RC=$?
LOG "Exiting, rc: ${RC}"
exit ${RC}
