#!/bin/bash

if [ -z $1 ];
then
    echo "Please provide a host or IPv4 address as the first parameter"
    exit 1
fi

if [ -z $2 ];
then
    echo "Please provide a TCP port as the second parameter"
    exit 1
fi


# Use netcat to check whether we can connect to a given port with a 1 second timeout
rawtime=$({ time nc -z -w 1 $1 $2 1>/dev/null 2>/dev/null ; } 2>&1 | grep "real" | cut -f2 | cut -ds -f1 | cut -dm -f2)
response="$?"


if [ "$response" -ne "0" ];
then
    output="-1"

else
    output=$(echo "$rawtime * 1000" | bc | cut -d. -f1)
fi


echo -e "$1\t$output"
