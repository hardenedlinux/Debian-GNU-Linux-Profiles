#!/bin/sh
dashboard_uuid=${1}
dashboard_name=${2}
curl -XGET http://localhost:5601/api/kibana/dashboards/export?dashboard=${dashboard_uuid} > ${dashboard_name}.json
cat ${dashboard_name}.json
