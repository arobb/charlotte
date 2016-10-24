# Charlotte #
## Home network monitoring on Raspberry Pi ##

These steps guide the installation of the InfluxDB time-series datastore, Grafana web UI, a slew of dependencies, and make available a small Python daemon that can poll the local network for information, as well as the internal thermal sensor built into the Raspberry Pi SoC. These were built on a VM running Debian, and installed on a Pi 2. The 'estimated durations' below are approximately what I experienced when I ran these on a Pi 2; run times on the development VM (on a MacBook Pro host) were significantly faster.

The metrics collected include external traffic flow from the gateway using SNMP. While most of the metrics are auto-discovering, you'll need to change the MAC address of the external interface in bin/stats_daemon.py. For the collection to work, your router also must support SNMP, and must have it enabled. (It also needs to publish the same information the get_local_net_ext_traffic.sh script expects at the same SNMP OIDs.)

Additional latency measurements can be included easily by adding a name and IP to the list at the beginning of put_standard_latency_measurements.sh. The names become additional measurements in the "network" Influx database.

For those who care about such things, I want to call out that the following packages are installed during this process. See install/install_dependencies.sh for a full list:
- Bonjour (mdns, though this is installed by default)
- arp-scan
- snmp
- ruby
- go

FOR NODE OR NODE-RED USERS: The dependency installation script will install the newest version of node.js (directly from nodejs.org) which can also cause the reinstallation of node-red.

# Basics #
## Hardware ##
	Raspberry Pi 2 Model B
	Adafruit PiTFT 3.5" Resistive Touch Display HAT

## Operating System ##
	Raspbian (as of 2 Feb 2016)

## Influx DB ##
	Version 0.10.3
	UI http://*:8083
	REST API http://*:8086

## Grafana ##
	Version 2.6.0
	UI http://*:3000

## Running things ##
The stats collection daemon can be managed manually with the following, if you do not install the service:
```
$PWD/bin/stats_daemon.py start
```

and stopped with:
```
$PWD/bin/stats_daemon.py stop
```

For a reason that now escapes me, using '.' rather than $PWD does *not* work to start the daemon scripts. (They'll appear to start, but won't function.)


## APC, multicast scripts ##
To pull in the sub project that includes services for broadcasting data over multicast, use the following commands to pull and keep the subproject up-to-date  

First pull-down
```
git submodule update --init
```

Stay up to date
```
git submodule foreach git pull origin master
```


## Extras ##
I also installed Chromium following these directions: http://elinux.org/RPi_Chromium

And configured it to start on boot with a small Grafana dashboard I built, following these instructions:   https://www.danpurdy.co.uk/web-development/raspberry-pi-kiosk-screen-tutorial/

Hopefully I'll have a chance in the future to automate the process to include these components as well.


# Install #
From start-to-finish this will probably take between 3 and 3 1/2 hours – mostly on the install_dependencies.sh script.


## Precheck ##
If you're doing this on a new Pi, don't forget to grab recent updates/upgrades for your system. Even recent images can be out-of-date by the time you get them installed. These three commands all require an Internet connection.

Update the list of available packages:
```
sudo apt-get update
```

Install any available upgrades:
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
Install a time-series database.

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
Install a graphical web-UI for rendering time-series data.

### Service installation ###
Estimated duration: 35 minutes  
Run:
```
./install/install_grafana.sh
```


## Reporting service ##
Install the service that automatically starts the reporting daemon(s)

NOTE: Use the `install/install_service.sh` script to enable the two network and one temperature reporting daemons. Use `install/install_service_temperature.sh` to install _just_ the temperature daemon. Use `install/install_service_ups_send.sh` on all Pi's connected to APC UPS devices. Use `install/install_service_ups_receive.sh` only on the Pi that should record power metrics to the database.

Estimated duration: 5 seconds  
Run:  
```
sudo ./install/install_service.sh
```


**User Impersonation /dev/stdout error**  
If you attempt to start the script while impersonating another user (`sudo su`) You may get the following error: `IOError: [Errno 13] Permission denied: '/dev/stdout'`. The simple resolution is to log in as the user directly; more information is at the StackExchange thread below.
Solved with: http://unix.stackexchange.com/questions/38538/bash-dev-stderr-permission-denied


Stats are collected thusly:  
**Database**: network  
**Measurements**  
- internet
  - field: if (hard coded in bin/stats_daemon.py)
  - field: provider (hard coded in bin/stats_daemon.py)
  - field: router (hard coded to 'router01')
  - tag: state
  - tag: received_in_bytes
  - tag: sent_in_bytes
- local_latency
  - field: source_ip (Raspberry Pi's IP address)
  - field: target_ip
  - tag: value (ping time in whole milliseconds)

**Database**: temperature  
**Measurements**
- bramble00 (hard coded in bin/put_temperature.sh)
  - field: host
  - field: unit (hard coded to 'f' in bin/put_temperature.sh)

**Database**: power
**Measurements**
- power_line_volts
- power_load_pct
- power_battery_volts
- power_minutes_left
- power_battery_charge_pct
- power_seconds_on_battery
- power_status

There are five stand-alone daemons that poll independently. bin/stats_daemon.py performs most network collection, excluding the local network "all-ping" which is done in bin/stats_daemon_local_net_latency.py. Temperature readings are recorded from localhost via bin/temp_daemon.py. Power readings are read and broadcast by bin/ups_send_daemon.py, they are received and recorded to Influx via multicast-comms/receive-put-apc.py.

**Dashboard**  
Open a browser to Grafana. You'll need to configure your InfluxDB as a data source and build a dashboard. (I haven't automated that part yet.)  
http://raspberrypi.local:3000
