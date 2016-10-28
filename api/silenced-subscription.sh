#!/bin/bash

HOST="$1"
SUBS="$2"
TIME="$3"
REASON="$4"

CURL=`which curl`

if [ "$#" -lt "2" ]; then
 echo "Use: $0 HOST-API SUBSCRIPTION TIME-SILENCED 'REASON'"
 exit 1
fi

if [ -z "$TIME" ]; then
  TIME="60"
fi

$CURL -s -i -X POST \
-H 'Content-Type: application/json' \
-d "{\"subscription\": \"${SUBS}\", \"creator\":\"${USER}\", \"reason\": \"${REASON}\", \"expire\": ${TIME} }" \
http://${HOST}:4567/silenced
