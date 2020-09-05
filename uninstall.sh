#!/bin/bash
# file: setup.sh

DISTRO=`awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }'`

# Welcome Message
echo 'Welcome to TunnelCat VPN Uninstall Script'

# Verify Distro
if ! [[ $DISTRO == "ubuntu" || $DISTRO == "debian" ]]; then
	echo 'This script works only on Debian/Ubuntu OS'
	exit 1
fi

# Check if root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if ! test -f "/root/.tcat_installed"; then
	echo 'TunnelCat VPN Software is not installed!'
	exit 1
fi

echo 'Uninstalling using APT'
DEBIAN_FRONTEND=noninteractive apt purge privoxy dns2tcp stunnel -y

# Uninstall software packages
echo 'Uninstalling TunnelCat VPN software'
systemctl stop ohpserver
rm /usr/local/bin/ohpserver
rm /etc/systemd/system/ohpserver.service
systemctl daemon-reload

# Removing Configurations
echo 'Removing configurations'
rm -rf /etc/dns2tcp/
rm -rf /etc/stunnel/
rm /root/.tcat_installed

echo 'Uninstall Complete'