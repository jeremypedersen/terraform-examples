#!/bin/bash
apt update

apt install -y \
  apache2 \
  php \
  libapache2-mod-php \
  php-mysql 

echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/server:/10/Ubuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/isv:ownCloud:server:10.list
curl -fsSL https://download.opensuse.org/repositories/isv:ownCloud:server:10/Ubuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/isv_ownCloud_server_10.gpg > /dev/null

apt update

apt install -y \
  apache2 \
  libapache2-mod-php \
  mariadb-server \
  openssl \
  php-imagick php-common php-curl \
  php-gd php-imap php-intl \
  php-json php-mbstring php-mysql \
  php-ssh2 php-xml php-zip \
  php-apcu php-redis redis-server \
  wget

apt install -y owncloud-complete-files

sed -i 's/\/var\/www\/html/\/var\/www\/owncloud/g' /etc/apache2/sites-enabled/000-default.conf
systemctl restart apache2

cd /var/www/
chown -R www-data. owncloud