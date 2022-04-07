#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to create multi accounts at once

LIST="create_multi_accounts.csv"
COSID="ENTER_COSID_DOMAIN"
PASSWD="Change@123"

while IFS=, read USER DOMAIN NAME;do

        echo create account ${USER}@${DOMAIN} ...
        echo -e "command: /opt/zimbra/bin/zmprov ca \"${USER}@${DOMAIN}\" \"${PASSWD}\" displayName \"${NAME}\" zimbraCOSid ${COSID}\n\n"

        /opt/zimbra/bin/zmprov ca ${USER}@${DOMAIN} ${PASSWD} displayName "${NAME}" zimbraCOSid ${COSID}

done < ${LIST}
