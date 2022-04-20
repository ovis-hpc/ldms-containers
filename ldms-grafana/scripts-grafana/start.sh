#!/bin/bash

LOG() {
	echo $(date +"%F %T") "$@"
}

SOCK=/sock/grafana.sock
rm -f ${SOCK}

# invoke grafana run script
/run.sh >/var/log/grafana/run.log 2>&1 &

{
while true; do
	sleep 1

	[[ -S ${SOCK} ]] || continue # socket not created yet
	chmod 666 ${SOCK}

	S=$( curl -S --unix-socket ${SOCK} http://localhost/api/datasources --user admin:admin )
	(( $? == 0 )) || continue # not ready

	# Seems to be ready
	LOG "Grafana seems to be ready, available datasources: ${S}"
	LOG "Adding LDMS datasource"
	curl -S -X "POST" --unix-socket ${SOCK} http://localhost/api/datasources \
	     -H "Content-Type: application/json" \
	     --user admin:admin --data-binary @/docker/datasources.json
	S=$( curl -S --unix-socket ${SOCK} http://localhost/api/datasources --user admin:admin )
	LOG "current datasources: ${S}"
	break
done
LOG "/docker/start.sh DONE -- pending"
} > /var/log/grafana/start.log 2>&1

# This script is the `init` process in the container
tail -f /dev/null
