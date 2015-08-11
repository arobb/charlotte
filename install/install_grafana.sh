#!/bin/bash
# Installs Grafana

# Version to install
version="2.1.0"
goversion="1.4"

#Install Grafana
echo "Installing Grafana"
sudo npm install grunt --save-dev
sudo npm install -g grunt-cli --save-dev

source ~/.gvm/scripts/gvm
gvm use "go$goversion"

# Show the current $GOPATH
echo "Current GOPATH: $GOPATH"

# GVM has changed up where GOPATH is, so need to use it
mkdir -p $GOPATH/src/github.com/grafana
cd $GOPATH/src/github.com/grafana

# Download the source
git clone https://github.com/grafana/grafana.git
cd $GOPATH/src/github.com/grafana/grafana
git checkout tags/v"$version"

# Build the backend
# Godep setup
go run build.go setup

# Get dependencies
$GOPATH/bin/godep restore

# Build
go build .

# Build the front end
sudo npm install
sudo npm install -g grunt-cli
grunt


# Package
printf "\nPackaging Grafana\n"
#go run build.go build package
#go run build.go package

# Install the package
printf "\nInstalling Grafana package\n"
sudo dpkg -i dist/grafana_*.deb

# Start the service
printf "\nStarting Grafana server\n"
sudo service grafana-server start

# Check the service started
sudo service grafana-server status >/dev/null
status=$?

if [ "$status" -ne 0 ];
then
    echo "Something went wrong starting Grafana. Exiting."
    exit 1
else
    echo "Configuring the service to start at boot"
    sudo systemctl enable grafana-server.service
fi

printf "\nInstalled and started Grafana successfully.\n"
printf "\nWeb UI should be available at http://*:3000.\n"