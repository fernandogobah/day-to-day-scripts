#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to update linux servers alike debian

echo "-------------------------------"
echo " Current Version Info Follows: "
echo "-------------------------------"
lsb_release -i
lsb_release -r
lsb_release -d
lsb_release -c
printf "Kernal Version: ";uname -r
printf "Processor Type: ";uname -m
echo "------------------------------"
echo "     Performing updates:      "
echo "------------------------------"
echo "----- CLEAN -----"
apt-get clean
echo "----- UPDATE -----"
apt-get update
echo "----- UPGRADE -----"
apt-get upgrade -y
echo "----- DIST-UPGRADE -----"
apt-get dist-upgrade -y
echo "----- AUTOREMOVE -----"
apt-get autoremove -y
echo "------------------------------"
echo " Device Version Info Follows: "
echo "------------------------------"
lsb_release -i
lsb_release -r
lsb_release -d
lsb_release -c
printf "Kernal Version: ";uname -r
printf "Processor Type: ";uname -m
echo "------------------------------"
