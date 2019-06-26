#!/bin/bash

USER=""
APIKEY=""
HOST=""
PROJECTID=""
TMPDIR="/tmp"
NEWDIRECTORYURL="$HOST/download/agent/automation/"

curl -u "$USER:$APIKEY" --digest "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" > $TMPDIR/automationConfig.json 

./jq -c ".agentVersion.directoryUrl = \"$NEWDIRECTORYURL\"" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PUT "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" --data @$TMPDIR/automationConfig-new.json

