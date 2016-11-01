#!/bin/bash
#
# This script was create because:
# - For use with subscription and multiples containers and with name compose with version like app_001
# - You can pass the containers name via custom attribute at sensu-client :::containers_name::: 
# - containers_name: app01,app02 or app01
# 
#
# Examples:
# 1 - multi-containers-list.sh app check-container.rb -c
# 
# 2 - multi-containers-list.sh qpp metrics-docker-stats.rb "-p unix -H /var/run/docker.sock -c" -s hostname.app
#   OR - multi-containers-list.sh qpp metrics-docker-stats.rb "-p unix -H /var/run/docker.sock -c" metric
#

DOCKER=`which docker`
AWK=`which awk`
GREP=`which grep`

if [ "$#" -lt "3" ]; then
 echo "Use: $0 CONTAINER PLUGIN-SCRIPT-DOCKER ARGS"
 echo "CONTAINER: Use one, \"app01\" or use \"app-01,app-02,app-03\" " 
 echo "PLUGIN-SCRIPT-DOCKER: like check-container.rb, check-container-logs.rb, metrics-docker-stats.rb"
 echo "ARGS: like \"-h /var/run/docker.sock -c\". At last, pass \"-c\" or \"-n\" for indicate the container name used in script "
 exit 1
fi

IFS=", "
LIST_WITH_COMMA="$1"
COMMAND="$2"
OPTIONS="$3"
EXTRAS="$4 $5"

LIST_CONTAINERS=`$DOCKER ps -a| $AWK '{ print $NF }' | $GREP -v NAMES`

for container in ${LIST_WITH_COMMA}
  do

    container_solo=`echo $LIST_CONTAINERS | grep ^${container}`
    if [ "$4" == "metric" ]; then
      # Use this line to troubleshooting
      #echo $PWD/$COMMAND "$OPTIONS" $container_solo --schema $( hostname ).$container_solo
      $PWD/$COMMAND $OPTIONS $container_solo --schema $( hostname ).$container_solo
    else
      # Use this line to troubleshooting
      #echo $PWD/$COMMAND "$OPTIONS" $container_solo $EXTRAS
      $PWD/$COMMAND $OPTIONS $container_solo $EXTRAS
    fi

  done
