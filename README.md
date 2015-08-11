= Charlotte = 
== Home network monitoring on Raspberry Pi ==

*This is the first round, I don't expect all this to work until I've removed this message.*

This will install the InfluxDB time-series datastore and Grafana web UI, a slew of dependencies, and make available a small Python daemon that can poll the local network for information.

= Basics =
== Hardware ==
	Raspberry Pi 2 Model B
	Adafruit PiTFT 3.5" Resistive Touch Display HAT

== Influx DB ==
	Version 0.9.2.1
	UI http://localhost:8083
	REST API http://localhost:8086

== Grafana ==
	Version 2.1.0
	UI http://*:3000

== Running things ==
The stats collection daemon can be started with:
./bin/stats_daemon.py start

and stopped with:
./bin/stats_daemon.py stop

The other services should be started automatically by the installers, and are configured to start at boot.


= Install =
== PiTFT 3.5" ==
This will perform the basic prep tasks and start the PiTFT Easy Install script.

Run:
./install/install_pitft_35.sh


== Service Dependencies ==
This will install a fairly large set of dependencies.

Run:
./install/install_dependencies.sh


== InfluxDB ==
*You will need to press enter a few times during this script!* But you don't need to enter any info. Hopefully.

=== Service installation ===
Run:
./install/install_influx.sh


=== Service configuration ===
Create the basic network database and retention policy

Run:
./install/configure_influx.sh


== Grafana ==
Run:
./install/install_grafana.sh

