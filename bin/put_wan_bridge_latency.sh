#!/bin/bash

influxhostport="localhost:8086"
influxdatabase="network"
influxtable="wan_bridge_latency"
target="192.168.100.1"


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
        myip=$(ip -4 addr show $1 | grep 'inet ' | grep -v '127.0.0.1' | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;

    *)
        platform='linux'
        myip=$(ip -4 addr show $1 | grep 'inet ' | grep -v '127.0.0.1' | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;
esac


# Get ping latency in milliseconds
epoch=$(date +%s)
submission=""

SAFEIFS=$IFS
IFS=$'\n'

# Get ping results
results=$($DIR/get_roundtrip_latency.sh "$target")

addr=$(echo "$results" | cut -f1)
latency=$(echo "$results" | cut -f2)

submission="$influxtable,source_ip=$myip,target_ip=$addr value=$latency $epoch"

# Submit
run="curl --silent --show-error -i -XPOST \"http://$influxhostport/write?db=$influxdatabase&precision=s\" --data-binary \"$submission\""

echo "$run"
bash -c $run
