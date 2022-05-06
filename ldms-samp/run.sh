#!/bin/bash

D=$(dirname $0)

USAGE=$( cat <<EOF
SYNOPSIS
    $0 [--name NAME] [--no-host-namespaces] [--pdsh "PDSH_TARGETS"]
	[--volume|-v HOST_PATH:CONT_PATH:OPT] [--conf PATH] [--port LISTEN_PORT]
	[--samp "SAMPLER_PLUGIN_LIST"] [--interval USEC] [--offset USEC]
	[--compid NUM]

EXAMPLE
    # docker-run samp-01 container with vmstat and meminfo
    $0 --name samp-01 --samp "vmstat meminfo"

FILE
    $(realpath ${D}/../config.sh)

DESCRIPTION
    This is a convenient 'docker-run' wrapper to run ldmsd in a container with a
    container name specified by '--name NAME'. By default, the ldms-samp
    containers run with '--privileged' and in the host's namespaces (pid,
    network, uts, and ipc) so that the ldmsd in the container has access to
    host's /proc and /sys information. If this is not a desire behavior,
    '--no-host-namespaces' option will disable '--privileged' and all host
    namespaces.

    The 'docker' command is by default executed in the localhost. However, if
    '--pdsh PDSH_TARGETS' option is given, 'pdsh -w PDSH_TARGETS' is used to
    execute docker-run commands remotely using pdsh to help sampler docker
    deployment.

OPTIONS
    --name NAME
	The option is used to supply docker container name, docker container
	hostname, and ldmsd daemon name inside the container.

    --no-host-namespaces
	If this option is given, the container will run WITHOUT --privileged
	option, and will NOT be in host namespaces (pid, network, uts, and ipc).
	Be mindful that in this case some of the /proc and /sys data (e.g.
	/proc/net/dev) will be data specific to the container, not the host's.

	If this option is not given, the container will run WITH --privileged
	option and will be in pid, network, uts and ipc host namespaces so that
	ldmsd can collect host's /proc and /sys metrics.

    --pdsh PDSH_TARGETS
	If this option is given, 'pdsh -w PDSH_TARGETS' is used to execute
	docker-run across hosts in the PDSH_TARGETS. Note that PDSH_TARGETS is
	not the same syntax as Bash Brace Expansion. See pdsh(1) "-w" option and
	"HOSTLIST EXPRESSIONS" section for more information.

    --volume HOST_PATH:CONT_PATH:OPT
	The option is passed through to 'docker-run' command to specify the file
	or directory to bind-mount in the container. The 'volume' option can be
	specified multiple times and is collective.

    --conf PATH
	If the '--conf' option is given, the specified configuration file is
	used as the ldmsd configuration file in the container (through docker
	read-only bind-mount). In such case, the 'ldmsd-conf' (config generator)
	will NOT be executed. In other words, options in 'LDMSD-CONF-OPTIONS'
	are ignored.

	If the '--conf' option is not given, 'ldmsd-conf' will generate
	configuration file inside the container. The CLI options provided to
	this script will be passed through to 'ldmsd-conf' (except '--volume'
	option).  The description of the ldmsd-conf options is as the following:

LDMSD-CONF-OPTIONS
    --name NAME    (default: \$HOSTNAME)
	The NAME is supplied to both 'docker --name NAME', and 'ldmsd -n NAME'
	running inside the container.

    --port LISTEN_PORT   (default: 411)
        The port to listen to.

    --samp "SAMPLER_PLUGIN_LIST"   (default: EMPTY)
	Generate the load, config, start commands for the plugins in the
	"SAMPLER_PLUGIN_LIST". The list is SPACE separated and support Bash
	Brace Expansion (see bash(1) "Brace Expansion" for more info). The
	option can be specified multiple times. In such case, the lists will be
	concatinated together.

    --interval USEC   (default: 1000000)
        The "interval" option for sampler.

    --offset USEC   (default: 0)
        The "offset" option for sampler or updtr.

    --compid NUM    (default: numbers in the \$NAME)
        The value to supply to 'component_id' parameter for the sampler config.
EOF
)

. ${D}/../config.sh

NAME=${HOSTNAME}
IMG=ovishpc/ldms-samp
CONF=
PDSH=
VOL_OPTS=( )
SAMP_OPTS=( )
HOST_NAMESPACES=1
# VOLUMES may be defined in config.sh
[[ "${#VOLUMES[@]}" -gt 0 ]] || VOLUMES=( )

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
	--conf )
		# do not save arg for ldmsd-conf
		shift
		CONF="${1}"
		;;
	--volume|-v )
		# do not save arg for ldmsd-conf
		shift
		VOLUMES+=( "$1" )
		;;
	--samp | --port | --interval | --offset | --compid )
		# pass-through to ldmsd-conf
		SAVED_ARGS+=( "$1" )
		shift
		SAVED_ARGS+=( "$1" )
		;;
	--no-host-namespaces )
		# set to empty string & do not save arg for ldmsd-conf
		HOST_NAMESPACES=
		;;
	--pdsh )
		# do not save arg for ldmsd-conf
		shift
		PDSH="${1}"
		;;
	-h|--help )
		cat <<<"$USAGE"
		exit 0
		;;
	* )
		echo "ERROR: Unrecognized option $1"
		exit -1
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

if [[ -z "$HOST_NAMESPACES" ]]; then
	NS_OPTIONS=( --hostname=${NAME} --network=${NET} )
else
	NS_OPTIONS=( --privileged
		     --pid host
		     --network host
		     --uts host
		     --ipc host )
fi

PDSH_EXEC=( )
if [[ -n "${PDSH}" ]]; then
	PDSH_EXEC=( pdsh -w "${PDSH}" )
fi

"${PDSH_EXEC[@]}" docker run -d --rm --name=${NAME} \
	"${NS_OPTIONS[@]}" \
	"${VOL_OPTS[@]}" \
	"${OPT_CAPADDS[@]}" \
	${IMG} "$@" "${SAMP_OPTS[@]}"
