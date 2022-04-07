#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to install Baculum in Linux system. alike Debian

wget -qO - https://www.bacula.org/downloads/baculum/baculum.pub | apt-key add -

echo "
deb http://www.bacula.org/downloads/baculum/stable-11/debian buster main
deb-src http://www.bacula.org/downloads/baculum/stable-11/debian buster main
" > /etc/apt/sources.list.d/baculum.list

apt-get update && apt-get install baculum-common baculum-api baculum-api-apache2 baculum-common baculum-web baculum-web-apache2 -y

echo "Defaults:www-data !requiretty
www-data ALL = (root) NOPASSWD: /usr/sbin/mtx
www-data ALL = (root) NOPASSWD: /opt/bacula/bin/bdirjson
www-data ALL = (root) NOPASSWD: /opt/bacula/bin/bsdjson
www-data ALL = (root) NOPASSWD: /opt/bacula/bin/bfdjson
www-data ALL = (root) NOPASSWD: /opt/bacula/bin/bconsole
www-data ALL = (root) NOPASSWD: /opt/bacula/bin/bbconsjson
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl start bacula-dir
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl stop bacula-dir
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl restart bacula-dir
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl start bacula-sd
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl stop bacula-sd
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl restart bacula-sd
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl start bacula-fd
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl stop bacula-fd
www-data ALL=(root) NOPASSWD: /usr/bin/systemctl restart bacula-fd
" > /etc/sudoers.d/baculum

a2enmod rewrite ssl
a2ensite baculum-api baculum-web

openssl req -x509 -out /etc/baculum/baculum.crt -keyout /etc/baculum/baculum.pem \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=localhost' -extensions EXT -config <( \
   printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
ln -s /etc/baculum/baculum.crt /etc/baculum/Config-api-apache/baculum.crt
ln -s /etc/baculum/baculum.pem /etc/baculum/Config-api-apache/baculum.pem
ln -s /etc/baculum/baculum.crt /etc/baculum/Config-web-apache/baculum.crt
ln -s /etc/baculum/baculum.pem /etc/baculum/Config-web-apache/baculum.pem


firewall-cmd --permanent --add-port=9095-9096/tcp
firewall-cmd --reload

service apache2 restart

service postgresql restart
