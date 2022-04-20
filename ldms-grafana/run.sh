#!/bin/bash

set -e

D=$(realpath $(dirname $0))

. ${D}/../config.sh

# change working directory to the script's home
cd ${D}

USAGE=$( cat <<EOF
SYNOPSIS
    $0 [--name NAME] [--volume|-v HOST_PATH:CONT_PATH:OPT]

EXAMPLE
    $0 --name grafana

FILE
    $(realpath ${D}/conf/grafana.ini)

OPTIONS
    --name NAME
        The container name. This will also be used as a part of the socket
	directory ('${D}/socket/\${NAME}/') to export grafana socket
	from the container.

    -v|--volume HOST_PATH:CONT_PATH:OPT
	This option is passed through to 'docker-run' command to specify the
	file or directory to bind-mount in the container. The 'volume' option
	can be specified multiple times and is collective.
EOF
)

NAME=grafana
IMG=ovishpc/ldms-grafana
VOLUMES=( )
VOL_OPTS=( )

while (( $# )); do
	case "$1" in
	--name )
		shift
		NAME=${1}
		;;
	--name=* )
		NAME=${1#--name=}
		;;
	--volume=* )
		# do not save arg for ldmsd-conf
		VOLUMES+=( "${1#--volume=}" )
		;;
	--volume|-v )
		# do not save arg for ldmsd-conf
		shift
		VOLUMES+=( "$1" )
		;;
	-h|--help|-? )
		cat <<<"$USAGE"
		exit 0
		;;
	* )
		echo "Unrecognize option: $1"
		echo "    '$0 -h' for more information"
		exit -1
		;;
	esac
	shift
done

for V in "${VOLUMES[@]}"; do
	VOL_OPTS+=( "-v" "$V" )
done

SOCKDIR=${D}/sock/${NAME}
mkdir -p ${SOCKDIR}
chmod 777 ${SOCKDIR}

OPTIONS=(
	-d --rm --name ${NAME} --hostname ${NAME}
	-v ${D}/conf/grafana.ini:/etc/grafana/grafana.ini
	-v ${SOCKDIR}:/sock
	-v ${D}/scripts-grafana/start.sh:/docker/start.sh
	"${VOL_OPTS[@]}"
	--network ${NET}
	${IMG}
	)

docker run "${OPTIONS[@]}"
