#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Import configuration
. $DIR/../conf/conf.sh

# Get arguments
show_help()
{
    echo "Please provide three string arguments: 'i' the interface label, 'm' the interface MAC address, and 'p' the provider label."
}

OPTIND=1 # Reset counter for getopts
interface=""
mac=""
provider=""

while getopts "hi:m:p:" opt; do
    case $opt in
        i)
            interface="$OPTARG"
            ;;
        m)
            mac="$OPTARG"
            ;;
        p)
            provider="$OPTARG"
            ;;
        h|\?)
            show_help
            exit 0
            ;;
        :)
            echo "'$OPTARG' requires a string argument"
    esac
done


exitnow=0
if [ -z "$interface" ];
then
    echo "'i' not set"
    exitnow=1
fi

if [ -z "$mac" ];
then
    echo "'m' not set"
    exitnow=1
fi

if [ -z "$provider" ];
then
    echo "'p' not set"
    exitnow=1
fi

if [ "$exitnow" -eq "1" ];
then
    show_help
    exit 1
fi


# Determine which platform we're on since the responses vary
platform='unknown'
unamestr=$(uname)

case $unamestr in
    Darwin)
        platform='mac'
        myip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2)
        ;;

    Linux)
        platform='linux'
        myip=$(ip -4 addr show | grep 'inet ' | grep -v 127.0.0.1 | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;

    *)
        platform='linux'
        myip=$(ip -4 addr show | grep 'inet ' | grep -v 127.0.0.1 | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | cut -d'/' -f1)
        ;;
esac


# Get a list of IPs and ping latencies in milliseconds
epoch=$(date +%s)
submission=""

SAFEIFS=$IFS
IFS=$'\n'

# Get ping results
results=($($DIR/get_local_net_ext_traffic.sh "$mac"))
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

submission="$influxtable,router=$router,if=$interface,provider=$provider state=$state""i"",received_in_bytes=$received""i"",sent_in_bytes=$sent""i"" $epoch"000000000

echo $submission

# Submit
#run="curl --silent --show-error -i -XPOST \"http://$influxhostport/write?db=$influxdatabase&precision=s\" --data-binary \"$influxtable,router=$router,if=$interface,provider=$provider state=$state,received_in_bytes=$received,sent_in_bytes=$sent $epoch\""
run="influx -database \"$influxdatabase\" -execute \"INSERT $submission\""

echo "$run"
bash -c $run
