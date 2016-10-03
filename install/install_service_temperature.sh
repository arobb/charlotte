#!/usr/bin/env bash
# Generate and install the SystemD service
# Installs JUST the temoerature daemon
#
# Remove service with:
# systemctl disable charlotte.service
# systemctl stop charlotte.service
# rm /lib/systemd/system/charlotte.service


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


# Configure some values
REALUSER=$(who am i | awk '{print $1}')
SERVICE="systemd"
FILENAME="charlotte.service"
FILEPATH="$DIR/../etc/$SERVICE"


# Make sure an existing charlotte.service is not installed
if [ -f "/etc/systemd/system/multi-user.target.wants/$FILENAME" ];
then
  echo "Service already appears to be installed."
  echo "Please remove existing service '$FILENAME' before installing this one."
  echo "If you have already run 'install/install_service.sh' you do not also"
  echo "  need to install this service."
  exit 1
fi


# Make sure we are running as root
if [ "$(whoami)" != "root" ];
then
  echo "$(basename $0) must be run as root"
  exit 1
fi


# Configure file path if it doesn't already exist
echo -n "Creating and setting permission on directory '$FILEPATH'  "
mkdir -p "$FILEPATH"
chown -R $REALUSER:$REALUSER "$FILEPATH"
if [ "$?" -ne "0" ];
then
  echo ""
  echo 1>&2 "Unable to set permission on service file path: '$FILEPATH'... "
  exit 1
else
  echo "Done"
fi


# Generate the service file
echo -n "Creating service file '$FILEPATH/$FILENAME'... "
cat << EOF > "$FILEPATH/$FILENAME"
[Unit]
Description=Manage Charlotte temperature reporting daemon

[Service]
User=pi
Type=oneshot
ExecStart=/usr/bin/env bash -c 'cd $DIR/..; \$PWD/bin/temp_daemon.py start'
ExecStop=/usr/bin/env bash -c 'cd $DIR/..; \$PWD/bin/temp_daemon.py stop'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

if [ "$?" -ne "0" ];
then
  echo ""
  echo 1>&2 "Failed to create service script: '$FILEPATH/$FILENAME'"
  exit 1
else
  echo "Done"
fi


# Set ownership
echo -n "Change ownership of service script: '$FILEPATH/$FILENAME'... "
chown $REALUSER:$REALUSER "$FILEPATH/$FILENAME"
if [ "$?" -ne "0" ];
then
  echo ""
  echo 1>&2 "Unable to set permission on service file: '$FILEPATH/$FILENAME'"
  exit 1
else
  echo "Done"
fi


# Link
echo -n "Copy service script... "
cp "$FILEPATH/$FILENAME" /lib/systemd/system/
if [ "$?" -ne "0" ];
then
  echo 1>&2 "Failed to copy file"
  exit 1
else
  echo "Done"
fi


# Enable the service
echo "Enable the new service... "
systemctl daemon-reload
systemctl enable charlotte.service
if [ "$?" -ne "0" ];
then
  echo ""
  echo 1>&2 "Failed to enable Charlotte service in Systemd"
  exit 1
else
  echo "Done"
fi


# Start the service
echo -n "Start the service... "
service charlotte start
if [ "$?" -ne "0" ];
then
  echo ""
  echo 1>&2 "Failed to start Charlotte service via Systemd"
  exit 1
else
  echo "Started"
fi
