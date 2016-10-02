#!/usr/bin/env bash
# Generate and install the SystemD service


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
FILEPATH="../etc/$SERVICE"


# Configure file path if it doesn't already exist
mkdir -p "$FILEPATH"
chown -R $REALUSER:$REALUSER "$FILEPATH"
if [ "$?" -ne "0" ];
then
  echo 1>&2 "Unable to set permission on service file path: '$FILEPATH'"
  exit 1
fi


# Generate the service file
cat << EOF > "$FILEPATH/$FILENAME"
[Unit]
Description=Manage Charlotte reporting daemon

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash -c 'cd $PWD/..; \$PWD/bin/service-all.sh start'
ExecStop=/usr/bin/env bash -c 'cd $PWD/..; \$PWD/bin/service-all.sh stop'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

if [ "$?" -ne "0" ];
then
  echo 1>&2 "Failed to create service script: '$FILEPATH/$FILENAME'"
  exit 1
fi


# Set ownership
chown $REALUSER:$REALUSER "$FILEPATH/$FILENAME"
if [ "$?" -ne "0" ];
then
  echo 1>&2 "Unable to set permission on service file: '$FILEPATH/$FILENAME'"
  exit 1
fi


# Link
ln -s "$FILEPATH/$FILENAME" "/etc/systemd/system/$FILENAME"
if [ "$?" -ne "0" ];
then
  echo 1>&2 "Failed to create symlink for service file in: '/etc/systemd/system/$FILENAME'"
  exit 1
fi


# Enable the service
systemctl enable charlotte.service
if [ "$?" -ne "0" ];
then
  echo 1>&2 "Failed to enable Charlotte service in Systemd"
  exit 1
fi


# Start the service
service charlotte start
if [ "$?" -ne "0" ];
then
  echo 1>&2 "Failed to start Charlotte service via Systemd"
  exit 1
fi
