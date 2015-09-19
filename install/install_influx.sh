#!/bin/bash
# Script to install InfluxDB (after dependencies have been satisfied)

# Version to install
version="0.9.2.1"
goversion="1.4"

# Install InfluxDB
echo "Installing InfluxDB"
sudo npm install grunt --save-dev
sudo npm install -g grunt-cli --save-dev

# Use go1.4
source ~/.gvm/scripts/gvm
gvm use "go$goversion"

# Show the current $GOPATH
echo "Current GOPATH: $GOPATH"

# GVM has changed up where GOPATH is, so need to use it
mkdir -p $GOPATH/src/github.com/influxdb
cd $GOPATH/src/github.com/influxdb

# Download the source
git clone https://github.com/influxdb/influxdb.git
cd $GOPATH/src/github.com/influxdb/influxdb

# Dependencies
cd $GOPATH/src/github.com/influxdb
go get -u -f -t ./...

# Build
go build ./...

# Install, whatever that means
go install ./...


# This is interesting. package.sh is provided by the product
#  but in order to build you have to provide a tag name that doesn't yet
#  exist. (Hints provided from http://www.genericmaker.com/2015/
#  04/updating-influxdb-grafana-raspberry-pi.html
cd $GOPATH/src/github.com/influxdb/influxdb

# Remove packages if they already exist
if [ -f influxdb_*.deb ];
then
    rm influxdb_*.deb
    rm influxdb_*.tar.gz
    rm influxdb-*.rpm
fi

git checkout tags/v"$version"
NIGHTLY_BUILD="v$version" ./package.sh "$version"
# Intentionally ignore errors here, we expect one regarding an S3 key


# Install the packaged version
printf "\nInstalling InfluxDB...\n"
sudo dpkg --install influxdb_*.deb
result=$?

if [ "$result" -ne 0 ];
then
    echo "Package build and setup for InfluxDB failed, installation incomplete."
    exit 1
else
    printf "Adding log rotation..."

    # Check that logrotate exists
    if [ -d /etc/logrotate.d ];
    then
       printf "/var/log/influxdb {\n  compress\n  rotate 5\n  size 1M\n  missingok\n  copytruncate\n}\n" | sudo tee /etc/logrotate.d/influxdb >/dev/null
       printf "\nDone\n"
    else
       printf "\nFailed"
       printf "\nPlease make sure to rotate /var/log/influxdb appropriately\n"
    fi
fi


# Start the service
echo "Starting InfluxDB"
sudo service influxdb start

# Check the service started
sudo service influxdb status >/dev/null
status=$?

if [ "$status" -ne 0 ];
then
    echo "Something went wrong starting InfluxDB. Exiting."
    exit 1
else
    echo "Configuring the service to start at boot"
    sudo systemctl enable influxdb.service

    printf "\nConfiguring process monitor to automatically restart the service\n"
    sudo tee /etc/monit/conf.d/influxdb >/dev/null <<- EOF
	check process influxd with pidfile /var/run/influxdb/influxd.pid
	group influxdb
	start program = "/etc/init.d/influxdb start"
	stop program = "/etc/init.d/influxdb stop"
	if failed host 127.0.0.1 port 8083
	protocol http then restart
	if 5 restarts within 5 cycles then timeout
	EOF

    sudo service monit restart >/dev/null
fi


printf "\nInstalled and started InfluxDB successfully.\n"
printf "\nAPI endpoint should be http://localhost:8086.\n"
printf "\nWeb UI should be available at http://localhost:8083.\n"
