#!/bin/bash

if [ -z $1 ];
then
    echo "Please provide an interface name as the first and only parameter"
    exit 1
fi

DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

# Use an arp-scan to detect all the local IP addresses
# This would normally require root, but arp-scan can be make globally usable with
#  sudo chmod u+s /usr/bin/arp-scan
for i in $(arp-scan --interface=$1 --localnet | tail -n+3 | grep '^[0-9]\{1,3\}[.]' | cut -f1 | sort -u);
do
    # Start each as a background job so we don't wait forever
    $DIR/get_roundtrip_latency.sh "$i" &
done

# Wait to return control until all background jobs complete
wait
