#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to start RDP session

until ps -e | grep remmina > /dev/null; do
	remmina -c $HOME/.local/share/remmina/1546894554775.remmina
	sleep 1
done
