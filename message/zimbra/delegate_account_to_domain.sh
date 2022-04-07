# !/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to revoke or grant permission admins accounts

WHO=`whoami`
if [ $WHO != "zimbra" ]
then
 echo
 echo "Execute this scipt as user zimbra (\"su - zimbra\")"
 echo
 exit 1
fi

echo
echo
echo "Zimbra Delegate Admin control"
echo "*************************************************"
echo "Utility to grant/revoke delegated administrators"
echo 

echo "Informe o domínio para o qual você deseja conceder ou revogar direitos."
read domain


echo "Você deseja garantir ou revogar as diretivas de acesso? Digite R para REVOGAR ou G para GARANTIR o acesso."
read -p "R ou G: " rg


if [ "$rg" == 'R' ]
then
   echo "Informe um endereço de email ex:(bgraaff@domain.com) para o qual você deseja revogar a delegação de direitos admin para o domínio $domain."
   read -p "username: " username

zmprov ma $username zimbraIsDelegatedAdminAccount FALSE


elif [ "$rg" == 'G' ]
then
   echo "Informe um endereço de email ex:(bgraaff@domain.com) para o qua você deseja gararntir a delegação de direitos admin para o domínio $domain."
   read -p "username: " username

zmprov ma $username +zimbraIsDelegatedAdminAccount TRUE
zmprov ma $username +zimbraAdminConsoleUIComponents accountListView
zmprov ma $username +zimbraAdminConsoleUIComponents aliasListView
zmprov ma $username +zimbraAdminConsoleUIComponents DLListView

#Rows not testing
#zmprov grr domain $domain usr $username domainAdminRights 
#zmprov grr domain $domain usr $username +adminConsoleDomainRights

zmprov grr domain $domain usr $username +listAccount
zmprov grr domain $domain usr $username set.account.zimbraAccountStatus
zmprov grr domain $domain usr $username set.account.sn
zmprov grr domain $domain usr $username set.account.displayName
zmprov grr domain $domain usr $username set.account.zimbraPasswordMustChange
zmprov grr domain $domain usr $username +getAccount
zmprov grr domain $domain usr $username +getAccountInfo
zmprov grr domain $domain usr $username +renameAccount
zmprov grr domain $domain usr $username +modifyAccount
zmprov grr domain $domain usr $username +setAccountPassword
zmprov grr domain $domain usr $username +createDistributionList
zmprov grr domain $domain usr $username +addDistributionListMember
zmprov grr domain $domain usr $username +getDistributionListMembership
zmprov grr domain $domain usr $username +getDistributionList
zmprov grr domain $domain usr $username +listDistributionList
zmprov grr domain $domain usr $username +modifyDistributionList
zmprov grr domain $domain usr $username +deleteDistributionList
zmprov grr domain $domain usr $username +renameDistributionList
zmprov grr domain $domain usr $username +removeDistributionListMember 

else
   echo "Invalid option, abort"
   exit 0
fi

exit 0
