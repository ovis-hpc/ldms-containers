#!/bin/bash
#
# ldmscon2023-cont-cluster.sh
#

USAGE=$( cat <<EOF
Synopsis:
  $(basename $0) create|run|start|stop|rm CLUSTER_NAME
        [ -n,--num NUMBER_OF_NODES ] [ -v,--volume SRC:DST:MODE ]
        [ --sshd|--no-sshd ] [ --assets-dir ASSETS_DIR ]
	[ --sshd-addr SSHD_ADDR ] [ --image IMAGE ]

Descriptions:
  This is a script to manage cluster of containers in a single docker node -- to
  emulate N-node cluster.

  'create' command creates the container cluster by 1) creates docker network of
  the name <CLUSTER_NAME> and 2) creates <NUMBER_OF_NODES> containers and add
  them into <CLUSTER_NAME> docker network. The options that apply on 'create'
  are described as follows:

    -n,--num NUMBER_OF_NODES
        The number of nodes.

    -v,--volume SRC:DST:MODE
        The volume option for 'docker create'

    --sshd,--no-sshd
        Enable or disable sshd usage.

    --asset-dir ASSET_DIR
        A directory that holds data (assets) for the docker cluster.

    --sshd-addr SSHD_ADDR
	Host's IP Address to expose sshd (port 22) in the last container to the
	host network (the last container being the head node of the cluster).

  'start' command starts the containers in the cluster.

  'run' command does 1) 'create' and then 2) 'start'

  'stop' command stops the contianers in the cluster (does not remove them).

  'rm' command stops and remove the containers in the cluster, as well as remove
  the docker network created for the cluster.

  The default IMAGE is "ovishpc/ldmscon2023".
EOF
)

SCRIPT_DIR=$(dirname $0)
pushd ${SCRIPT_DIR} >/dev/null
SCRIPT_DIR=${PWD} # get the full path
popd >/dev/null

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

# Parameters
NUM=4
VOLUMES=( )
SSHD=1
CLUSTER=
IMAGE=ovishpc/ldmscon2023
SSHD_DIR=
SSHD_ADDR=

opt2var() {
	local V=$1
	V=${V#--} # remove leading '--'
	V=${V//-/_} # substitute all '-' with '_'
	V=${V^^} # uppercase
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

OP=
while (($#)); do
	case "$1" in
	create|run|rm|stop|start)
		OP=$1
		handle_opt --cluster $2
		shift
		;;
	-a|--assets-dir)
		handle_opt --asset-dir $2
		shift
		;;
	-n|--num)
		handle_opt --num $2
		shift
		;;
	-i|--image)
		handle_opt --image $2
		shift
		;;
	-v|--volume)
		VOLUMES+=( -v "$2" )
		shift
		;;
	--sshd)
		SSHD=1
		;;
	--no-sshd)
		SSHD=
		;;
	--sshd-addr)
		handle_opt --sshd-addr $2
		shift
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

[[ -n "$OP" ]] || _ERROR_EXIT "'run', 'rm' 'start', or 'stop' command is required"
[[ -n "$CLUSTER" ]] ||  _ERROR_EXIT 'CLUSTER_NAME is required'
(( NUM )) || _ERROR_EXIT '-n NUM must be greater than 0'

ASSETS_DIR=${ASSETS_DIR:-assets/${CLUSTER}}
mkdir -p ${ASSETS_DIR} || _ERROR_EXIT "Cannot create directory: ${ASSETS_DIR}"

get_nodes() {
	OUT=($( docker ps -a -f network=${CLUSTER} --format "NODES[{{.Names}}]='{{.State}}'" ))
	unset NODES
	declare -Ag NODES
	for CMD in "${OUT[@]}" ; do
		eval "${CMD}"
	done
}

get_nodes

do_create() {
	_INFO "Creating network ..."
	DNET=( $(docker network ls -f name=${CLUSTER} --format '{{.Name}}' | grep -x ${CLUSTER}) )
	if [[ -z "${DNET}" ]]; then
		docker network create --attachable -d overlay ${CLUSTER} || \
			_ERROR_EXIT "'docker network create' error"
	fi
	set -e
	_INFO "Creating containers ..."
	for ((I=1; I<=NUM; I++)); do
		NAME=${CLUSTER}-${I}
		PUBLISH=
		if (( I == NUM )) && [[ -n "${SSHD_ADDR}" ]]; then
			PUBLISH=( -p ${SSHD_ADDR}:22:22 )
		fi
		# Create container if not existed
		[[ -n "${NODES[${NAME}]}" ]] || \
			docker create -it --name ${NAME} --hostname ${NAME} \
					-u root --net ${CLUSTER} \
					"${VOLUMES[@]}" \
					${PUBLISH[@]} \
					${IMAGE}
	done
	get_nodes # update node list
	_INFO "Finished creating containers"
	set +e
}

do_run() {
	do_create
	do_start
}

do_start() {
	set -e
	_INFO "Starting containers ..."
	for NAME in "${!NODES[@]}"; do
		[[ "${NODES[${NAME}]}" == "running" ]] || docker start ${NAME}
	done
	do_sshd_init
	do_sshd_start
	_INFO "Finished starting containers"
	set +e
}

do_stop() {
	set -e
	_INFO "Stopping containers ..."
	for NAME in "${!NODES[@]}"; do
		[[ "${NODES[${NAME}]}" != "running" ]] || docker stop ${NAME}
	done
	_INFO "Finished stopping containers"
	set +e
}

do_rm() {
	set -e
	_INFO "Removing containers ..."
	for NAME in "${!NODES[@]}"; do
		docker rm -f ${NAME}
	done
	_INFO "Finished removing containers"
	_INFO "Removing network ..."
	docker network rm ${CLUSTER}
	_INFO "Finished removing network"
	set +e
}

cluster_cp() {
	SRC=$1 # path in host
	DST=$2 # path in container
	for NAME in ${!NODES[@]} ; do
		docker cp ${SRC} ${NAME}:${DST}
		docker exec ${NAME} chown root:root -R ${DST}
	done
}

do_sshd_init() {
	(( ${SSHD} )) || return 0
	_INFO "Initializing SSH and SSHD"
	# part of start, we need containers to be running
	set -e
	SSH_DIR=${ASSETS_DIR}/ssh
	mkdir -p ${SSH_DIR}
	for KTYPE in rsa ecdsa ed25519 ; do
		KEY_FILE=${SSH_DIR}/ssh_host_${KTYPE}_key
		[[ -e "${KEY_FILE}" ]] || {
			ssh-keygen -t ${KTYPE} -f ${KEY_FILE} -N "" -C "host"
		}
		cluster_cp ${KEY_FILE} /etc/ssh/
		cluster_cp ${KEY_FILE}.pub /etc/ssh/
	done
	KEY_FILE="${SSH_DIR}/id_rsa"
	[[ -e "${KEY_FILE}" ]] || {
		ssh-keygen -t rsa -f ${KEY_FILE} -N "" -C "root"
	}
	cluster_cp ${KEY_FILE} /root/.ssh/
	cluster_cp ${KEY_FILE}.pub /root/.ssh/
	cp ${KEY_FILE}.pub ${SSH_DIR}/authorized_keys
	chmod 600 ${SSH_DIR}/authorized_keys
	cluster_cp ${SSH_DIR}/authorized_keys /root/.ssh/
	# make known_hosts file
	KNOWN_HOSTS=${SSH_DIR}/known_hosts
	cat > ${KNOWN_HOSTS} <<-EOF
	$(
	  for NAME in ${!NODES[@]}; do
	    echo -n "${NAME} "
	    cat ${SSH_DIR}/ssh_host_ed25519_key.pub
	  done
	)
	EOF
	cluster_cp ${KNOWN_HOSTS} /root/.ssh/known_hosts
	_INFO "Finished SSH and SSHD initialization"
	set +e
}

do_sshd_start() {
	(( ${SSHD} )) || return 0
	_INFO "Starting sshd"
	set -e
	for NAME in ${!NODES[@]}; do
		{ cat <<-EOF
		sudo -u munge munged
		touch /var/run/utmp
		cd /etc/ssh/sshd_config.d/
		LIST=( HOSTNAME PATH PYTHONPATH ZAP_LIBPATH
			LDMSD_PLUGIN_LIBPATH LDMS_AUTH_FILE )
		echo -n SetEnv > env.conf
		for X in \${LIST[*]}; do
			echo -n " \\"\${X}=\${!X}\\"" >> env.conf
		done
		EOF
		} | docker exec -i ${NAME} bash -l
		docker exec ${NAME} /usr/sbin/sshd
	done
	set +e
	_INFO "sshd started successfully"
}

eval do_${OP}
