#!/bin/bash
#
# This is for starting an agg L2 container with 'test' network for testing out
# various containers on a single machine.
#
# SYNOPSIS
#   ./start-agg2.sh NAME PRDCR1 PRDCR2 ...

D=$(dirname $0)
cd $D

NAME=${1:-agg2}
shift
PRDCRS=( "$@" )
IMG=ovishpc/ldms-agg
NET=test
XPRT=sock
PORT=411

mkdir -p store

docker run -d --name ${NAME} --hostname ${NAME} \
	-v ${PWD}/store:/store:rw \
	--network ${NET} ${IMG} -x sock:411

# Limited wait for State.Running == true
for ((I=0; I<5; I++)); do
	STATE=$(docker inspect -f {{.State.Running}} ${NAME} )
	[[ "$STATE" != "true" ]] || break
	sleep 0.5
done

if [[ "$STATE" != "true" ]]; then
	echo "ERROR: ${NAME} not running"
	exit -1
fi

# Configure the daemon
{ cat <<EOF
load name=store_sos
config name=store_sos path=/store
strgp_add name=sos plugin=store_sos container=meminfo schema=meminfo
$(
for P in ${PRDCRS[*]}; do
	echo "prdcr_add name=${P} xprt=${XPRT} host=${P} port=${PORT} \
		type=active interval=1000000"
done
)
prdcr_start_regex regex=.*
strgp_prdcr_add name=sos regex=.*
strgp_start name=sos
updtr_add name=all interval=1000000 offset=200000
updtr_prdcr_add name=all regex=.*
updtr_start name=all
EOF
} | docker exec -i ${NAME} ldmsd_controller --xprt sock \
					    --host localhost \
					    --port 411
