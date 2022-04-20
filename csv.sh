#!/bin/bash
#
# Start csv-21, csv-22, csv-23 containers. Similar to agg-2*, csv-21, csv-22,
# and csv-23 connect to voltrino-int:413 voltrino-int:414, voltrino-int:415
# respectively.

D=$(realpath $(dirname $0))

STORE_ROOT=/data/nntaera/csv_store
mkdir -p ${STORE_ROOT}

csv_run() {
	local NAME=$1
	local PRDCR=$2
	./ldms-agg/run.sh --name ${NAME} --prdcr "${PRDCR}" \
		  --mem 1G \
		  --strgp-conf ${D}/csv/ncsa_csv.conf \
		  --interval 60000000 --offset 500000 \
		  -v "${D}/csv/ncsa_fcn_rollover.sh:/opt/ovis/sbin/ncsa_fcn_rollover.sh" \
		  -v "${D}/scripts/ldmsd-conf:/opt/ovis/sbin/ldmsd-conf" \
		  -v "${D}/csv/ncsa_function_csv.conf:/opt/ovis/etc/ldms/ncsa_function_csv.conf" \
		  -v "${STORE_ROOT}/${NAME}:/store"
	docker exec ${NAME} /opt/ovis/sbin/ncsa_fcn_rollover.sh
}

csv_run csv-21 "10.8.1.11:413"
csv_run csv-22 "10.8.1.11:414"
csv_run csv-23 "10.8.1.11:415"
