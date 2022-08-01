#!/bin/bash
#
# recipes/ldms-maestro/docker-build.sh

USAGE=$( cat <<EOF
./docker-build.sh [--ovis PATH]
EOF
)

# script dir
SCRIPT_DIR=$(dirname $0)
cd ${SCRIPT_DIR}
SCRIPT_DIR=${PWD}
# Work from the top src dir
cd ${SCRIPT_DIR}/../../
NAME=ovishpc/ldms-maestro
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
pushd ${OVIS}
OVIS_LIBS=($(
	ls lib/lib* | grep -Ev 'lib(key|sos|dsos|idx|ods|tirpc|ldmsd)'
))
tar c bin/maestro* ${OVIS_LIBS[*]} lib/python* lib/ovis-ldms/libzap* etc \
    -C ${SCRIPT_DIR} Dockerfile \
    | docker build -t ${NAME} -
