#!/bin/bash

USER="{USER}"
APIKEY="{APIKEY}"
HOST="{OMHOST:PORT}"


## Dump the headers to view additional server information

curl -D - -u "$USER:$APIKEY" --digest "https://$HOST/api/public/v1.0/" 

