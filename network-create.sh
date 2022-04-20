#!/bin/bash
#
# ./network-create.sh

D=$(dirname $0)

. ${D}/config.sh

docker network create \
	--driver=overlay \
	--subnet=${SUBNET} \
	--attachable \
	${NET}
