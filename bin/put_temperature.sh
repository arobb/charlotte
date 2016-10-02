#!/usr/bin/env bash

influxhostport="raspberrypi.local:8086"
influxdatabase="temperature"
influxtable="bramble00"


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

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

# Make sure the command is available
command -v vcgencmd >/dev/null 2>&1
if [ "$?" -ne "0" ];
then
  echo 1>&2 "Temp read command (vcgencmd) not found"
  exit 1
fi

# Get temperature
temp=$(vcgencmd measure_temp | sed -n 's/temp=\([0-9.]*\).*$/\1/p' | bc <<< "9 / 5 * `cat` + 32")
h=$(hostname -s | tr '[:upper:]' '[:lower:]')

submission="$influxtable,host=$h,unit=f value=$temp $epoch"

# Submit
run="curl --silent --show-error -H 'Content-Type: text/plain' -i -XPOST \"http://$influxhostport/write?db=$influxdatabase&precision=s\" --data-binary \"$submission\""

echo "$run"
bash -c $run
