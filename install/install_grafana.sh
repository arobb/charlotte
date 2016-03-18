#!/bin/bash
# Installs Grafana

# Version to install
version="2.6.0"
goversion="1.5"

#Install Grafana
printf "\nInstalling Grafana\n"
sudo npm install grunt --save-dev
sudo npm install -g grunt-cli --save-dev

source ~/.gvm/scripts/gvm
gvm use "go$goversion"

# Show the current $GOPATH
printf "\nCurrent GOPATH: $GOPATH\n"

# GVM has changed up where GOPATH is, so need to use it
mkdir -p $GOPATH/src/github.com/grafana
cd $GOPATH/src/github.com/grafana

# Download the source
git clone https://github.com/grafana/grafana.git
cd $GOPATH/src/github.com/grafana/grafana
git pull origin master
git checkout tags/v"$version"
result=$?

if [ "$result" -ne "0" ];
then
	printf "\nGit operations failed, exiting install. Please resolve errors above and try again.\n"
	exit 1
fi


# Get ARM/RPi version of PhantomJS
arch=$(uname -m)

if [[ $arch == arm* ]];
then

	cd $GOPATH/src/github.com/grafana/grafana/vendor/phantomjs

	if [ ! -f phantomjs.amd64 ];
	then
		mv phantomjs phantomjs.amd64
	fi

	if [ ! -f /usr/local/bin/phantomjs ];
	then
		printf "\nDownloading PhantomJS 1.9.8 for Raspberry Pi\n"
		sudo curl --silent -L -o /usr/local/bin/phantomjs https://github.com/piksel/phantomjs-raspberrypi/raw/master/bin/phantomjs

		sudo chmod +x /usr/local/bin/phantomjs

		# Copy it to the vendor directory
		cp /usr/local/bin/phantomjs ./
		sudo chown pi:pi phantomjs

	fi

	# Patch requirejs.js to handle slow drives, per this comment thread
	# https://github.com/grafana/grafana/issues/2183#issuecomment-131439150
	cd $GOPATH/src/github.com/grafana/grafana/tasks/options
	patch --forward --silent requirejs.js >/dev/null <<EOF
*** requirejs.js.old	2015-08-22 02:52:18.553465630 +0000
--- requirejs.js	2015-08-22 02:19:29.942872946 +0000
***************
*** 21,26 ****
--- 21,28 ----
        inlineText: true,
        skipPragmas: true,
  
+       waitSeconds: 0, // Raspberry Pi builds https://github.com/grafana/grafana/issues/2183#issuecomment-131439150
+ 
        done: function (done, output) {
          var duplicates = require('rjs-build-analysis').duplicates(output);
  
EOF

	# In case patching fails (likely because it already happened)
	# a file will be created that needs to be deleted
	rm requirejs.js.rej 2>/dev/null

	cd $GOPATH/src/github.com/grafana/grafana
fi


# Build the backend
printf "\nBuilding Grafana backend\n"
# Godep setup
go run build.go setup

# Get dependencies
$GOPATH/bin/godep restore

# Build
go build .
go run build.go build
result=$?

if [ "$result" -ne "0" ];
then
	printf "\nGrafana backend build failed. Exiting."
	exit 1
fi


# Build the front end
printf "\nBuilding Grafana frontend\n"
sudo npm install
sudo npm install -g grunt-cli
grunt
result=$?

if [ "$result" -ne "0" ];
then
        printf "\nGrafana frontend build failed. Exiting."
        exit 1
fi


# Package
printf "\nPackaging Grafana\n"
#go run build.go build package
go run build.go package
result=$?

if [ "$result" -ne "0" ];
then
        printf "\nGrafana packaging failed. Exiting."
        exit 1
fi


# Install the package
printf "\nInstalling Grafana package\n"
sudo dpkg -i dist/grafana_*.deb
result=$?

if [ "$result" -ne "0" ];
then
        printf "\nGrafana package install failed. Exiting."
        exit 1
fi


# Start the service
printf "\nStarting Grafana server\n"
sudo service grafana-server start
result=$?

if [ "$result" -ne "0" ];
then
        printf "\nGrafana service failed to start. Exiting install script."
        exit 1
fi


# Check the service started
sudo service grafana-server status >/dev/null
status=$?

if [ "$status" -ne 0 ];
then
    printf "\nSomething went wrong starting Grafana. Exiting.\n"
    exit 1
else
    printf "\nConfiguring the service to start at boot\n"
    sudo systemctl enable grafana-server.service

    printf "\nConfiguring process monitor to automatically restart the service\n"
    sudo tee /etc/monit/conf.d/grafana-server >/dev/null <<- EOF
	check process grafana-server with pidfile /var/run/grafana-server.pid
	group grafana
	start program = "/etc/init.d/grafana-server start"
	stop program = "/etc/init.d/grafana-server stop"
	if failed host 127.0.0.1 port 3000
	protocol http then restart
	if 5 restarts within 5 cycles then timeout
	EOF

    sudo service monit restart >/dev/null
fi

printf "\nInstalled and started Grafana successfully.\n"
printf "\nWeb UI should be available at http://*:3000.\n"
