#!/bin/bash

D=$(dirname $0)
cd $D

docker rm -f mtest-samp-{1..4} mtest-agg-{11,12} mtest-agg-2 mtest-maestro \
	     mtest-ui mtest-grafana

if [[ -d store ]]; then
	{ cat <<-EOF
	rm -rf /store/* /store/.*lock
	EOF
	} | docker run --rm -i --entrypoint /bin/bash \
		-v $PWD/store:/store:rw ovishpc/ldms-agg

	rmdir store
fi
