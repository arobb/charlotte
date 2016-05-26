#!/bin/bash

influxhostport="localhost:8086"
influxdatabase="network"
#influxtable="google_dns_latency"
#target="8.8.8.8"

declare -A measurements
measurements[att_bridge_latency]="192.168.1.254"
measurements[att_gateway_latency]="162.238.124.1"
measurements[comcast_bridge_latency]="192.168.100.1"
measurements[comcast_gateway_latency]="24.5.80.1"
measurements[google_dns_latency]="8.8.8.8"



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


# Get ping latency in milliseconds
epoch=$(date +%s)
submission=""

SAFEIFS=$IFS
IFS=$'\n'


for i in "${!measurements[@]}"
do
  # Get ping results
  target="${measurements[$i]}"
  results=$($DIR/get_roundtrip_latency.sh "$target")

  addr=$(echo "$results" | cut -f1)
  latency=$(echo "$results" | cut -f2)

  submission="$i,source_ip=$myip,target_ip=$addr value=$latency""i"" $epoch"000000000

  # Submit
  run="influx -database \"$influxdatabase\" -execute \"INSERT $submission\""

  echo "$run"
  bash -c $run
done
