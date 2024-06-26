#!/bin/bash
#
# This is for starting a sampler container with 'test' network for testing out
# various containers on a single machine.

NAME=${1:-samp}
IMG=ovishpc/ldms-samp:${BUILD_TAG}
NET=test
COMPID=${NAME//[^0-9]/}
D=$(realpath $(dirname $0))

docker run -d --name ${NAME} --hostname ${NAME} --network ${NET} \
	-v ${D}/munge.key:/etc/munge/munge.key:rw \
	${IMG} -x sock:411 -a munge

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

sleep 1

# Configure the daemon
{ cat <<EOF
load name=meminfo
config name=meminfo producer=${NAME} instance=${NAME}/meminfo component_id=${COMPID}
start name=meminfo interval=1000000 offset=0
EOF
} | docker exec -i ${NAME} ldmsd_controller --xprt sock \
					    --host localhost \
					    --port 411 --auth munge
