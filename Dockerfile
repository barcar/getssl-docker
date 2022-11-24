FROM debian:stable-slim

WORKDIR /opt/runzero

RUN set -ex

RUN apt update && \
    apt install -y git openssl curl && \
    addgroup letsencrypt && \
    adduser letsencrypt letsencrypt && \
    mkdir /etc/letsencrypt && \
    chown letsencrypt:letsencrypt /etc/letsencrypt && \
    chmod 770 /etc/letsencrypt && \
    chmod g+s /etc/letsencrypt && \
    mkdir /etc/letsencrypt/certs && \
    mkdir /etc/letsencrypt/private
    
USER letsencrypt

RUN git clone https://github.com/srvrco/getssl.git && \
	  curl https://raw.githubusercontent.com/dominictarr/JSON.sh/master/JSON.sh > "/home/letsencrypt/getssl/dns_scripts/JSON.sh" && \
    chmod 700 "/home/letsencrypt/getssl/dns_scripts/JSON.sh"

CMD tail -f /dev/null

