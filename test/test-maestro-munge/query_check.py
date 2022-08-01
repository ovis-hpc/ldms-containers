#!/usr/bin/python3
#
# This must be run in a container

from urllib import request
import json

f = open('/query.json')
d = f.read()

h = request.urlopen('http://mtest-ui/grafana/query', data=d.encode())
assert( h.code == 200 )
b = h.read()
cols = json.loads(b)
assert( cols[0]['target'] == 'Active' )
assert( cols[1]['target'] == 'component_id' )
assert( cols[2]['target'] == 'job_id' )

comps = cols[1]['datapoints'] # list of pairs (compt_id, ts)
comp_ids = set( c[0] for c in comps )
print(f"query results: {b}")
print(f"comp_ids:{comp_ids}")
assert( comp_ids == set([1,2,3,4]) )
