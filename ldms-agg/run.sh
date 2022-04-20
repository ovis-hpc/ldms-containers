#!/bin/bash

D=$(dirname $0)

USAGE=$( cat <<EOF
SYNOPSIS
    $0 [--name NAME] [--volume|-v HOST_PATH:CONT_PATH:OPT] [--conf PATH]
	[--port LISTEN_PORT] [--samp "SAMPLER_PLUGIN_LIST"]
	[--prdcr "PRDCR_LIST"] [--strgp "SCHEMA_LIST"] [--strgp-conf CONF_FILE]
	[--store-path STORE_PATH] [--interval USEC] [--offset USEC]
	[--name LDMSD_NAME] [--compid NUM]

EXAMPLE
    # docker-run agg-11 container, ldms-connecting to samp-01, samp-02, samp-03,
    # samp-04.
    $0 --name agg-11 --prdcr "samp-{01..04}"

    # docker-run agg-21 container with sos store for meminfo and vmstat schemas
    $0 --name agg-21 --prdcr "samp-11" --strgp "meminfo vmstat"

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

    --strgp-conf CONF_FILE  (default: EMPTY)
	The extra storages and storage policies configuration. If the file is
	specified, the content of the file will be appended to the STRGP section
	of the output.

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

NAME=agg
IMG=ovishpc/ldms-agg
CONF=
STRGP_CONF=
CONT_STRGP_CONF=/opt/ovis/etc/strgp.conf

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
		# do not save arg for conf
		CONF=${1#--conf=}
		;;
	--conf )
		# do not save arg for conf
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
	--strgp-conf=* )
		# STRGP_CONF will be mounted at /opt/ovis/etc/strgp.conf
		STRGP_CONF=${1#--strgp-conf=}
		SAVED_ARGS+=( "--strgp-conf" "${CONT_STRGP_CONF}" )
		;;
	--strgp-conf )
		shift
		STRGP_CONF=${1}
		SAVED_ARGS+=( "--strgp-conf" "${CONT_STRGP_CONF}" )
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

VOL_OPTS=( )
for V in "${VOLUMES[@]}"; do
	VOL_OPTS+=( "-v" "$V" )
done

if [[ -n "${STRGP_CONF}" ]]; then
	[[ -f "${STRGP_CONF}" ]] || {
		echo "strgp-conf file not found: '${STRGP_CONF}'"
		exit -1
	}
	STRGP_CONF=$(realpath ${STRGP_CONF})
	VOL_OPTS+=( "-v" "${STRGP_CONF}:${CONT_STRGP_CONF}" )
fi

docker run -d --rm --name=${NAME} --hostname=${NAME} \
	--network=${NET} \
	"${VOL_OPTS[@]}" \
	"${OPT_CAPADDS[@]}" \
	${IMG} "$@"
