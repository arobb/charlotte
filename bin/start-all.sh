#!/bin/bash

$PWD/bin/stats_daemon.py start
$PWD/bin/stats_daemon_bridge.py start
$PWD/bin/stats_daemon_bridge_att.py start
$PWD/bin/stats_daemon_comcast.py start
$PWD/bin/stats_daemon_att.py start
$PWD/bin/stats_daemon_google.py start
