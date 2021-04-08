#!/bin/bash

USER="" #API Public Key
APIKEY="" #API Pirvate Key
HOST="https://OM-HOST:8443"
PROJECTID="" #OM Project/Group ID
TMPDIR="/tmp"

curl -u "$USER:$APIKEY" --digest "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" > $TMPDIR/automationConfig.json

CA=$(cat foobar.ca) #Update with CA chain

./jq ".ldap.CAFileContents = \"$CA\" " $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PUT "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" --data @$TMPDIR/automationConfig-new.json

