#!/bin/bash

USER="" #OM Username or Public Key
APIKEY="" #OM Private Key
HOST="https://OMHOST:8443"
PROJECTID="PROJECTID" #OM Project/Group ID
TMPDIR="/tmp"

replicaSetName="" #Replica Set we are adding members to
addList=("server1:27017" "server2:27017") #List of members we are adding to the replica set

curl -u "$USER:$APIKEY" --digest "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" > $TMPDIR/automationConfig.json 

## Add processes to automation

i=2

for server in "${addList[@]}"
do
  hostname=$(echo $server | cut -d: -f1)
  port=$(echo $server | cut -d: -f2)
  ## Get the current primary process conf to use as a template
  procName=$( ./jq -r ".replicaSets[] | select(._id == \"$replicaSetName\") | .members[0].host" $TMPDIR/automationConfig.json)
  echo $procName
  procTemplate=$(./jq ".processes[] | select(.name == \"$procName\")" $TMPDIR/automationConfig.json)
  name=$procName"_"$i

  ## Setting dbPath and log path only if they differ from the "template", this portion will likely need customized or removed if consistent
  dbPath="/data/tc"$i
  systemLog="/data/tc"$i"/mongodb.log"

  server=$(echo $procTemplate | ./jq ".hostname = \"$hostname\" | .args2_6.net.port = $port | .name = \"$name\" | .args2_6.storage.dbPath = \"$dbPath\" | .args2_6.systemLog.path = \"$systemLog\"")
  echo $server
  ./jq ".processes += [$server]" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json
  cat $TMPDIR/automationConfig-new.json > $TMPDIR/automationConfig.json
  

  ## Add to the replica set members array
  rsTemplate=$(./jq ".replicaSets[] | select(._id == \"$replicaSetName\") | .members[0]" $TMPDIR/automationConfig.json)
  echo $rsTemplate
  member=$(echo $rsTemplate | ./jq "._id = $i | .host = \"$name\"")
  echo $member
  ./jq "(.replicaSets[] | select(._id == \"$replicaSetName\").members) += [$member]" $TMPDIR/automationConfig.json > $TMPDIR/automationConfig-new.json
  cat $TMPDIR/automationConfig-new.json > $TMPDIR/automationConfig.json
  i=$(($i+1)) 
done

# Send it back up for action

curl -u "$USER:$APIKEY" -H "Content-Type: application/json" --digest -i -X PUT "$HOST/api/public/v1.0/groups/$PROJECTID/automationConfig" --data @$TMPDIR/automationConfig.json

