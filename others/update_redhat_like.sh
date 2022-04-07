#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to update linux servers alike RedHat

echo --------------------------
echo -       Cleaning         -
echo --------------------------
yum clean metadata
yum clean all

echo --------------------------
echo -  Checking for Updates  -
echo --------------------------
yum check-update

echo --------------------------
echo -        Updating        -
echo --------------------------
yum update -y

echo "System Updated - $(date +%d-%m-%Y-%H:%M)" >> /root/update.log
