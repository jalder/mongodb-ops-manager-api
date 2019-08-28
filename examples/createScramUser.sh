#!/bin/bash

USER="{API-USER}"
APIKEY="{API-KEY}"
HOST="{OM-HOST}:{PORT}"
PROJECTID="{PROJECTID}"
TMPDIR="/tmp"
JQ="./jq"

# Drop the Tag
curl -u "$USER:$APIKEY" --digest "https://$HOST/api/public/v1.0/groups/$PROJECTID" > $TMPDIR/projectConfig.json

$JQ ' .tags |= map(select(. != "EXTERNALLY_MANAGED_BY_KUBERNETES"))' $TMPDIR/projectConfig.json > $TMPDIR/projectConfig-new.json

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PATCH "https://$HOST/api/public/v1.0/groups/$PROJECTID" --data @$TMPDIR/projectConfig-new.json

curl -u "$USER:$APIKEY" --digest "https://$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" > $TMPDIR/automationConfig.json 

DISABLED=$($JQ ".auth.disabled" $TMPDIR/automationConfig.json)
if [ "$DISABLED" == "true" ]
then
	echo "Auth is Disabled"
	AUTOUSER=$($JQ ".auth.autoUser" $TMPDIR/automationConfig.json)
	echo $AUTOUSER
	if [ "$AUTOUSER" == "null" ]
	then
		echo "AuthUser is Empty, creating mms-automation"
		# insert auth.autoUser and auth.autoPwd, set auth.disabled false, set auth.deploymentAuthMechanisms, send back upstream
		KEY=$(openssl rand -base64 756)
		INITPWD=$(openssl rand -base64 20)
		echo "Agent Credential: $INITPWD"
		$JQ ".auth.usersWanted=[{db:\"admin\",initPwd:\"$INITPWD\",user:\"mms-monitoring-agent\",roles:[{db:\"admin\",role:\"clusterMonitor\"}]},{db:\"admin\",initPwd:\"$INITPWD\",user:\"mms-backup-agent\",roles:[{db:\"local\",role:\"readWrite\"},{db:\"admin\",role:\"clusterAdmin\"},{db:\"admin\",role:\"readAnyDatabase\"},{db:\"admin\",role:\"userAdminAnyDatabase\"}]}]|.auth.keyfileWindows=\"%SystemDrive%\\\\MMSAutomation\\\\versions\\\\keyfile\"|.auth.autoUser=\"mms-automation\"|.auth.autoPwd=\"$INITPWD\"|.auth.authoritativeSet=false|.auth.deploymentAuthMechanisms=[\"MONGODB-CR\"]|.auth.autoAuthMechanisms=[\"MONGODB-CR\"]|.auth.disabled=false|.auth.key=\"$KEY\"|.auth.keyfile=\"/var/lib/mongodb-mms-automation/keyfile\"" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json
		curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PUT "https://$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" --data @$TMPDIR/automationConfig-new.json
		# fetch fresh doc after sending back
		curl -u "$USER:$APIKEY" --digest "https://$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" > $TMPDIR/automationConfig.json
	fi
fi

echo "Prompting for new SCRAM-SHA-1 User"

echo "Username:"

read USERNAME

echo "Password:"

read PASSWORD

echo "Database:"

read DATABASE

echo "Role:"

read ROLE

echo "Creating readWrite@$DATABASE $USERNAME@admin with $PASSWORD"

$JQ ".auth.usersWanted |= .+ [{db:\"admin\",initPwd:\"$PASSWORD\",user:\"$USERNAME\",roles:[{db:\"$DATABASE\",role:\"$ROLE\"}]}]" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PUT "https://$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" --data @$TMPDIR/automationConfig-new.json

# Put the Tags back
$JQ ' .tags |= .+ ["EXTERNALLY_MANAGED_BY_KUBERNETES"]' $TMPDIR/projectConfig-new.json > $TMPDIR/projectConfig-revert.json

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PATCH "https://$HOST/api/public/v1.0/groups/$PROJECTID" --data @$TMPDIR/projectConfig-revert.json


