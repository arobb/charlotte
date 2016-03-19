#!/bin/bash

influxhostport="localhost:8086"
influxdatabase="network"
influxtable="local_latency"

if [ -z $1 ];
then
    echo "Please provide an interface name as the first and only parameter"
    exit 1
fi

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
        myip=$(ip -4 addr show $1 | grep 'inet ' | grep -v 127.0.0.1 | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;

    *)
        platform='linux'
        myip=$(ip -4 addr show $1 | grep 'inet ' | grep -v 127.0.0.1 | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;
esac


# Get a list of IPs and ping latencies in milliseconds
epoch=$(date +%s)
submission=""

SAFEIFS=$IFS
IFS=$'\n'

# Get ping results
results=($($DIR/get_local_net_latency.sh $1))

IFS=$SAVEIFS

# Length of results
rlen=${#results[@]}

for (( i=0; i<${rlen}; i++ ));
do
    pair="${results[$i]}"
    addr=$(echo "$pair" | cut -f1)
    latency=$(echo "$pair" | cut -f2)

    host="INSERT $influxtable,source_ip=$myip,target_ip=$addr value=$latency""i"" $epoch"000000000

    submission=$(echo -e "$host\n$submission")
done

# Submit
#run="curl --silent --show-error -i -XPOST \"http://$influxhostport/write?db=$influxdatabase&precision=s\" --data-binary \"$submission\""
run="influx -database \"$influxdatabase\" -execute \"$submission\""

echo "$run"
bash -c $run
