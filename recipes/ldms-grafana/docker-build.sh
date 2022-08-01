#!/bin/bash

USAGE=$( cat <<EOF
./docker-build.sh [--dsosds PATH]
EOF
)

# script dir
SCRIPT_DIR=$(dirname $0)
cd ${SCRIPT_DIR}
SCRIPT_DIR=${PWD}
# Work from the top src dir
cd ${SCRIPT_DIR}/../../
NAME=ovishpc/ldms-grafana
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
	--dsosds)
		shift
		DSOSDS=$1
		;;
	*)
		cat <<<"$USAGE"
		exit -1
		;;
	esac
	shift
done

[[ -n "${DSOSDS}" ]] || _ERROR_EXIT "--dsosds PATH is required"
[[ -e "${DSOSDS}" ]] || _ERROR_EXIT "'${DSOSDS}' ovis directory does not exist."\
			"Please build it with 'scripts/build-dsosds.sh'"
[[ -d "${DSOSDS}" ]] || _ERROR_EXIT "'${DSOSDS}' is not a directory"

echo "Building Docker Image: ${NAME}"
pushd ${DSOSDS}
tar c * \
    -C ${SCRIPT_DIR} Dockerfile \
    | docker build -t ${NAME} -
