#!/bin/bash

# Run from script dir
D=$(dirname $0)
cd $D
SCRIPT_DIR=${PWD}
TOP_DIR=${SCRIPT_DIR}/../../

. ${TOP_DIR}/config.sh

export BUILD_TAG

DEBUG=

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

on_exit() {
	(( $DEBUG )) || {
		_INFO "Cleaning up ..."
		./cleanup.sh
		_INFO "DONE"
	}
}
trap on_exit EXIT

mkdir -p store

docker network ls |& grep 'test\s\+overlay\s\+swarm' >/dev/null || {
	docker network create --attachable -d overlay test || \
		_ERROR_EXIT "Cannot create docker network 'test'"
}

wait_running() {
	local CONT=$1
	local TIME=${2:-5} # 5 sec by default
	local INTERVAL=${3:-0.5}

	T0=$( date +%s )
	T1=$((T0 + TIME))
	while (( T0 < T1 )); do
		STATE=$(docker inspect -f {{.State.Running}} ${CONT} )
		if [[ "$STATE" == "true" ]]; then
			return 0
		fi
		sleep ${INTERVAL}
		T0=$( date +%s )
	done
	return -1
}

[[ -f munge.key ]] || {
        touch munge.key
	chmod 600 munge.key
        {
cat <<EOF
chown munge:munge /etc/munge.key
python3 -c 'print("0"*1024)' > /etc/munge.key
chmod 600 /etc/munge.key
EOF
        } | docker run --rm -i --entrypoint /bin/bash \
                -v ${PWD}/munge.key:/etc/munge.key:rw \
                ovishpc/ldms-agg:${BUILD_TAG}
} || {
        _ERROR "Failed creating munge.key"
        exit -1
}

# Samplers
for C in test-samp-{1..4}; do
	_INFO starting $C
	./start-samp.sh $C
done

for C in test-samp-{1..4}; do
	wait_running $C || _ERROR_EXIT "$C is not running"
	_INFO "$C is running"
done


# L1 aggregators
_INFO starting test-agg-11
./start-agg1.sh test-agg-11 test-samp-{1,2}
_INFO starting test-agg-12
./start-agg1.sh test-agg-12 test-samp-{3,4}

for C in test-agg-{11,12}; do
	wait_running $C || _ERROR_EXIT "$C is not running"
	_INFO "$C is running"
done

# L2 aggregator
_INFO starting test-agg-2
./start-agg2.sh test-agg-2 test-agg-{11,12}
wait_running test-agg-2 || _ERROR_EXIT "test-agg-2 is not running"
_INFO "test-agg-2 is running"

_INFO "Collecting data (into SOS)"
# collect some data
sleep 10

# Checking data
_INFO Checking SOS data
docker run --rm -i --entrypoint /usr/bin/python3 -v ${PWD}/store:/store:rw \
	ovishpc/ldms-agg:${BUILD_TAG} < check.py
RC=$?
_INFO "check rc: $RC"
exit $RC
