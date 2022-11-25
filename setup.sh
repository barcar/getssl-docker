#!/bin/bash
echo "Starting getssl  setup..."

HOMEDIR=/home/letsencrypt/getssl
WORKDIR=/etc/letsencrypt/getssl
CFGFILE=$WORKDIR/getssl.cfg
DOMAINFILE=$WORKDIR/$DOMAIN/getssl.cfg

env

test -f $CFGFILE && export GLOBAL_CFG=TRUE || export GLOBAL_CFG=FALSE
echo "$(tput setaf 3)Global configuration: $GLOBAL_CFG$(tput setaf 7)"

test -f $DOMAINFILE && export DOMAIN_CFG=TRUE || export DOMAIN_CFG=FALSE
echo "$(tput setaf 3)Domain configuration: $DOMAIN_CFG$(tput setaf 7)"

if [ "$DOMAIN_CFG" = "FALSE" ]; then
    echo "$(tput setaf 3)$DOMAINFILE does not exist.$(tput setaf 6)"
    ./getssl/getssl -c "$DOMAIN" -w "$WORKDIR"
fi

if [ "$GLOBAL_CFG" = "FALSE" ]; then

    echo "$(tput setaf 3)Editing global configuration file$(tput setaf 7)"

    # edit global config file
    sed -i 's/#VALIDATE_VIA_DNS="true"/VALIDATE_VIA_DNS="true"/' $CFGFILE
    sed -i "s~#DNS_DEL_COMMAND=~DNS_DEL_COMMAND=\"$HOMEDIR/dns_scripts/dns_del_godaddy\"~" $CFGFILE
    sed -i "s~#DNS_ADD_COMMAND=~DNS_ADD_COMMAND=\"$HOMEDIR/dns_scripts/dns_add_godaddy\"~" $CFGFILE
    sed -i 's~RENEW_ALLOW="30"~RENEW_ALLOW="60"~' $CFGFILE
    sed -i 's~#REUSE_PRIVATE_KEY="true"~REUSE_PRIVATE_KEY="true"~' $CFGFILE
    sed -i "s/#ACCOUNT_EMAIL=\"me@example.com\"/ACCOUNT_EMAIL=\"$EMAIL\"/" $CFGFILE

    # add variables to global config file
    echo "export GODADDY_JSON=\"$HOMEDIR/dns_scripts/JSON.sh\"" >> $CFGFILE
    echo "export GODADDY_KEY=\"$GODADDY_KEY\"" >> $CFGFILE
    echo "export GODADDY_SECRET=\"$GODADDY_SECRET\"" >> $CFGFILE
    echo "export GODADDY_BASE=\"$DOMAIN\"" >>  $CFGFILE
    echo 'export GODADDY_TRACE="Y"' >>  $CFGFILE
    echo "export GODADDY_SCRIPT=\"$HOMEDIR/dns_scripts/dns_godaddy\"" >>  $CFGFILE

fi

if [ "$DOMAIN_CFG" = "FALSE" ]; then

    echo "$(tput setaf 3)Editing domain configuration file$(tput setaf 7)"

    # edit domain config file
    sed -i 's/#PRIVATE_KEY_ALG="rsa"/#PRIVATE_KEY_ALG="rsa" DOMAIN_KEY_LENGTH=2048/' $DOMAINFILE
    sed -i "s/SANS=\"www.$DOMAIN\"/SANS=\"$SANS\"/" $DOMAINFILE

    # get certificates
    echo "$(tput setaf 3)Getting certificates from staging$(tput setaf 6)"
    ./getssl/getssl -w "$WORKDIR" "$DOMAIN"

fi

test -f "$WORKDIR/$DOMAIN/$DOMAIN.crt" && export STAGING_OK=TRUE || export STAGING_OK=FALSE

if [ "$STAGING_OK" = "TRUE" ]; then

    echo "$(tput setaf 3)Editing domain configuration file$(tput setaf 7)"

    sed -i "s~#DOMAIN_PEM_LOCATION=\"\"~DOMAIN_PEM_LOCATION=\"/etc/letsencrypt/private/$DOMAIN\"~" $DOMAINFILE
    sed -i "s~#DOMAIN_KEY_LOCATION=\"/etc/ssl/$DOMAIN.key\"~DOMAIN_KEY_LOCATION=\"/etc/letsencrypt/private/$DOMAIN.key\"~" $DOMAINFILE
    sed -i "s~#DOMAIN_CERT_LOCATION=\"/etc/ssl/$DOMAIN.crt\"~DOMAIN_CERT_LOCATION=\"/etc/letsencrypt/certs/$DOMAIN.crt\"~" $DOMAINFILE

    sed -i 's~#CA="https://acme-v02.api.letsencrypt.org"~##CA="https://acme-v02.api.letsencrypt.org"~' $DOMAINFILE

    # get certificates
    echo "$(tput setaf 3)Getting certificates from production$(tput setaf 6)"
    ./getssl/getssl -f -w "$WORKDIR" "$DOMAIN"

fi

echo "$(tput setaf 3)Done.$(tput setaf 7)"
