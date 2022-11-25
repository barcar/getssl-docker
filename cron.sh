#!/bin/bash

echo "Starting renewal..."
date
pwd
id
env

/home/letsencrypt/getssl/getssl -a -U -w /etc/letsencrypt/getssl
