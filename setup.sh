#!/bin/bash
echo "Starting getssl  setup..."

export MY_HOMEDIR=/home/letsencrypt/getssl
export MY_WORKDIR=/etc/letsencrypt/getssl
export MY_CONFIG_FILE=$MY_WORKDIR/getssl.cfg
export MY_DOMAIN_FILE=$MY_WORKDIR/$MY_DOMAIN/getssl.cfg

env

test -f $MY_CONFIG_FILE && export GLOBAL_CFG=TRUE || export GLOBAL_CFG=FALSE
echo "$(tput setaf 3)Global configuration: $GLOBAL_CFG$(tput setaf 7)"

test -f $MY_DOMAIN_FILE && export DOMAIN_CFG=TRUE || export DOMAIN_CFG=FALSE
echo "$(tput setaf 3)Domain configuration: $DOMAIN_CFG$(tput setaf 7)"

if [ "$DOMAIN_CFG" = "FALSE" ]; then
    echo "$(tput setaf 3)$MY_DOMAIN_FILE does not exist.$(tput setaf 6)"
    ./getssl/getssl -c "$MY_DOMAIN" -w "$MY_WORKDIR"
fi

if [ "$GLOBAL_CFG" = "FALSE" ]; then

    echo "$(tput setaf 3)Editing global configuration file$(tput setaf 7)"

    # edit global config file
    sed -i 's/#VALIDATE_VIA_DNS="true"/VALIDATE_VIA_DNS="true"/' $MY_CONFIG_FILE
    sed -i "s~#DNS_DEL_COMMAND=~DNS_DEL_COMMAND=\"$MY_HOMEDIR/dns_scripts/dns_del_godaddy\"~" $MY_CONFIG_FILE
    sed -i "s~#DNS_ADD_COMMAND=~DNS_ADD_COMMAND=\"$MY_HOMEDIR/dns_scripts/dns_add_godaddy\"~" $MY_CONFIG_FILE
    sed -i 's~RENEW_ALLOW="30"~RENEW_ALLOW="60"~' $MY_CONFIG_FILE
    sed -i 's~#REUSE_PRIVATE_KEY="true"~REUSE_PRIVATE_KEY="true"~' $MY_CONFIG_FILE
    sed -i "s/#ACCOUNT_EMAIL=\"me@example.com\"/ACCOUNT_EMAIL=\"$MY_EMAIL\"/" $MY_CONFIG_FILE

    # add variables to global config file
    echo "export GODADDY_JSON=\"$MY_HOMEDIR/dns_scripts/JSON.sh\"" >> $MY_CONFIG_FILE
    echo "export GODADDY_KEY=\"$MY_GODADDY_KEY\"" >> $MY_CONFIG_FILE
    echo "export GODADDY_SECRET=\"$MY_GODADDY_SECRET\"" >> $MY_CONFIG_FILE
    echo "export GODADDY_BASE=\"$MY_DOMAIN\"" >>  $MY_CONFIG_FILE
    echo 'export GODADDY_TRACE="Y"' >> $MY_CONFIG_FILE
    echo "export GODADDY_SCRIPT=\"$MY_HOMEDIR/dns_scripts/dns_godaddy\"" >>  $MY_CONFIG_FILE

fi

if [ "$DOMAIN_CFG" = "FALSE" ]; then

    echo "$(tput setaf 3)Editing domain configuration file$(tput setaf 7)"

    # edit domain config file
    sed -i 's/#PRIVATE_KEY_ALG="rsa"/#PRIVATE_KEY_ALG="rsa" DOMAIN_KEY_LENGTH=2048/' $MY_DOMAIN_FILE
    sed -i "s/SANS=\"www.$MY_DOMAIN\"/SANS=\"$MY_SANS\"/" $MY_DOMAIN_FILE

    # get certificates
    echo "$(tput setaf 3)Getting certificates from staging$(tput setaf 6)"
    ./getssl/getssl -w "$MY_WORKDIR" "$MY_DOMAIN"

fi

test -f "$MY_WORKDIR/$MY_DOMAIN/$MY_DOMAIN.crt" && export STAGING_OK=TRUE || export STAGING_OK=FALSE

if [ "$STAGING_OK" = "TRUE" ]; then

    echo "$(tput setaf 3)Editing domain configuration file$(tput setaf 7)"

    sed -i "s~#DOMAIN_PEM_LOCATION=\"\"~DOMAIN_PEM_LOCATION=\"/etc/letsencrypt/private/$MY_DOMAIN\"~" $MY_DOMAIN_FILE
    sed -i "s~#DOMAIN_KEY_LOCATION=\"/etc/ssl/$MY_DOMAIN.key\"~DOMAIN_KEY_LOCATION=\"/etc/letsencrypt/private/$MY_DOMAIN.key\"~" $MY_DOMAIN_FILE
    sed -i "s~#DOMAIN_CERT_LOCATION=\"/etc/ssl/$MY_DOMAIN.crt\"~DOMAIN_CERT_LOCATION=\"/etc/letsencrypt/certs/$MY_DOMAIN.crt\"~" $MY_DOMAIN_FILE

    sed -i 's~#CA="https://acme-v02.api.letsencrypt.org"~CA="https://acme-v02.api.letsencrypt.org"~' $MY_DOMAIN_FILE

    # get certificates
    echo "$(tput setaf 3)Getting certificates from production$(tput setaf 6)"
    ./getssl/getssl -f -w "$MY_WORKDIR" "$MY_DOMAIN"
    
    mkdir $MY_WORKDIR/../log

fi

echo "$(tput setaf 3)Done.$(tput setaf 7)"
