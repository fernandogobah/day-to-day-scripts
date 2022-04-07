#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to send message in telegram

sleep $[ ( $RANDOM % 600 ) + 1 ]s
to=My_Home_🏡_☀️
curl -s https://www.bibliaon.com/versiculo_do_dia/ | html2text -width 500 | grep -A3 "Hoje" > $HOME/msg_do_dia.txt     

(echo "contact_list" ; sleep 5 ; echo "send_text $to $HOME/msg_do_dia.txt" ; echo "safe_quit") | telegram-cli --enable-msg-id
