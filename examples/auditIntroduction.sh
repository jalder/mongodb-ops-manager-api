#!/bin/bash

curl -u "{USERNAME}:{APIKEY}" --digest "http://{HOST:PORT}/api/public/v1.0/groups/{PROJECTID}/automationConfig" > /tmp/automationConfig.json

./jq -c --arg FILTER '{ atype: { $nin: [ "createCollection", "createDatabase" ] } }' '.processes |= map((select(.processType == "mongod") | .args2_6 += {"auditLog":{"destination":"file","format":"JSON","filter":$FILTER,"path":"/tmp/auditLog.json"}}) // .)' /tmp/automationConfig.json > /tmp/automationConfig-new.json

curl -u "{USERNAME}:{APIKEY}" -H "Content-Type: application/json" --digest -i -X PUT "http://{HOST:PORT}/api/public/v1.0/groups/{PROJECTID}/automationConfig" --data @/tmp/automationConfig-new.json

