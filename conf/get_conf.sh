#!/usr/bin/env bash
# Usage
# get_conf.sh <config parameter>
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. $DIR/conf.sh

echo ${!1}
