#!/bin/bash

D=$(dirname $0)
cd $D

docker rm -f test-samp-{1..4} test-agg-{11,12} test-agg-2

if [[ -d store ]]; then
	{ cat <<-EOF
	rm -rf /store/* /store/.*lock
	EOF
	} | docker run --rm -i --entrypoint /bin/bash \
		-v $PWD/store:/store:rw ovishpc/ldms-agg

	rmdir store
fi
