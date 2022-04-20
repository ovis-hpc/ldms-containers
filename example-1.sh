#!/bin/bash

D=$(realpath $(dirname $0))

SOS=1
UI=1
CSV=1

for S in samp-{01..8}; do
	./ldms-samp/run.sh --name ${S}
done

./ldms-agg/run.sh --name agg-11 --prdcr "samp-{01,02}" --mem 64M --offset 200000
./ldms-agg/run.sh --name agg-12 --prdcr "samp-{03,04}" --mem 64M --offset 200000
./ldms-agg/run.sh --name agg-13 --prdcr "samp-{05,06}" --mem 64M --offset 200000
./ldms-agg/run.sh --name agg-14 --prdcr "samp-{07,08}" --mem 64M --offset 200000

if [[ -n "$SOS" ]]; then
./ldms-agg/run.sh --name agg-21 --prdcr "agg-{11,12}" --mem 64M \
		  --strgp "meminfo loadavg" --offset 400000
./ldms-agg/run.sh --name agg-22 --prdcr "agg-{13,14}" --mem 64M \
		  --strgp "meminfo loadavg" --offset 400000
fi

if [[ -n "$CSV" ]]; then
./ldms-agg/run.sh --name csv-21 --prdcr "agg-{11,12}" \
		  --mem 64M \
		  --strgp-conf ${D}/csv/csv.conf \
		  --interval 60000000 --offset 400000 \
		  -v "${D}/scripts/ldmsd-conf:/opt/ovis/sbin/ldmsd-conf" \
		  -v "${D}:/opt/ovis/etc/ldms/function_csv.conf" \
		  -v "${D}/csv_store/csv-21:/store"
./ldms-agg/run.sh --name csv-22 --prdcr "agg-{13,14}" \
		  --mem 64M \
		  --strgp-conf ${D}/csv/csv.conf \
		  --interval 60000000 --offset 400000 \
		  -v "${D}/scripts/ldmsd-conf:/opt/ovis/sbin/ldmsd-conf" \
		  -v "${D}:/opt/ovis/etc/ldms/function_csv.conf" \
		  -v "${D}/csv_store/csv-22:/store"
fi

if [[ -n "$UI" ]]; then
./ldms-ui/run.sh --name ui --dsosd "agg-{21,22}"
./ldms-grafana/run.sh
fi
