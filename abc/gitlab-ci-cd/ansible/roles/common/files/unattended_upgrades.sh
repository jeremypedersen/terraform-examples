#!/bin/bash
# Enable unattended upgrades (for security)
# Make sure upgrades and other installs run unattended (i.e. do not prompt)
export DEBIAN_FRONTEND=noninteractive
apt-get -y install unattended-upgrades
echo unattended-upgrades/enable_auto_updates true boolean | debconf-set-selections
dpkg-reconfigure --priority=low  unattended-upgrades

# Configure auto upgrade settings
echo "APT::Periodic::Update-Package-Lists \"1\";" > /etc/apt/apt.conf.d/20auto-upgrades
echo "APT::Periodic::Unattended-Upgrade \"1\";" >> /etc/apt/apt.conf.d/20auto-upgrades
echo "APT::Periodic::Download-Upgradeable-Packages \"1\";" >> /etc/apt/apt.conf.d/20auto-upgrades
echo "APT::Periodic::AutocleanInterval \"7\";" >> /etc/apt/apt.conf.d/20auto-upgrades

# Run unattended upgrades once to ensure configuration is OK
# Note: manually check for issues in /var/log/unattended-upgrades
unattended-upgrade -d

# Create file in /root to indicate the script has completed 
# Ansible checks for this file: if it finds this file
# on a subsequent run, it will *not* re-run this script
touch /root/.ansible_unattended_upgrades_enabled
