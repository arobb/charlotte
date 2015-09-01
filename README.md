# Charlotte #
## Home network monitoring on Raspberry Pi ##

These steps guide the installation of the InfluxDB time-series datastore, Grafana web UI, a slew of dependencies, and make available a small Python daemon that can poll the local network for information. These were built on a VM running Debian, and installed on a Pi 2. The 'estimated durations' below are approximately what I experienced when I ran these on a Pi 2; run times on the development VM (on a MacBook Pro host) were significantly faster.

For those who care about such things, I want to call out that the following packages are installed during this process. See install/install_dependencies.sh for a full list:
- Bonjour (mdns, though this is installed by default)
- arp-scan
- snmp
- ruby
- go
- node.js

# Basics #
## Hardware ##
	Raspberry Pi 2 Model B
	Adafruit PiTFT 3.5" Resistive Touch Display HAT

## Operating System ##
	Raspbian (as of 10 Aug 2015)

## Influx DB ##
	Version 0.9.2.1
	UI http://localhost:8083
	REST API http://localhost:8086

## Grafana ##
	Version 2.1.3
	UI http://*:3000

## Running things ##
The stats collection daemon can be started with:
```
./bin/stats_daemon.py start
```

and stopped with:
```
./bin/stats_daemon.py stop
```

The other services should be started automatically by the installers, and are configured to start at boot.


## Extras ##
I also installed Chromium following these directions: http://elinux.org/RPi_Chromium

And configured it to start on boot with a small Grafana dashboard I built, following these instructions: https://www.danpurdy.co.uk/web-development/raspberry-pi-kiosk-screen-tutorial/

Hopefully I'll have a chance in the future to automate the process to include these components as well.


# Install #
From start-to-finish this will probably take between 3 and 3 1/2 hours – mostly on the install_dependencies.sh script.


## Precheck ##
If you're doing this on a new Pi, don't forget to grab recent updates/upgrades for your system. Even recent images can be out-of-date by the time you get them installed. These three commands all require an Internet connection.

Update the list of available packages:
```
sudo apt-get update
```

Install any available up*grades*:
```
sudo apt-get upgrade
```

Install any "os" level upgrades:
```
sudo apt-get dist-upgrade
```


## PiTFT 3.5" ##
This will perform the basic prep tasks, but you'll then need to run the PiTFT Helper yourself (command also below). install_pitft_35.sh does the top part of https://learn.adafruit.com/adafruit-pitft-3-dot-5-touch-screen-for-raspberry-pi/easy-install .

*You will need to press enter a few times during this script!*
You will need to respond **YES** to these prompts.

Estimated duration: 5 minutes
Run:
```
sudo ./install/install_pitft_35.sh
```

Run the PiTFT configuration script:
```
sudo adafruit-pitft-helper -t 35r
```

Reboot:
```
sudo reboot
```


## Service Dependencies ##
This will install a fairly large set of dependencies.

Estimated duration: 2 hours 30 minutes
Run:
```
./install/install_dependencies.sh
```


## InfluxDB ##
*You will need to press enter a few times during this script!* 
But you don't need to enter any info. Hopefully.

### Service installation ###
Estimated duration: 7 minutes
Run:
```
./install/install_influx.sh
```


### Service configuration ###
Create the basic network database and retention policy

Estimated duration: 1 second
Run:
```
./install/configure_influx.sh
```


## Grafana ##
Estimated duration: 35 minutes
Run:
```
./install/install_grafana.sh
```


## DONE! ##
You should be ready to go. Start the stats collection daemon: (From the project root)
```
$PWD/bin/stats_daemon.py start
```

**PLEASE NOTE**: The daemon is not yet configured to start on boot, so you'll need to re-run this command whenever you restart the Pi! (One extremely dirty option would be to run the command with cron, piping output to /dev/null; the daemon uses a PID file to maintain a single instance, so this should not create multiple instances, however you will lose any error messages that would otherwise be written to the terminal.)


**User Impersonation /dev/stdout error**
If you attempt to start the script while impersonating another user (`sudo su`) You may get the following error: `IOError: [Errno 13] Permission denied: '/dev/stdout'`. The simple resolution is to log in as the user directly; more information is at the StackExchange thread below.
Solved with: http://unix.stackexchange.com/questions/38538/bash-dev-stderr-permission-denied


Stats are collected thusly:
**Database**: network
**Measurements**
- internet
  - field: if (hard coded to 'wan1')
  - field: provider (hard coded to 'comcast')
  - field: router (hard coded to 'router01')
  - tag: state
  - tag: received_in_bytes
  - tag: sent_in_bytes
- local_latency
  - field: source_ip (Raspberry Pi's IP address)
  - field: target_ip
  - tag: value (ping time in whole milliseconds)

And open a browser to Grafana. You'll need to configure your InfluxDB as a data source and build a dashboard. (I haven't automated that part yet.)
http://raspberrypi.local:3000
