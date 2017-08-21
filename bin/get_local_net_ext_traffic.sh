#!/usr/bin/env bash
#
#  Created by Andy Robb on 8/8/15.
#
# Mac address in any combination
# F0 9F C2 1E C5 CA
# f0:9f:c2:1e:c5:ca

#OID if status: .1.3.6.1.2.1.2.2.1.8.index
#OID if in: .1.3.6.1.2.1.31.1.1.1.6.index
#OID if out: .1.3.6.1.2.1.31.1.1.1.10.index

# Status returns 1 for up and 2 for down

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Import configuration
. $DIR/../conf/conf.sh

# SNMP locators for specific metrics
oidstatus=".1.3.6.1.2.1.2.2.1.8"
oidin=".1.3.6.1.2.1.31.1.1.1.6"
oidout=".1.3.6.1.2.1.31.1.1.1.10"

# Make sure we received a MAC address as the first parameter
if [ -z "$1" ];
then
    echo "Please provide a space-separated MAC address as the first and only parameter"
    exit 1
fi

# Pull the parameter into a named parameter
mac="$1"

# Get the local gateway
gateway=$(netstat -rn | grep 'UG' | awk '{print $2}' | grep '^[0-9]\{1,3\}\.')

# Get the gateway interface SNMP MIB index
# -On: print numeric values
ifrawoid=$(snmpwalk -v 2c -On -c $snmp_community $gateway | grep '.1.3.6.1.2.1.2.2.1.6')
result=$?

if [ "$result" -ne 0 ];
then
    echo "$0 unable to get interface index. Router might not support SNMP"
    exit 1
fi

# Determine whether the values are Hex-Strings or just normal strings
# hashexstring is "has hex string"
hashexstring=$(echo "${ifrawoid[@]}" | grep "Hex-STRING" | wc -l | awk '{$1=$1;print}')

# Configure the mac address to match
# Hex-STRING: F0 9F C2 1E C5 CA
#     STRING: f0:9f:c2:1e:c5:cb
if [ "$hashexstring" -gt "0" ];
then
  mac=$(echo $mac | \
    tr '[:lower:]' '[:upper:]' | \
    tr ':' ' ')

else
  mac=$(echo $mac | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' ':')
fi

# Get the numeric index for the interface specified by the given MAC address
ifindex=$(echo "${ifrawoid[@]}" | grep "$mac" | rev | cut -d'.' -f1 | rev | cut -d' ' -f1)

# Get the info. status/in/out
# -O qv: show only value portion of key:value pair
# -Oe: print numeric value of enum values (up/down as numeric)
snmpget -O qv -Oe -v 2c -c $snmp_community $gateway "$oidstatus.$ifindex" "$oidin.$ifindex" "$oidout.$ifindex"
result=$?

exit $result
