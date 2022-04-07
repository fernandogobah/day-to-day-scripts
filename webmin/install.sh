#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Install Webmin in the linux system. Alike Debian

echo "deb https://download.webmin.com/download/repository sarge contrib" | tee /etc/apt/sources.list.d/webmin.list && wget -O- http://www.webmin.com/jcameron-key.asc | apt-key add - && apt-get install apt-transport-https && apt update && apt -y install webmin