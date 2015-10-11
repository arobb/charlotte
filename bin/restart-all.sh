#!/bin/bash

DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))

$DIR/stop-all.sh
echo "$DIR/stop-all.sh: $?"

$DIR/start-all.sh
echo "$DIR/start-all.sh: $?"
