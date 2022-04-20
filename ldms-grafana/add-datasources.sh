#!/bin/bash
D=$(dirname $0)
cd ${D}
curl -X "POST" http://localhost:3000/api/datasources \
     -H "Content-Type: application/json" \
     --user admin:admin --data-binary @datasources.json
