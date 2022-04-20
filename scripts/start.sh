#!/bin/bash

set -e

LOG() {
	echo $(date +"%F %T") "$@"
}

process_args() {
	# This function reset and build STRGP_LIST and STORE_PATH variables
	STRGP_LIST=( )
	STORE_PATH="/store"
	while (( $# )); do
		case "$1" in
		--strgp)
			shift
			eval "STRGP_LIST+=( $1 )"
			;;
		--strgp=*)
			eval "STRGP_LIST+=( ${1#--strgp=} )"
			;;
		--store-path)
			shift
			STORE_PATH="$1"
			;;
		--store-path=*)
			STORE_PATH="${1#--store-path=}"
			;;
		esac
		shift
	done
}

{
. /opt/ovis/etc/profile.d/set-ovis-variables.sh

/sbin/sshd

CONF="/opt/ovis/etc/ldms.conf"
if [[ -e "${CONF}" ]]; then
	LOG "Use existing ${CONF}"
else
	LOG "Generating ${CONF}"
	# parameters from the 'docker run' will be passed to ldmsd-conf to
	# generate the ldms.conf config file
	ldmsd-conf "$@" > ${CONF}
fi

process_args "$@"
if (( ${#STRGP_LIST[@]} )); then
	# dsosd
	cat > /opt/ovis/etc/dsosd.json <<-EOF
	{
	  "${HOSTNAME}":{
	$(
	    local S
	    local C=" "
	    for S in "${STRGP_LIST[@]}"; do
		echo "   ${C}\"$S\":\"${STORE_PATH}/$S\""
		C=","
	    done
	)
	  }
	}
	EOF
	LOG "Starting dsosd"
	dsosd-start
fi

LOG "Starting ldmsd"
ldmsd-start

# sos-part chmod routine
CONT_LIST=( "${STRGP_LIST[@]}" )
N=${#CONT_LIST[@]}
LOG "N: ${N}"
LOG "CONT_LIST: ${CONT_LIST[@]}"
if (( ${N} )); then
	LOG "Set SOS partition mode (permission) ..."
	while (( ${N} )); do
		sleep 1
		for (( I=0; I < ${#CONT_LIST[@]}; I++)); do
			CONT="${CONT_LIST[$I]}"
			LOG "working on CONT: ${CONT}"
			[[ -n "$CONT" ]] || continue # already done
			PART_LIST=( ${STORE_PATH}/${CONT}/*/ )
			LOG "PART_LIST: ${PART_LIST[@]}"
			(( ${#PART_LIST[@]} >= 2 )) || continue # not ready
			ERR=0
			for PART in "${PART_LIST[@]}"; do
				LOG "  ... partition: ${PART}"
				# NOTE: apache@ui cannot read data with mode 0o664
				sos-part --path ${PART} --set --mode 0o666
				ERR=$?
				(( $ERR == 0 )) || break
			done
			(( $ERR == 0 )) || continue
			# successfully modify partitions' mode
			N=$((N-1))
			CONT_LIST[$I]=
		done
	done
	LOG "partition mode set ... DONE"
fi

LOG "start routine done, pending init process ..."
} 2>&1 | tee /var/log/start.log

# This script is the `init` process in the container
tail -f /dev/null
