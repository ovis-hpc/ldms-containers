#!/bin/bash

# Run from script dir
D=$(dirname $0)
cd $D
SCRIPT_DIR=${PWD}
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


mkdir -p store

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

on_exit() {
	(( $DEBUG )) || {
		_INFO "Cleaning up ..."
		./cleanup.sh
		_INFO "DONE"
	}
}
trap on_exit EXIT

NET=test

[[ -e ${SCRIPT_DIR}/files/munge.key ]] || touch ${SCRIPT_DIR}/files/munge.key

# Prep munge key
{ cat <<EOF
dd if=/dev/urandom of=/etc/munge/munge.key bs=4096 count=1
chown munge:munge /etc/munge/munge.key
chmod 600 /etc/munge/munge.key
EOF
} | docker run --rm -i --entrypoint /bin/bash \
	-v ${SCRIPT_DIR}/files/munge.key:/etc/munge/munge.key:rw \
	ovishpc/ldms-maestro

# Maestro
C=mtest-maestro
_INFO starting $C
docker run -d --name ${C} --hostname ${C} --network ${NET} \
	-v ${SCRIPT_DIR}/files/munge.key:/etc/munge/munge.key:ro \
	-v ${PWD}/files/ldms_cfg.yaml:/etc/ldms_cfg.yaml:rw \
	ovishpc/ldms-maestro

# Samplers
for C in mtest-samp-{1..4}; do
	_INFO starting $C
	COMPID=${C#mtest-samp-}
	docker run -d --name ${C} --hostname ${C} --network ${NET} \
		-v ${SCRIPT_DIR}/files/munge.key:/etc/munge/munge.key:ro \
		-e COMPID=${COMPID} \
		ovishpc/ldms-samp -x sock:411 -a munge
done

for C in mtest-samp-{1..4}; do
	wait_running $C || _ERROR_EXIT "$C is not running"
	_INFO "$C is running"
done

# aggregators
for C in mtest-agg-{11,12}; do
	_INFO starting $C
	docker run -d --name ${C} --hostname ${C} --network ${NET} \
		-v ${SCRIPT_DIR}/files/munge.key:/etc/munge/munge.key:ro \
		ovishpc/ldms-agg -x sock:411 -a munge
done

for C in mtest-agg-{11,12}; do
	wait_running $C || _ERROR_EXIT "$C is not running"
	_INFO "$C is running"
done

# L2 aggregator
C=mtest-agg-2
_INFO starting ${C}
docker run -d --name ${C} --hostname ${C} --network ${NET}  \
	   -v ${SCRIPT_DIR}/files/munge.key:/etc/munge/munge.key:ro \
	   -v ${PWD}/store:/store:rw ovishpc/ldms-agg -x sock:411 -a munge
wait_running ${C} || _ERROR_EXIT "${C} is not running"
_INFO "${C} is running"

_INFO "Collecting data (into SOS)"
# collect some data
sleep 10

# Stop updater on L1 daemons to stop data collection
docker kill mtest-agg-{11,12}

# Checking data
_INFO Checking SOS data
docker run --rm -i --entrypoint /usr/bin/python3 -v ${PWD}/store:/store:rw \
	ovishpc/ldms-agg < check.py
RC=$?
_INFO "sos check rc: $RC"

# start dsosd on mtest-agg-2
docker cp ${SCRIPT_DIR}/files/dsosd.json mtest-agg-2:/etc/
{ cat <<EOF
rpcbind
sleep 1
export DSOSD_DIRECTORY=/etc/dsosd.json
dsosd >/var/log/dsosd.log 2>&1 &
EOF
} | docker exec -i mtest-agg-2 /bin/bash

# start UI
C=mtest-ui
_INFO "starting ${C}"
docker run -d --name ${C} --hostname ${C} --network ${NET} \
	   -v ${SCRIPT_DIR}/files/dsosd.conf:/opt/ovis/etc/dsosd.conf \
	   -v ${SCRIPT_DIR}/files/settings.py:/opt/ovis/ui/sosgui/settings.py \
	   ovishpc/ldms-ui
wait_running ${C} || _ERROR_EXIT "${C} is not running"
T0=$(($(date +%s) - 24*3600))
T1=$(( T0 + 48*3600 ))

cat > ${SCRIPT_DIR}/files/query.json <<EOF
{
  "range": {
    "from":"$( date -d @${T0} -u +'%FT00:00:00.000000Z' )",
    "to":"$( date -d @${T1} -u +'%FT00:00:00.000000Z' )"
  },
  "intervalMs":"1000",
  "interval":"1",
  "maxDataPoints":"100000",
  "targets": [
    {
      "container":"cont",
      "format":"time_series",
      "query_type": "metrics",
      "schema": "meminfo",
      "target": "Active",
      "filters": []
    }
  ]
}
EOF

UI_ADDR=$( docker inspect -f {{.NetworkSettings.Networks.${NET}.IPAddress}} mtest-ui )

URL=http://mtest-ui/grafana/query
_INFO "Checking query from mtest-ui: ${URL}"
docker run --rm -i --entrypoint /usr/bin/python3 \
	--name mtest-qcheck --hostname mtest-qcheck --network ${NET} \
	-v ${SCRIPT_DIR}/files/query.json:/query.json \
	ovishpc/ldms-agg < ${SCRIPT_DIR}/query_check.py
_INFO "query check RC: $?"

# Grafana
C=mtest-grafana
docker run -d --name ${C} --hostname ${C} -p 3000:3000 --network test ovishpc/ldms-grafana
sleep 5

_INFO "Adding DSOS data source in Grafana"
curl -H "Content-Type: application/json" \
     -d @${SCRIPT_DIR}/files/dsos_grafana_create.json \
     http://admin:admin@localhost:3000/api/datasources
sleep 1
echo

cat > ${SCRIPT_DIR}/files/grafana_query.json <<EOF
{
    "range": {
        "from":"$( date -d @${T0} -u +'%FT00:00:00.000000Z' )",
        "to":"$( date -d @${T1} -u +'%FT00:00:00.000000Z' )",
        "raw": {
            "from":"$( date -d @${T0} -u +'%FT00:00:00.000000Z' )",
            "to":"$( date -d @${T1} -u +'%FT00:00:00.000000Z' )"
        }
    },
    "interval": "10ms",
    "intervalMs": 10,
    "targets": [
        {
            "target": "Active",
            "container": "cont",
            "schema": "meminfo",
            "query_type": "metrics",
            "filters": null,
            "format": "time_series",
            "analysis_module": null,
            "extra_params": null,
            "refId": "A"
        }
    ],
    "maxDataPoints": 601,
    "scopedVars": {
        "__interval": {
            "text": "10ms",
            "value": "10ms"
        },
        "__interval_ms": {
            "text": "10",
            "value": 10
        }
    },
    "rangeRaw": {
        "from":"$( date -d @${T0} -u +'%FT00:00:00.000000Z' )",
        "to":"$( date -d @${T1} -u +'%FT00:00:00.000000Z' )"
    }
}
EOF

_INFO "Checking grafana data"
python3 ${SCRIPT_DIR}/grafana_check.py
_INFO "Grafana data check, rc: $?"

# See `on_exit()` for the exit-cleanup routine
