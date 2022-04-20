#!/bin/bash

set -e

LIST=( ldms-samp ldms-agg ldms-ui )

for D in "${LIST[@]}"; do
	pushd $D
	./ovis-build.sh
	popd
done
