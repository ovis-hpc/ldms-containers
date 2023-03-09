#!/bin/bash

USAGE=$( cat <<EOF
$(basename $0) -c,--context CONTEXT_DIR

Descriptions:
    Copy libserdes from 'ovishpc/ldms-dev' into the CONTEXT_DIR. The CONTEXT_DIR
    is treated as _ROOT_ (as in chroot).
EOF
)

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

BUILD_CONT=${BUILD_CONT:-ldms-cont-ovis-build}
BUILD_IMG=${BUILD_IMG:-ovishpc/ldms-dev}

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
	-c|--context)
		handle_opt --context $2
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

if [[ -z "${CONTEXT}" ]] ; then
	_ERROR_EXIT "--context CONTEXT_DIR is required"
fi

CONTEXT=$( realpath ${CONTEXT} )

SCRIPT_DIR=$(dirname $0)
cd ${SCRIPT_DIR}
SCRIPT_DIR=${PWD} # get the full path

# Work from the top dir
cd ../
SRCDIR=${PWD}
source config.sh
_INFO "==== Parameter Info ============================================="
for X in CONTEXT ; do
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
else
	mkdir -p ${SRCDIR}/root
	docker run -itd --name ${BUILD_CONT} --hostname ${BUILD_CONT} \
		   ${BUILD_IMG} /bin/bash
fi

at_exit() {
	if [[ -z "${DEBUG}" ]]; then
		docker rm -f ${BUILD_CONT}
	fi
}
trap at_exit EXIT

{ cat << EOF
set -e
mkdir -p /context
cd ~/libserdes
make DESTDIR=/context install
EOF
} | docker exec -i ${BUILD_CONT} /bin/bash
RC=$?

if (($RC == 0)); then
	mkdir -p ${CONTEXT}
	docker cp ${BUILD_CONT}:/context - | tar x --strip-components=1 -C ${CONTEXT}
fi
