#!/bin/bash
# Update the machine
apt-get update

# Make sure upgrades and other installs run unattended (i.e. do not prompt)
export DEBIAN_FRONTEND=noninteractive
apt-get -y upgrade

# Add a new repository for apt-get for GitLab Runner
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash

# Add a new repository for apt-get for Docker
apt-get -y install software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update the machine again
apt-get update

# Install GitLab runner
apt-get -y install gitlab-runner

# Install dependencies for Docker
apt-get -y install apt-transport-https 
apt-get -y install ca-certificates 
apt-get -y install curl 
apt-get -y install software-properties-common

# Install Docker
apt-get -y install docker-ce

# Enable unattended upgrades (for security)
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

# Reboot the machine to ensure updates and upgrades are applied
reboot
