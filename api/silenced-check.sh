#!/bin/bash

HOST="$1"
SUBS="$2"
CHECK="$3"
TIME="$4"
REASON="$5"

CURL=`which curl`

if [ "$#" -lt "3" ]; then
 echo "Use: $0 HOST-API SUBSCRIPTION CHECK TIME-SILENCED 'REASON'"
 exit 1
fi

if [ -z "$TIME" ]; then
  TIME="60"
fi

$CURL -s -i -X POST \
-H 'Content-Type: application/json' \
-d "{\"subscription\": \"${SUBS}\", \"check\": \"${CHECK}\", \"creator\":\"${USER}\", \"reason\": \"${REASON}\", \"expire\": ${TIME} }" \
http://${HOST}:4567/silenced
