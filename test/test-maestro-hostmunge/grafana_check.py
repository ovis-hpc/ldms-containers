#!/usr/bin/python3

import os
import sys
import json
import base64
import urllib.request

SRC_DIR = os.path.realpath(sys.path[0])

data_path = f"{SRC_DIR}/files/grafana_query.json"
f = open(data_path, "rb")
data = f.read()
auth = base64.b64encode(b"admin:admin").decode()
req = urllib.request.Request(
        "http://localhost:3000/api/datasources/proxy/1/query",
        data = data,
        method = "POST",
        headers = {
                "Content-Type" : "application/json",
                "Authorization" : f"Basic {auth}",
            },
    )
rsp = urllib.request.urlopen(req)
obj = json.load(rsp)
active_data, comp_data, job_data = obj
assert( active_data["target"] == "Active" )
assert( len(active_data["datapoints"]) > 0 )
for x,y in active_data["datapoints"]:
    assert( x > 0 )
assert( comp_data["target"] == "component_id" )
comp_ids = set( x for x, y in comp_data["datapoints"] )
assert( comp_ids == set( [1,2,3,4] ) )
