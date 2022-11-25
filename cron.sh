#!/bin/bash

echo "Starting renewal..."
mkdir /etc/letsencrypt/log
date
pwd
id
env

/home/letsencrypt/getssl/getssl -a -U -w /etc/letsencrypt/getssl
