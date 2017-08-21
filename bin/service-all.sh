#!/usr/bin/env bash

$PWD/bin/stats_daemon.py $1
$PWD/bin/stats_daemon_local_net_latency.py $1
$PWD/bin/temp_daemon.py $1
