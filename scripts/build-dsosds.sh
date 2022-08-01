#!/bin/bash

USAGE=$( cat <<EOF
$(basename $0) -o,--dsosds-out OUT_DIR
                     [--dsosds-repo GIT_REPO] [--dsosds-branch GIT_REF]

Descriptions:
    Build dsosds, a grafana plugin for accessing dsos. The OUT_DIR is the output
    directory where the plugin files (and NodeJS dependencies) will be put in.
EOF
)

SCRIPT_DIR=$(dirname $0)
cd ${SCRIPT_DIR}
SCRIPT_DIR=${PWD} # get the full path

# Work from the top dir
cd ../
SRCDIR=${PWD}
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

# Parameters
DSOSDS=${DSOSDS:-}
DSOSDS_REPO=${DSOSDS_REPO:-}
DSOSDS_BRANCH=${DSOSDS_BRANCH:-}
DSOSDS_BUILD_CONT=${DSOSDS_BUILD_CONT:-dsosds-build}
DSOSDS_BUILD_IMG=${DSOSDS_BUILD_IMG:-ovishpc/ldms-dev}
DEBUG=

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
	-o|--dsosds-out)
		handle_opt --dsosds-out $2
		shift
		;;
	--dsosds-repo|--dsosds-branch)
		handle_opt $1 $2
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

if [[ -z "${DSOSDS_REPO}" ]]; then
	_INFO "DSOSDS_REPO is not specified .. skip dsosds build"
	exit 0
fi

[[ -n "${DSOSDS}" ]] || _ERROR_EXIT "'-o DSOSDS' option is required"
mkdir -p "${DSOSDS}"
DSOSDS=$( realpath ${DSOSDS} )

_INFO "==== Parameter Info ============================================="
for X in DSOSDS_{OUT,REPO,BRANCH} ; do
	_INFO "$X: ${!X}"
done
_INFO "================================================================="

# Check if the container has already existed
CONT_PS=( $(docker ps -a --format '{{.Names}}' --filter "name=${DSOSDS_BUILD_CONT}") )
if ((${#CONT_PS})); then
	# DSOSDS_BUILD_CONT has already been created
	if [[ -z "${DEBUG}" ]]; then
		_ERROR_EXIT "${DSOSDS_BUILD_CONT} build container existed. Please remove the container."
	fi

	# We are in debug mode

	_INFO "${DSOSDS_BUILD_CONT} existed"
	# determine if it is running
	CONT_PS=( docker ps --format '{{.Names}}' --filter "name=${DSOSDS_BUILD_CONT}" )
	if ((${#CONT_PS})); then
		_INFO "${DSOSDS_BUILD_CONT} is running"
	else
		docker start ${DSOSDS_BUILD_CONT} \
		|| _ERROR_EXIT "Cannot start container: ${DSOSDS_BUILD_CONT}"
	fi
else
	mkdir -p ${DSOSDS}
	docker run -itd --name ${DSOSDS_BUILD_CONT} --hostname ${DSOSDS_BUILD_CONT} \
		   -v ${DSOSDS}:${DSOSDS}:rw \
		   ${DSOSDS_BUILD_IMG} /bin/bash
fi

# prep npm temp build dir
#{ cat <<EOF
#mkdir /.npm
#chown ${UID}:${UID} /.npm
#EOF
#} | docker exec -i ${DSOSDS_BUILD_CONT} /bin/bash

{ cat <<EOF
cd ${DSOSDS}
rm -rf * .git/ .npm/
set -e
echo "==== Checking out ${DSOSDS_REPO} - ${DSOSDS_BRANCH} ===="
git init .
git remote add origin ${DSOSDS_REPO}
git fetch origin ${DSOSDS_BRANCH}
git checkout -b out FETCH_HEAD
echo "==== Installing the dependencies ===="
mkdir .npm
npm install --cache ${DSOSDS}/.npm --production
EOF
} | docker exec -u ${UID} -i ${DSOSDS_BUILD_CONT} /bin/bash

RC=$?

if [[ -z "${DEBUG}" ]]; then
	docker rm -f ${DSOSDS_BUILD_CONT}
fi

exit $RC
