#!/usr/bin/env bash
# Script to configure a database for network stats after InfluxDB has been installed

# Create default db for stats
curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE DATABASE network"
echo ""

# Apply reasonable (2 month) retention period
curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE RETENTION POLICY twomonths ON network DURATION 60d REPLICATION 1 DEFAULT"
echo ""


# Create db for temperature
curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE DATABASE temperature"
echo ""

# Apply reasonable (2 month) retention period
curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE RETENTION POLICY twomonths ON temperature DURATION 60d REPLICATION 1 DEFAULT"
echo ""


# Create db for power
curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE DATABASE power"
echo ""

# Apply reasonable (2 month) retention period
curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE RETENTION POLICY twomonths ON power DURATION 60d REPLICATION 1 DEFAULT"
echo ""
