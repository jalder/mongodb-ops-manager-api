#!/bin/bash

USER="{USERNAME}"
APIKEY="{APIKEY}"
HOST="{HOST:PORT}"
PROJECTID="{PROJECTID}"
TMPDIR="/tmp"

curl -u "$USER:$APIKEY" --digest "http://$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" > $TMPDIR/automationConfig.json

./jq -c --arg FILTER '{ atype: { $nin: [ "createCollection", "createDatabase" ] } }' '.processes |= map((select(.processType == "mongod") | .args2_6 += {"auditLog":{"destination":"file","format":"JSON","filter":$FILTER,"path":"/tmp/auditLog.json"}}) // .)' /tmp/automationConfig.json > $TMPDIR/automationConfig-new.json

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PUT "http://$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" --data @$TMPDIR/automationConfig-new.json
