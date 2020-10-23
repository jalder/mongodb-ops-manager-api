#!/bin/bash

######BEGIN CONFIG######

USER="" # Public API Key

APIKEY="" # Private API Key

HOST="" # Ops Manager host

PROJECTID="" # Ops Manager Group/Project ID

TMPDIR="/tmp" # TMP directory, if needed

RS="" #Cluster ID of the Replica Set

#########END CONFIG#######


LATESTSNAPID=$(curl -s -u "$USER:$APIKEY" --digest "$HOST/api/public/v1.0/groups/$PROJECTID/clusters/$RS/snapshots" | ./jq -r '.results[0].id')
LATESTDATE=$(curl -s -u "$USER:$APIKEY" --digest "$HOST/api/public/v1.0/groups/$PROJECTID/clusters/$RS/snapshots" | ./jq -r '.results[0].created.date')

echo "Requesting HTTP Download of Snapshot ID:$LATESTSNAPID, Created At:$LATESTDATE"



RESTORELINK=$(curl --user "$USER:$APIKEY" -s --digest \
     --header "Accept: application/json" \
     --header "Content-Type: application/json" \
     --request POST "$HOST/api/public/v1.0/groups/$PROJECTID/clusters/$RS/restoreJobs?pretty=true" \
     --data '{"delivery" : {"methodName" : "HTTP", "maxDownloads": 10, "expirationHours": 10}, "snapshotId": "'$LATESTSNAPID'"}'| ./jq -r '.results[0].delivery.url')


echo "Restore Link is: $RESTORELINK"

echo "Sleeping 10s"

sleep 10

echo "Downloading"

curl -O $RESTORELINK

