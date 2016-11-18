#!/bin/bash

HOST="$1"
TYPE="$2"
CLIENT="$3"
CHECK="$4"
SUBNAME="$5"

CURL=`which curl`

if [ "$#" -lt "2" ]; then
 echo "Use: $0 HOST-API TYPE NAME"
 echo "TYPE: clients, checks, results, aggregates, events, silenced, info"
 echo "Use: $0 HOST-API clients (alone or client name for more details)"
 echo "Use: $0 HOST-API checks (alone or check name for more details)"
 echo "Use: $0 HOST-API results (alone or client name for more details or client-name + check-name for more specific details)"
 echo "Use: $0 HOST-API aggregates (alone or aggregate name for more details or aggregate-name + client-name for more specific details or aggregate-name + check-name or aggregate-name + severity)"
 echo "Use: $0 HOST-API events (alone or client name for more details or client-name + check-name for more specific details)"
 echo "Use: $0 HOST-API silenced (alone or check-name or subscription-name for more specific details)"
 echo "Use: $0 HOST-API info"
 exit 1
fi

case $TYPE in
  clients)
    if [ -z $CLIENT ]; then
      $CURL -s -X GET http://${HOST}:4567/clients
    else
      $CURL -s -X GET http://${HOST}:4567/clients/${CLIENT}
    fi
  ;;
  checks)
    if [ -z $CLIENT ]; then
      $CURL -s -X GET http://${HOST}:4567/checks
    else
      $CURL -s -X GET http://${HOST}:4567/checks/${CLIENT}
    fi
  ;;
  results)  
    if [ -z $CLIENT ]; then
      $CURL -s -X GET http://${HOST}:4567/results
    else
      if [ -z $CHECK ]; then
        $CURL -s -X GET http://${HOST}:4567/results/${CLIENT}
      else
        $CURL -s -X GET http://${HOST}:4567/results/${CLIENT}/${CHECK}
      fi  
    fi  
  ;;
  aggregates)
    if [ -z $CLIENT ]; then
      $CURL -s -X GET http://${HOST}:4567/aggregates
    else
      if [ -z $CHECK ]; then
        $CURL -s -X GET http://${HOST}:4567/aggregates/${CLIENT}
      else
        case $CHECK in
          checks)
            $CURL -s -X GET http://${HOST}:4567/aggregates/${CLIENT}/checks
          ;;
          clients)
            $CURL -s -X GET http://${HOST}:4567/aggregates/${CLIENT}/clients
          ;;
          severity)
            $CURL -s -X GET http://${HOST}:4567/aggregates/${CLIENT}/results/${SUBNAME}
          ;;
          *)
            echo "USE: $0 HOST-API aggregates AGGREGATES-NAME (checks|clients)"
            echo "USE: $0 HOST-API aggregates AGGREGATES-NAME severity (ok|critical|warning|unkknown)"
          ;;
        esac
      fi
    fi  
  ;;
  events)  
    if [ -z $CLIENT ]; then
      $CURL -s -X GET http://${HOST}:4567/events
    else
      if [ -z $CHECK ]; then
        $CURL -s -X GET http://${HOST}:4567/events/${CLIENT}
      else
        $CURL -s -X GET http://${HOST}:4567/events/${CLIENT}/${CHECK}
      fi  
    fi  
  ;;
  silenced)
    if [ -z $CLIENT ]; then
      $CURL -s -X GET http://${HOST}:4567/silenced
    else
      case $CLIENT in
        checks)
          $CURL -s -X GET http://${HOST}:4567/silenced/checks/${CHECK}
        ;;
        subscriptions)
          $CURL -s -X GET http://${HOST}:4567/silenced/subscriptions/${CHECK}
        ;;
        *)
          echo "USE: $0 HOST-API silenced (checks|subscriptions) (NAME-CHECK|NAME-SUBSCRIPTION)"
        ;;
      esac
    fi
  ;;
  health|info)
    $CURL -s -X GET http://${HOST}:4567/info
  ;;
  *)
    echo "Use: $0 HOST-API TYPE CLIENT"
  ;;
esac
