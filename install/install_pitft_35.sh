#!/usr/bin/env bash
# Install PiTFT 3.5" screen and configure to allow X to boot
# Still need to run raspi-config to configure boot option

# Directions adapted from https://learn.adafruit.com/adafruit-pitft-28-inch-resistive-touchscreen-display-raspberry-pi/extras#boot-to-x-windows-on-pitft
#  and  https://learn.adafruit.com/adafruit-pitft-3-dot-5-touch-screen-for-raspberry-pi/faq

# Move a potentially conflicting file
sudo mv /usr/share/X11/xorg.conf.d/99-fbturbo.conf /tmp >/dev/null 2>/dev/null

# Create the PiTFT configuration file
echo "Creating PiTFT config file..."
conffile="/usr/share/X11/xorg.conf.d/99-pitft.conf"

printf "Section \"Device\"\n" >$conffile
printf "\tIdentifier \"Adafruit PiTFT\"\n" >>$conffile
printf "\tDriver \"fbdev\"\n" >>$conffile
printf "\tOption \"fbdev\" \"/dev/fb1\"\n" >>$conffile
printf "EndSection" >>$conffile

# Install the drivers
echo "Configuring adafruit repo..."
curl -SLs https://apt.adafruit.com/add | sudo bash

echo "Installing loader changes and Pi helper"
sudo apt-get install raspberrypi-bootloader
sudo apt-get install adafruit-pitft-helper
