#!/bin/bash
# Install dependencies for InfluxDB and Grafana
# Will ask for sudo password (via sudo)


printf "\nThis script will first install the following:\n"
printf "\tGPG\n"
printf "\topenssl\n"
printf "\tlibssl-dev\n"
printf "\tbc\n" # For monitor scripts
printf "\tBonjour\n"
printf "\tarp-scan\n"
printf "\tSNMP tools\n"
printf "\tcurl\n"
printf "\tgit\n"
printf "\tmercurial\n"
printf "\tmake\n"
printf "\tcheckinstall\n"
printf "\tbinutils\n"
printf "\tmonit\n"
printf "\truby\n" # For FPM, in turn for Influx package.sh
printf "\truby-dev\n" # For FPM, in turn for Influx package.sh
printf "\tbison\n"
printf "\tgcc\n"
printf "\tbuild-essential\n"
printf "\talien\n" # For Influx package.sh, provides rpmbuild command
printf "\n\n"
printf "This script will then install:\n"
printf "\tFPM effing package management\n"
printf "\n\n"
printf "This script will then install:\n"
printf "\tGo version manager\n"
printf "\tgo\n"
printf "\n\n"
printf "This script will then:\n"
printf "\tUninstall nodejs-legacy and nodered\n"
printf "\tInstall the current version of node.js\n"
printf "\tInstall the current version of node-red\n"
printf "\n\n"
printf "Getting started...\n"

sudo apt-get --quiet -y install gnupg openssl libssl-dev bc libnss-mdns arp-scan snmp curl git mercurial make checkinstall binutils monit ruby ruby-dev bison gcc build-essential alien
result=$?

if [ "$result" -ne 0 ];
then
    echo "Dependency install failed. Exiting."
    exit 1
fi


# Make arp-scan usable
printf "\nMaking arp-scan usable by non-root users\n"
printf "This is a potential security risk, change this back if\n"
printf "you do not trust users on this machine\n"
printf "Change this back with 'sudo chmod u-s /usr/bin/arp-scan'\n"
sudo chmod u+s /usr/bin/arp-scan


# Install FPM
printf "\nInstalling FPM package helper...\n"
sudo gem install fpm
result=$?


# Install Go manager (required for full use of InfluxDB helper utilities)
printf "\nInstalling Go manager 'gvm'...\n"
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

# Activate
echo "Running 'source /home/$(whoami)/.gvm/scripts/gvm'"
source /home/$(whoami)/.gvm/scripts/gvm

# Install Go
gvm install go1.5
gvm install go1.4.3
result=$?

if [ "$result" -ne 0 ];
then
    echo "Go did not install correctly. Exiting."
    exit 1
fi

# Set go 1.5 as the default version
gvm use go1.5 --default

# Configure a work directory
printf "\nConfiguring the Go work directory...\n"
printf "\t/home/"$(whoami)"/gocode\n"
printf "\tYou can update this in /home/"$(whoami)"/.bashrc\n"

# Only create the work directory if it doesn't already exist
if [ ! -d /home/$(whoami)/gocode ];
then
    mkdir /home/$(whoami)/gocode
fi

# Append the GOPATH to the user's bash RC file if it is not already done
grep 'GOPATH=' /home/$(whoami)/.bashrc >/dev/null
pathsearch=$?
if [ "$pathsearch" -ne 0 ];
then
    echo 'export GOPATH="/home/'$(whoami)'/gocode"' >> /home/$(whoami)/.bashrc
fi

# Make the GOPATH available now
export GOPATH=/home/$(whoami)/gocode

# Install NodeJS
printf "\nInstalling node.js\n"
nodedir="/tmp/node_js_src"

# Download location
if [ ! -d $nodedir ];
then
    mkdir $nodedir
fi

# Switch to the source directory
cd $nodedir

# Pull down the hashes for the current files
printf "Downloading node binary"
curl --silent -o $nodedir/SHASUMS256.txt.asc https://nodejs.org/dist/latest/SHASUMS256.txt.asc
printf "\n"

# Identify the filename for our architecture's binary
nodebinary=$(grep "$(uname --machine).*gz" SHASUMS256.txt.asc | awk '{print $2}')

# Pull down the node source code if we don't already have it
if [ ! -f $nodedir/node-latest.tar.gz ];
then
    printf "Downloading node binary"
    curl -o $nodedir/node-latest.tar.gz http://nodejs.org/dist/latest/$nodebinary
    printf "\n"
fi

# Verify the hash of the download we have
publishedsha=$(grep "node-v[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}.tar.gz" $nodedir/SHASUMS256.txt.asc | cut -d' ' -f1)
currentsha=$(sha256sum $nodedir/node-latest.tar.gz | cut -d' ' -f1)

# If they don't match, download the binary again
#TODO this should be reconciled with the previous file check
#TODO verify this is the right place for the uninstall
# so that there is only one possible download
if [ "$currentsha" != "$publishedsha" ];
then
    printf "Hashes did not match, downloading source again"
    rm -f $nodedir/node-latest.tar.gz
    curl -o $nodedir/node-latest.tar.gz http://nodejs.org/dist/latest/$nodebinary
    printf "\n"

    # If node is already installed, remove it
    dpkg-query --status node 1>/dev/null
    result=$?

    if [ "$result" -eq 0 ];
    then
        echo "Removing existing node package"
        sudo dpkg -r node
    fi
fi

echo "Current location: "$(pwd)

# Untar
printf "Extracting node binary"
tar xzf $nodedir/node-latest.tar.gz
printf "\n"

# Remove conflicting nodejs-legacy
printf "Removing nodejs-legacy and older nodered"
sudo apt-get -y --purge remove nodejs-legacy
printf "\n"

# Install current version of nodejs
printf "Installing current version of nodejs"
cd $nodedir/node-v*
sudo dpkg --install node_*.deb
printf "\n"

# Replace node-red
printf "Replacing node-red\n"
sudo npm install -g node-red
printf "\n"

# Remove temporary directory
printf "Cleaning up..."
cd /tmp
sudo rm -rf $nodedir
printf "\n"

printf "\nDependency installation complete\n"
