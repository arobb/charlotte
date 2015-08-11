#!/bin/bash

influxhostport="localhost:8086"
influxdatabase="network"
influxtable="internet"
router="router01"
interface="wan1"
provider="comcast"

DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

platform='unknown'
unamestr=$(uname)

case $unamestr in
    Darwin)
        platform='mac'
        myip=$(ifconfig $1 | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2)
        ;;

    Linux)
        platform='linux'
        myip=$(ip -4 addr show $1 | grep 'inet ' | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;

    *)
        platform='linux'
        myip=$(ip -4 addr show $1 | grep 'inet ' | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;
esac


# Get a list of IPs and ping latencies in milliseconds
epoch=$(date +%s)
submission=""

SAFEIFS=$IFS
IFS=$'\n'

# Get ping results
results=($($DIR/get_local_net_ext_traffic.sh))
result=$?

if [ "$result" -ne 0 ];
then
    echo "Unable to retrieve traffic info. Router might not support SNMP"
    exit 1
fi

IFS=$SAVEIFS

# Length of results
rlen=${#results[@]}

state=2
received=0
sent=0

for (( i=0; i<${rlen}; i++ ));
do
    value="${results[$i]}"

    case $i in

        0)
            state=$value
            ;;

        1)
            received=$value
            ;;

        2)
            sent=$value
            ;;
    esac
done

# Submit
run="curl --silent --show-error -i -XPOST \"http://$influxhostport/write?db=$influxdatabase&precision=s\" --data-binary \"$influxtable,router=$router,if=$interface,provider=$provider state=$state,received_in_bytes=$received,sent_in_bytes=$sent $epoch\""

echo "$run"
bash -c $run