#!/bin/bash

HOST="$1"

CURL=`which curl`

if [ "$#" -lt "1" ]; then
 echo "Use: $0 HOST-API"
 exit 1
fi

$CURL -s -X GET http://${HOST}:4567/silenced
