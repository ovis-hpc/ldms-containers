#!/bin/bash

USAGE=$( cat <<EOF
$(basename $0) -o,--ovis OVIS_DIR
                     [--ovis-repo GIT_REPO] [--ovis-branch GIT_REF]
		     [--sos-repo GIT_REPO] [--sos-branch GIT_REF]
		     [--maestro-repo GIT_REPO] [--maestro-branch GIT_REF]

Descriptions:
    Build OVIS binaries from the specified sources with 'ovishpc/ldms-dev'
    container image and copy the OVIS binaries to the specified '--ovis'
    directory.
EOF
)

SCRIPT_DIR=$(dirname $0)
cd ${SCRIPT_DIR}
SCRIPT_DIR=${PWD} # get the full path

# Work from the top dir
cd ../
SRCDIR=${PWD}
source config.sh

if [[ -t 1 ]]; then
	# Enable color for terminal
	RST='\e[0m'
	RED='\e[31m'
	YLW='\e[33m'
fi

# Simple logging functions
_LOG() {
	local _TS=$(date -Iseconds)
	echo -e $(date -Iseconds) "$@"
}

_INFO() {
	_LOG "${YLW}INFO:${RST}" "$@"
}

_ERROR() {
	_LOG "${RED}ERROR:${RST}" "$@"
}

_ERROR_EXIT() {
	_ERROR "$@"
	exit -1
}

# Parameters
OVIS=${OVIS:-}
OVIS_REPO=${OVIS_REPO:-https://github.com/ovis-hpc/ovis}
OVIS_BRANCH=${OVIS_BRANCH:-OVIS-4}
SOS_REPO=${SOS_REPO:-https://github.com/ovis-hpc/sos}
SOS_BRANCH=${SOS_BRANCH:-SOS-6}
MAESTRO_REPO=${MAESTRO_REPO:-https://github.com/ovis-hpc/maestro}
MAESTRO_BRANCH=${MAESTRO_BRANCH:-master}
BUILD_CONT=${BUILD_CONT:-ldms-cont-ovis-build}
BUILD_IMG=${BUILD_IMG:-ovishpc/ldms-dev}
DEBUG=

PREFIX=${PREFIX:-/opt/ovis}
PREFIX_UI=${PREFIX_UI:-${PREFIX}/ui}

opt2var() {
	local V=$1
	V=${V#--}
	V=${V//-/_}
	V=${V^^}
	echo $V
}

handle_opt() {
	local NAME=$1
	local L=$(opt2var $1)
	local R=$2
	[[ -n "$R" ]] || _ERROR_EXIT "$NAME requires an argument"
	eval ${L}=${R}
}

# convert --arg=value to --arg "value"
ARGS=( )
for X in "$@"; do
	if [[ "$X" == --*=* ]]; then
		ARGS+=( "${X%%=*}" "${X#*=}" )
	else
		ARGS+=( "$X" )
	fi
done
set -- "${ARGS[@]}"

while (($#)); do
	case "$1" in
	-o|--outdir)
		handle_opt --outdir $2
		shift
		;;
	--ovis-repo|--ovis-branch|--sos-repo|--sos-branch|--maestro-repo|--maestro-branch)
		handle_opt $1 $2
		shift
		;;
	--debug)
		DEBUG=1
		;;
	-h|-?|--help)
		cat <<<"$USAGE"
		exit 0
		;;
	*)
		_ERROR_EXIT "Unknown option: $1"
		;;
	esac
	shift
done

[[ -n "$OVIS" ]] || _ERROR_EXIT "'-o OVIS_DIR' option is required"

_INFO "==== Parameter Info ============================================="
for X in OVIS {OVIS,SOS,MAESTRO}_{REPO,BRANCH} ; do
	_INFO "$X: ${!X}"
done
_INFO "================================================================="

# Check if the container has already existed
CONT_PS=( $(docker ps -a --format '{{.Names}}' --filter "name=${BUILD_CONT}") )
if ((${#CONT_PS})); then
	# BUILD_CONT has already been created
	if [[ -z "${DEBUG}" ]]; then
		_ERROR_EXIT "${BUILD_CONT} build container existed. Please remove the container."
	fi

	# We are in debug mode

	_INFO "${BUILD_CONT} existed"
	# determine if it is running
	CONT_PS=( docker ps --format '{{.Names}}' --filter "name=${BUILD_CONT}" )
	if ((${#CONT_PS})); then
		_INFO "${BUILD_CONT} is running"
	else
		docker start ${BUILD_CONT} \
		|| _ERROR_EXIT "Cannot start container: ${BUILD_CONT}"
	fi
else
	mkdir -p ${SRCDIR}/root
	docker run -itd --name ${BUILD_CONT} --hostname ${BUILD_CONT} \
		   -v ${SRCDIR}/root:/root:rw \
		   ${BUILD_IMG} /bin/bash
fi

{ cat << EOF
set -e
[[ -z "$DEBUG" ]] || set -x
cd ~
rm -rf *

mkdir -p ovis sos maestro

pushd ovis
git init .
git remote add origin ${OVIS_REPO}
git fetch origin ${OVIS_BRANCH}
git checkout -b build FETCH_HEAD
popd # ovis

pushd sos
git init .
git remote add origin ${SOS_REPO}
git fetch origin ${SOS_BRANCH}
git checkout -b build FETCH_HEAD
popd # sos

pushd maestro
git init .
git remote add origin ${MAESTRO_REPO}
git fetch origin ${MAESTRO_BRANCH}
git checkout -b build FETCH_HEAD
popd # maestro

echo "========== maestro ======================================================"
pushd maestro
pip3 install --prefix ${PREFIX} .
pushd ${PREFIX}
if [[ -d local ]]; then
	mv local/* ./
	rmdir local
fi
popd # ${PREFIX}
popd # maestro
echo "-------------------------------------------------------------------------"

echo "========== sos =========================================================="
pushd sos
./autogen.sh
mkdir build
pushd build
../configure --prefix ${PREFIX} ${SOS_OPTIONS[@]}
make
make install-strip
popd # build
popd # sos
echo "-------------------------------------------------------------------------"

echo "========== ovis ========================================================="
pushd ovis
./autogen.sh
mkdir build
pushd build
../configure --prefix ${PREFIX} ${OVIS_OPTIONS[@]}
make
make install-strip
popd # build
popd # ovis
echo "-------------------------------------------------------------------------"

if [[ -n "${NUMSOS_REPO}" ]]; then
echo "========== numsos ======================================================="
  mkdir -p numsos
  pushd numsos
  git init .
  git remote add origin ${NUMSOS_REPO}
  git fetch origin ${NUMSOS_BRANCH}
  git checkout -b build FETCH_HEAD
  ./autogen.sh
  mkdir -p build
  pushd build
  ../configure --prefix=${PREFIX} --with-sos=${PREFIX} ${NUMSOS_OPTIONS[@]} PYTHON=python3
  make
  make install
  popd # build
  popd # numsos
echo "-------------------------------------------------------------------------"
fi

if [[ -n "${SOSDBUI_REPO}" ]]; then
echo "========== sosdb-ui ====================================================="
  mkdir -p sosdb-ui
  pushd sosdb-ui
  git init .
  git remote add origin ${SOSDBUI_REPO}
  git fetch origin ${SOSDBUI_BRANCH}
  git checkout -b build FETCH_HEAD
  ./autogen.sh
  mkdir -p build
  pushd build
  ../configure --prefix ${PREFIX_UI} ${SOSDBUI_OPTIONS[@]}
  make
  make install
  popd # build
  popd # sosdb-ui
echo "-------------------------------------------------------------------------"
fi

if [[ -n "${SOSDBGRAFANA_REPO}" ]]; then
echo "========== sosdb-grafana ================================================"
  mkdir -p sosdb-grafana
  pushd sosdb-grafana
  git init .
  git remote add origin ${SOSDBGRAFANA_REPO}
  git fetch origin ${SOSDBGRAFANA_BRANCH}
  git checkout -b build FETCH_HEAD
  ./autogen.sh
  mkdir -p build
  pushd build
  ../configure --prefix ${PREFIX_UI} ${SOSDBGRAFANA_OPTIONS[@]}
  make
  make install
  popd # build
  popd # sosdb-grafana
echo "-------------------------------------------------------------------------"
fi
EOF
} | docker exec -i ${BUILD_CONT} /bin/bash

RC=$?

if (($RC == 0)); then
	mkdir -p ${OVIS}
	docker cp ${BUILD_CONT}:${PREFIX} - | tar x --strip-components=1 -C ${OVIS}
fi

if [[ -z "${DEBUG}" ]]; then
	docker kill ${BUILD_CONT}
	docker rm ${BUILD_CONT}
fi

exit $RC
