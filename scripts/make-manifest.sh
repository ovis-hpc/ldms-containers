#!/bin/bash

USAGE=$( cat <<EOF
$(basename $0) [ -t SRC_TAG ] [ -T DST_TAG ]

Options:
    -t SRC_TAG
	The SRC_TAG as a base tag for pulling corresponding images. See
	Descriptions below. If not specified (in config.sh or in this option),
	the default is 'latest'.
    -T DST_TAG
        The TGT_TAG to tag the manifests. If not specified, it is set to
	SRC_TAG.

Descriptions:
    The script docker-pull ovishpc/ldms-{samp,agg,maestro,ui,grafana,storage}
    from docker hub with tags \${SRC_TAG}-amd64 and  \${SRC_TAG}-arm64
    and make the corresponding manifests with tag \${DST_TAG}. In other
    words, it does the following
        for X in ovishpc/ldms-{samp,agg,maestro,ui,grafana,storage} ; do
	  docker pull \${X}:\${SRC_TAG}-amd64
	  docker pull \${X}:\${SRC_TAG}-arm64
          docker manifest ...
	done
   This is to make an image supporting both amd64 and arm64 under the same image
   name (manifest).


**** REMARK ****
    Make sure that the ovishpc/ldms-*:\${SRC_TAG}-amd64 and
    ovishpc/ldms-*:\${SRC_TAG}-arm64 on hub.docker.com are up-to-date.
    The manifests are built based on those *-amd64 and *-arm64 images on the
    docker hub.
EOF
)

set -e

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
	-t)
		handle_opt --manifest-src-tag $2
		shift
		;;
	-T)
		handle_opt --manifest-dst-tag $2
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

MANIFEST_SRC_TAG=${MANIFEST_SRC_TAG:-latest}
MANIFEST_DST_TAG=${MANIFEST_DST_TAG:-${MANIFEST_SRC_TAG}}

for X in ${MANIFEST_IMAGES[*]} ; do
	M=${X}:${MANIFEST_SRC_TAG}
	TGT=${X}:${MANIFEST_DST_TAG}
	_INFO "==== ${M} ===="
	for A in ${MANIFEST_ARCHS[*]}; do
		_INFO "pulling ${M}-${A}"
		docker pull ${M}-${A}
	done
	set -x
	docker manifest rm ${TGT} || true
	OPT="-a ${M}"
	docker manifest create ${TGT} ${MANIFEST_ARCHS[*]/#/${OPT}-}
	docker manifest push ${TGT}
	set +x
done
