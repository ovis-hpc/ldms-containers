#!/bin/bash

# Location on the host to keep the storage data. The '/store' in a container
# is mapped to ${STORE_ROOT}/${CONTAINER_NAME}.
STORE_ROOT=/data/nntaera/store

SOS_STRGP=(
	loadavg
	meminfo_x86_ven0000fam0006mod003F
	meminfo_x86_ven0000fam0006mod0057
	procstat_x86_ven0000fam0006mod003F
	procstat_x86_ven0000fam0006mod0057
)

# script dir
D=$(realpath $(dirname $0))

# agg with SOS
agg_run() {
	local NAME=$1
	local PRDCR=$2
	./ldms-agg/run.sh --name ${NAME} --prdcr "${PRDCR}" \
		--mem 1G \
		-v "${STORE_ROOT}/${NAME}:/store" \
		--strgp "${SOS_STRGP[*]}" --offset 500000
}
agg_run agg-21 "10.8.1.11:413"
agg_run agg-22 "10.8.1.11:414"
agg_run agg-23 "10.8.1.11:415"

# CSV
mkdir -p ${STORE_ROOT}

csv_run() {
	local NAME=$1
	local PRDCR=$2
	./ldms-agg/run.sh --name ${NAME} --prdcr "${PRDCR}" \
		  --mem 1G \
		  --strgp-conf ${D}/csv/ncsa_csv.conf \
		  --interval 60000000 --offset 500000 \
		  -v "${D}/csv/ncsa_fcn_rollover.sh:/opt/ovis/sbin/ncsa_fcn_rollover.sh" \
		  -v "${D}/csv/ncsa_function_csv.conf:/opt/ovis/etc/ldms/ncsa_function_csv.conf" \
		  -v "${STORE_ROOT}/${NAME}:/store"
	docker exec ${NAME} /opt/ovis/sbin/ncsa_fcn_rollover.sh
}

csv_run csv-21 "10.8.1.11:413"
csv_run csv-22 "10.8.1.11:414"
csv_run csv-23 "10.8.1.11:415"

# UI + grafana
./ldms-ui/run.sh --name ui --dsosd "agg-{21..23}"
./ldms-grafana/run.sh --name grafana \
	-v "${D}/ldms-grafana/scripts-grafana/start.sh:/docker/start.sh"
