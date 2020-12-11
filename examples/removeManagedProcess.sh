#!/bin/bash

USER="" #OM Username or Public API Key
APIKEY="" #OM API Private Key
HOST="https://OMHOST:8443"
PROJECTID="" #OM Project/Group ID
TMPDIR="/tmp"


rmList=("server1:27017" "server2:27017") #List of servers are are dropping from replica sets

curl -u "$USER:$APIKEY" --digest "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" > $TMPDIR/automationConfig.json 

## Shut Down Mongod(s) and remove from RS

for server in "${rmList[@]}"
do
  # Shutdown the process
  hostname=$(echo $server | cut -d: -f1)
  port=$(echo $server | cut -d: -f2)
  procName=$(./jq ".processes[] | select(.hostname == \"$hostname\" and .args2_6.net.port == $port) | .name" $TMPDIR/automationConfig.json)
  if [ ! -z "$procName" ]
  then
    echo $procName # Easier to work with the process name
    ./jq "(.processes[] | select(.name == $procName) | .disabled) = true" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json
    cat $TMPDIR/automationConfig-new.json > $TMPDIR/automationConfig.json # Have to write it back for next iter, avoiding clobber
    ## Remove the process from the rs.conf()
    ./jq "del(.replicaSets[].members[] | select(.host == $procName))" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json
    cat $TMPDIR/automationConfig-new.json > $TMPDIR/automationConfig.json
    ## Remove the process from management
    ./jq "del(.processes[] | select(.name == $procName))" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json
    cat $TMPDIR/automationConfig-new.json > $TMPDIR/automationConfig.json
  fi
done

# Send it back up for action

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PUT "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" --data @$TMPDIR/automationConfig.json

# Delete the hosts from Monitoring as well

for server in "${rmList[@]}"
do
  ## Get the Host ID
  hostId=$(curl -u "$USER:$APIKEY" --digest "$HOST/api/public/v1.0/groups/$PROJECTID/hosts/byName/$server" | ./jq -r '.id')
  echo $hostId
  curl -u "$USER:$APIKEY" --digest -i -X DELETE "$HOST/api/public/v1.0/groups/$PROJECTID/hosts/$hostId"
done
