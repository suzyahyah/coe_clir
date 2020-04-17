#!/usr/bin/env bash

qparser(){
val=$(python3 - "${@}" <<EOF
import sys
import json
from src import queryparser
qp=queryparser.QueryParser()
fil=sys.argv[1]
j=qp.parse_to_json(x)
j=json.loads(j)
print(j[0]['query_string'])
EOF
)
echo $val
}

qparser '''"<broadcasted> live[syn:in real time]"'''
#from src import queryparser
#qp = queryparser.QueryParser()
#json = qp.parse_to_json(sys.argv[1])
#print(json)
