#!/bin/bash
#
# recipes/ldmscon2023/docker-build.sh

NAME=ovishpc/ldmscon2023

USAGE=$( cat <<EOF
./docker-build.sh [--ovis PATH]
EOF
)

# script dir
SCRIPT_DIR=$(dirname $0)
cd ${SCRIPT_DIR}
SCRIPT_DIR=${PWD}
# Get the config from the top source dir
cd ${SCRIPT_DIR}/../../
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
	--ovis)
		shift
		OVIS=$1
		;;
	*)
		cat <<<"$USAGE"
		exit -1
		;;
	esac
	shift
done

[[ -n "${OVIS}" ]] || _ERROR_EXIT "--ovis PATH is required"
[[ -e "${OVIS}" ]] || _ERROR_EXIT "'${OVIS}' ovis directory does not exist."\
			"Please build it with 'scripts/build-ovis-binaries.sh'"
[[ -d "${OVIS}" ]] || _ERROR_EXIT "'${OVIS}' is not a directory"

NAMES=($( cd ${OVIS} ; ls ))

_INFO "Building docker image: ${NAME}"
CTXT_DIR=${SCRIPT_DIR}/context
mkdir -p ${CTXT_DIR}
rm -rf ${CTXT_DIR}/*
pushd ${OVIS}
tar -c * \
    -C ${SCRIPT_DIR} Dockerfile | tar -C ${CTXT_DIR} -x
pushd ${CTXT_DIR}
docker build -t ${NAME} .
