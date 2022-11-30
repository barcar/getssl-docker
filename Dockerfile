FROM debian:stable-slim

#WORKDIR /opt/runzero

RUN set -ex

RUN apt update && \
    apt install -y git openssl curl dnsutils cron rsyslog nano procps ssmtp && \
#    addgroup letsencrypt && \
#    useradd letsencrypt -g letsencrypt && \
    mkdir /etc/letsencrypt && \
#    chown letsencrypt:letsencrypt /etc/letsencrypt && \
    chmod 770 /etc/letsencrypt && \
    chmod g+s /etc/letsencrypt && \
    mkdir /etc/letsencrypt/certs && \
    mkdir /etc/letsencrypt/private && \
    mkdir /etc/letsencrypt/logs && \
    mkdir /home/letsencrypt
    
#USER letsencrypt
WORKDIR /home/letsencrypt

COPY setup.sh ./
COPY crontab ./
COPY cron.sh ./
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf

RUN id && \
    pwd && \
    ls -la && \
    git clone https://github.com/srvrco/getssl.git && \
    curl https://raw.githubusercontent.com/dominictarr/JSON.sh/master/JSON.sh > "./getssl/dns_scripts/JSON.sh" && \
    chmod 700 "./getssl/dns_scripts/JSON.sh" && \
    ls -la && \
    chmod +x ./*.sh && \
    crontab ./crontab && \
    crontab -l && \
    ls -la && \
    chown root.mail /etc/ssmtp/ssmtp.conf && \
    chmod 0640 /etc/ssmtp/ssmtp.conf

ENTRYPOINT ["cron", "-f"]
