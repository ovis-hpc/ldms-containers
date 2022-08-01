#!/usr/bin/python3

import sys
from sosdb import Sos

cont = Sos.Container()
cont.open("/store/cont")
sch = cont.schema_by_name("meminfo")
attr = sch.attr_by_name("time_comp_job")
itr = attr.attr_iter()

def ITR(ii):
    b = ii.begin()
    while b:
        yield ii.item()
        b = ii.next()

objs = [ o for o in ITR(itr) ]

comp_ids = set( o['component_id'] for o in objs )
print("Component IDs:", comp_ids)
if comp_ids == set([1,2,3,4]):
    sys.exit(0)
else:
    sys.exit(-1)
