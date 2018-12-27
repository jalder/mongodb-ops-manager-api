#!/bin/bash

curl -u "{USERNAME}:{APIKEY}" --digest "http://{HOST:PORT}/api/public/v1.0/groups/{PROJECTID}/automationConfig" > /tmp/automationConfig.json

./jq -c '.roles += [{"role":"foobartest", "db": "admin", "privileges": [{"resource": {"db":"foobar","collection":"test"}, "actions" : ["find"]}]}]' /tmp/automationConfig.json > /tmp/automationConfig-new.json

curl -u "{USERNAME}:{APIKEY}" -H "Content-Type: application/json" --digest -i -X PUT "http://{HOST:PORT}/api/public/v1.0/groups/{PROJECTID}/automationConfig" --data @/tmp/automationConfig-new.json

