#!/bin/bash

D=$(dirname $0)

USAGE=$( cat <<EOF
SYNOPSIS
    $0 [--name NAME] [--volume|-v HOST_PATH:CONT_PATH:OPT] [--conf PATH]
	[--port LISTEN_PORT] [--samp "SAMPLER_PLUGIN_LIST"]
	[--prdcr "PRDCR_LIST"] [--strgp "SCHEMA_LIST"]
	[--store-path STORE_PATH] [--interval USEC] [--offset USEC]
	[--name LDMSD_NAME] [--compid NUM]

EXAMPLE
    # docker-run samp-01 container with vmstat and meminfo
    $0 --name samp-01 --samp "vmstat meminfo"

FILE
    $(realpath ${D}/../config.sh)

DESCRIPTION
    This is a convenient 'docker-run' wrapper to run ldmsd in a container.

    '--name' option is used to supply docker container name, docker container
    hostname, and ldmsd daemon name inside the container.

    '--volume' (-v) option is passed through to 'docker-run' command to specify
    the file or directory to bind-mount in the container. The 'volume' option
    can be specified multiple times and is collective.

    If the '--conf' option is given, the specified configuration file is used as
    the ldmsd configuration file in the container (through docker read-only
    bind-mount). In such case, the 'ldmsd-conf' (config generator) will NOT be
    executed.

    If the '--conf' option is not given, 'ldmsd-conf' will generate
    configuration file inside the container. The CLI options provided to this
    script will be passed through to 'ldmsd-conf' (except '--volume' option).
    The description of the ldmsd-conf options is as the following:

LDMSD-CONF-OPTIONS
    --port LISTEN_PORT   (default: 411)
        The port to listen to.

    --name LDMSD_NAME    (default: \$HOSTNAME)
	The '-n' (name) option supplied to ldmsd.

    --samp "SAMPLER_PLUGIN_LIST"   (default: EMPTY)
	Generate the load, config, start commands for the plugins in the
	"SAMPLER_PLUGIN_LIST". The list is SPACE separated and support Bash
	Brace Expansion (see bash(1) "Brace Expansion" for more info). The
	option can be specified multiple times. In such case, the lists will be
	concatinated together.

    --prdcr "PRDCR_LIST"   (default: EMPTY)
	Generate the prdcr_add, updtr_prdcr_add commands for the producers in
	the "PRDCR_LIST". The list is SPACE separated and support Bash Brace
	Expansion (see bash(1) "Brace Expansion" for more info). The option can
	be specified multiple times. In such case, the lists will be
	concatinated together.

    --strgp "SCHEMA_LIST"   (default: EMPTY)
	Generate the strgp for each of the schema in the SCHEMA_LIST. The list
	is SPACE separated and support Bash Brace Expansion (see bash(1) "Brace
	Expansion" for more info). The option can be specified multiple times.
	In such case, the lists will be concatinated together.

    --store-path STORE_PATH   (default: "/store")
	The 'path' option to store_sos plugin. Note that if the strgp
	SCHEMA_LIST is empty, store_sos won't be loaded.

    --interval USEC   (default: 1000000)
        The "interval" option for sampler or prdcr + updtr.

    --offset USEC   (default: 0)
        The "offset" option for sampler or updtr.

    --compid NUM    (default: numbers in the \$NAME)
        The value to supply to 'component_id' parameter for the sampler config.
EOF
)

. ${D}/../config.sh

NAME=samp
IMG=ovishpc/ldms-samp
CONF=
VOL_OPTS=( )
SAMP_OPTS=( )
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
	--conf=* )
		# do not save arg for ldmsd-conf
		CONF=${1#--conf=}
		;;
	--conf )
		# do not save arg for ldmsd-conf
		shift
		CONF="${1}"
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

for V in "${SAMPLER_PLUGIN_LIST[@]}"; do
	SAMP_OPTS+=( "--samp" "$V" )
done

docker run -d --rm --name=${NAME} --hostname=${NAME} \
	--network=${NET} \
	"${VOL_OPTS[@]}" \
	"${OPT_CAPADDS[@]}" \
	${IMG} "$@" "${SAMP_OPTS[@]}"
