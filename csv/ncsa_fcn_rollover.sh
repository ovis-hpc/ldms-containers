#!/bin/bash
#
# This is a version of 'ncsa_fcn_rollover.sh' that has been modified to run
# inside the 'csv-*' ldms-agg containers. Since the ldms-agg docker image does
# not come with 'cron', this script will run as a daemon.
#
# ------ original description ------------------------------------------------ #
# this script rolls over completed files with a 3 minute delay (mmin)
# into the ncsa destructive ingest directory on the hosts
# named in argv from crontab file
# ---------------------------------------------------------------------------- #

USAGE=$( cat <<EOF
NAME
    ncsa_fcn_rollver.sh - periodically move rollover csv files into spool

SYNOPSIS
    ncsa_fcn_rollover.sh [--interval USEC] [--offset USEC]

EXAMPLES
    # for sampler
    ncsa_fcn_rollover.sh --interval 60000000 --offset 500000

DESCRIPTION
    This script is meant to be run inside a ldms-agg container with store_csv,
    and store_function_csv. The script periodically modify the permissions of
    the rollover csv and function csv files and move older rollover files into
    the spool directory.

OPTIONS
    --interval USEC
	The interval in Micro-Second (default: 60000000).

    --offset USEC
	The offset of the timer, in Micro-Second (default: 500000).
EOF
)

INTERVAL=60000000
OFFSET=500000

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

# process arguments
while (($#)); do
	case "$1" in
	--interval )
		shift
		INTERVAL=$1
		;;
	--offset )
		shift
		OFFSET=$1
		;;
	--help|-h|-?)
		cat <<<"$USAGE"
		exit 0
		;;
	* )
		echo "Unknown parameter: $1"
		exit -1
		;;
	esac
done

{ # sub shell

do_work() {
	indir=/store/store_function_csv
	outdir=/store/store_function_csv/spool
	[[ -d $indir ]] || return
	mkdir -p $outdir
	# docker on voltrino use UID mapping. Unfortunately, the UIDs in a
	# container got mapped to non-existing UIDs on the host. If the
	# permission of the files and directores are not accessible for
	# 'others', the host-side won't be able to access them.
	chmod 777 $outdir
	chmod a+rw $indir/*.*
	for i in $(find $indir -maxdepth 1 -type f -mmin +4); do
		mv $i $outdir
	done
}

while true; do
	T=$( date +%s )
	S=$(
		bc <<-EBC
		scale = 0
		i = ${INTERVAL}
		o = ${OFFSET}
		t0 = ${T}*i
		t1 = (t0+2*i-1)/i*i + o
		dt = t1 - t0
		scale = 6
		dt/1000000
		EBC
	)
	sleep "${S}"
	echo "Wake up:" $(date '+%s %F %T')
	do_work
done
} > /var/log/rollover.log 2>&1 &

exit 0
