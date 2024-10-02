#!/bin/bash

D=$(dirname $0)
cd ${D}/.. # work from the top srcdir
. config.sh

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
	--*)
		handle_opt $1 $2
		shift
		;;
	*)
		_ERROR_EXIT "Unknown option: $1"
		;;
	esac
	shift
done

BUILD_TAG=${BUILD_TAG:?BUILD_TAG variable is not set}

[[ ${#PUSH_SIGN_LIST[*]} -gt 0 ]] ||
	PUSH_SIGN_LIST=(
		ovishpc/ldms-dev
		ovishpc/ldms-samp
		ovishpc/ldms-agg
		ovishpc/ldms-maestro
		ovishpc/ldms-web-svc
		ovishpc/ldms-grafana
		ovishpc/ldms-storage
	)

_INFO "PUSH_SIGN_LIST: ${PUSH_SIGN_LIST[*]}"

for X in "${PUSH_SIGN_LIST[@]}"; do
	OBJ="${X}:${BUILD_TAG}"
	_INFO "==== ${OBJ} ===="
	docker push ${OBJ}
	docker trust revoke ${OBJ}
	docker trust sign ${OBJ}
	_INFO "--------------------------------"
done
