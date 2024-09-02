#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo apt-get install -y php 
sudo apt-get install -y libapache2-mod-php 
sudo apt-get install -y php-mysql
sudo bash -c 'curl https://download.owncloud.org/download/repositories/production/Ubuntu_18.04/Release.key | apt-key add -'
sudo bash -c 'echo "deb https://download.owncloud.org/download/repositories/production/Ubuntu_18.04/ /" > /etc/apt/sources.list.d/owncloud.list'
sudo apt-get update
sudo apt-get install -y php-bz2
sudo apt-get install -y php-curl 
sudo apt-get install -y php-gd 
sudo apt-get install -y php-imagick 
sudo apt-get install -y php-intl 
sudo apt-get install -y php-mbstring 
sudo apt-get install -y php-xml 
sudo apt-get install -y php-zip 
sudo apt-get install -y owncloud-files
sudo bash -c 'sed -i "s/\/var\/www\/html/\/var\/www\/owncloud/g" /etc/apache2/sites-enabled/000-default.conf'
sudo systemctl restart apache2