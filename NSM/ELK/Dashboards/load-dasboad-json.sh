#!/bin/bash
for j in $(ls *.json)
do
    curl -XPOST http://localhost:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @${j}
done
