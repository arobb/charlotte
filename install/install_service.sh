#!/usr/bin/env bash
# Generate and install the SystemD service
#
# Remove service with:
# systemctl disable charlotte.service
# rm /lib/systemd/system/charlotte.service


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


# Make sure we are running as root
if [ "$(whoami)" != "root" ];
then
  echo "$(basename $0) must be run as root"
  exit 1
fi


# Configure some values
REALUSER=$(who am i | awk '{print $1}')
SERVICE="systemd"
FILENAME="charlotte.service"
FILEPATH="$DIR/../etc/$SERVICE"


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
Description=Manage Charlotte reporting daemon

[Service]
User=pi
Type=oneshot
ExecStart=/usr/bin/env bash -c 'cd $DIR/..; \$PWD/bin/service-all.sh start'
ExecStop=/usr/bin/env bash -c 'cd $DIR/..; \$PWD/bin/service-all.sh stop'
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
echo -n "Enable the new service... "
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
