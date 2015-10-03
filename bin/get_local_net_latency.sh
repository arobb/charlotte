#!/bin/bash

if [ -z $1 ];
then
    echo "Please provide an interface name as the first and only parameter"
    exit 1
fi

# Use an arp-scan to detect all the local IP addresses
# This would normally require root, but arp-scan can be make globally usable with
#  sudo chmod u+s /usr/bin/arp-scan
for i in $(arp-scan --interface=$1 --localnet | tail -n+3 | grep '^[0-9]\{1,3\}[.]' | cut -f1 | sort | uniq);
do
    # Ping a host, strip trailing newlines (thanks to StackOverflow user dogbane)
    #  then takes only the last line
    # http://stackoverflow.com/questions/7359527/removing-trailing-starting-newlines-with-sed-awk-tr-and-friends
    presponse=$(ping -c 1 -W 1 $i | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' | tail -1)

    # Check if the response we got starts with a "1"
    # Only bad responses will start that way, otherwise they'd start with text
    # Bad: "1 packets transmitted, 0 packets received, 100.0% packet loss"
    # Good (OS X): "round-trip min/avg/max/stddev = 2.054/2.054/2.054/0.000 ms"
    # Good (Debian): "rtt min/avg/max/mdev = 2.558/2.558/2.558/0.000 ms"
    if [[ "$presponse" =~ ^1.* ]];
    then
        response='-1'
    else
        response=$(echo "$presponse" | cut -d' ' -f4 | cut -d'/' -f2)
        response=$(echo "scale=0; $response"' / 1' | bc -l )
    fi

    echo -e "$i\t$response"
done
