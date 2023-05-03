#!/bin/bash

USAGE=$( cat <<EOF
$(basename $0) [ -t MANIFEST_TAG ]

Options:
    -t,--tag,--manifest-tag MANIFEST_TAG
        The MANIFEST_TAG to tag the manifests. This is also used as a base tag
	for pulling corresponding images. See Descriptions below. If not
	specified (in config.sh or in this option), the default is 'latest'.

Descriptions:
    The script docker-pull ovishpc/ldms-{samp,agg,maestro,ui,grafana,storage}
    from docker hub with tags \${MANIFEST_TAG}-amd64 and  \${MANIFEST_TAG}-arm64
    and make the corresponding manifests with tag \${MANIFEST_TAG}. In other
    words, it does the following
        for X in ovishpc/ldms-{samp,agg,maestro,ui,grafana,storage} ; do
	  docker pull \${X}:\${MANIFEST_TAG}-amd64
	  docker pull \${X}:\${MANIFEST_TAG}-arm64
          docker manifest ...
	done
   This is to make an image supporting both amd64 and arm64 under the same image
   name (manifest).


**** REMARK ****
    Make sure that the ovishpc/ldms-*:\${MANIFEST_TAG}-amd64 and
    ovishpc/ldms-*:\${MANIFEST_TAG}-arm64 on hub.docker.com are up-to-date.
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
	-t|--tag|--manifest-tag)
		handle_opt --manifest-tag $2
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

MANIFEST_TAG=${MANIFEST_TAG:-latest}

for X in ovishpc/ldms-{samp,agg,maestro,ui,grafana,storage} ; do
	M=${X}:${MANIFEST_TAG}
	_INFO "==== ${M} ===="
	docker pull ${M}-amd64
	docker pull ${M}-arm64
	set -x
	docker manifest rm ${M}
	docker manifest create ${M} -a ${M}-amd64 -a ${M}-arm64
	docker manifest push ${M}
	set +x
done
