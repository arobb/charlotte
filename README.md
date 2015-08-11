# Charlotte #
## Home network monitoring on Raspberry Pi ##

*This is the first round, I don't expect all this to work until I've removed this message.*

This will install the InfluxDB time-series datastore and Grafana web UI, a slew of dependencies, and make available a small Python daemon that can poll the local network for information.

# Basics #
## Hardware ##
	Raspberry Pi 2 Model B
	Adafruit PiTFT 3.5" Resistive Touch Display HAT

## Influx DB ##
	Version 0.9.2.1
	UI http://localhost:8083
	REST API http://localhost:8086

## Grafana ##
	Version 2.1.0
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

And configured it to start on boot with the small dashboard I built, following these instructions: https://www.danpurdy.co.uk/web-development/raspberry-pi-kiosk-screen-tutorial/


# Install #
## Precheck ##
If you're doing this on a new Pi, don't forget to grab recent updates/upgrades for your system. Even recent images can be out of date by the time you get them installed. These three commands all require an Internet connection.

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
This will perform the basic prep tasks and start the PiTFT Easy Install script. This does the top part of https://learn.adafruit.com/adafruit-pitft-3-dot-5-touch-screen-for-raspberry-pi/easy-install .

*You will need to press enter a few times during this script!*
You will need to respond **YES** to these prompts.

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
sudo shutdown -r now
```


## Service Dependencies ##
This will install a fairly large set of dependencies.

Run:
```
./install/install_dependencies.sh
```


## InfluxDB ##
*You will need to press enter a few times during this script!* But you don't need to enter any info. Hopefully.

### Service installation ###
Run:
```
./install/install_influx.sh
```


### Service configuration ###
Create the basic network database and retention policy

Run:
```
./install/configure_influx.sh
```


## Grafana ##
Run:
```
./install/install_grafana.sh
```
