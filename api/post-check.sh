#!/bin/bash

HOST="$1"
SUBS="$2"
CHECK="$3"
REASON="$4"

CURL=`which curl`

if [ "$#" -lt "3" ]; then
 echo "Use: $0 HOST-API CLIENT_FQDN CHECK 'REASON'"
 exit 1
fi

$CURL -s -i -X POST \
-H 'Content-Type: application/json' \
-d "{\"check\": \"${CHECK}\", \"subscribers\": [ \"client:${SUBS}\" ], \"creator\":\"${USER}\", \"reason\": \"${REASON}\" }" \
http://${HOST}:4567/request
