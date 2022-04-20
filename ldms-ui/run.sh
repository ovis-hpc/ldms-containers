#!/bin/bash

D=$(dirname $0)

USAGE=$( cat <<EOF
SYNOPSIS
    $0 [--name NAME] [--volume|-v HOST_PATH:CONT_PATH:OPT] [--dsosd DSOSD_LIST ]

EXAMPLE
    # docker-run ui container that connects to dsosd on agg-21 and agg-22
    $0 --name ui --dsosd "agg-{21,22}"

FILE
    $(realpath ${D}/../config.sh)

DESCRIPTION
    This is a convenient 'docker-run' wrapper to run UI server in a container.

    '--name' option is used to supply docker container name, and docker
    container hostname.

    '--volume' (-v) option is passed through to 'docker-run' command to specify
    the file or directory to bind-mount in the container. The 'volume' option
    can be specified multiple times and is accumulative.

    '--dsosd' option contains a list of containers that run dsosd. The list is
    space-separated and support Bash Brace Expansion (see bash(1) "Brace
    Expansion" for more info). --dsosd option can be specified multiple times
    and is accumulative.
EOF
)

. ${D}/../config.sh

NAME=ui
IMG=ovishpc/ldms-ui
VOL_OPTS=( )
# VOLUMES may be defined in config.sh
[[ "${#VOLUMES[@]}" -gt 0 ]] || VOLUMES=( )

SAVED_ARGS=( )
# Parse CLI options
while (( $# )); do
	case "$1" in
	--name )
		SAVED_ARGS+=( "$1" )
		shift
		SAVED_ARGS+=( "$1" )
		NAME=${1}
		;;
	--name=* )
		SAVED_ARGS+=( "$1" )
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
	-h|--help )
		cat <<<"$USAGE"
		exit 0
		;;
	* )
		SAVED_ARGS+=( "$1" )
		;;
	esac
	shift
done

# recover the positional parameters
set -- "${SAVED_ARGS[@]}"

if [[ -n "$CONF" ]]; then
	CONF=$(realpath "$CONF")
	VOLUMES+=( "${CONF}:/opt/ovis/etc/ldms.conf:ro" )
fi

for V in "${VOLUMES[@]}"; do
	VOL_OPTS+=( "-v" "$V" )
done

docker run -d --rm --name=${NAME} --hostname=${NAME} \
	--network=${NET} \
	"${VOL_OPTS[@]}" \
	"${OPT_CAPADDS[@]}" \
	${IMG} "$@"
