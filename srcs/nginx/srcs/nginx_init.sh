#!/bin/sh

mkdir -p /run/nginx

#	ssl 설정
openssl req -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=KR/ST=Seoul/L=Seoul/O=42Seoul/OU=Jung/CN=localhost" -keyout localhost.dev.key -out localhost.dev.crt

#	ssl 인증서 이동
mv localhost.dev.crt etc/ssl/certs/
mv localhost.dev.key etc/ssl/private/
chmod 600 etc/ssl/certs/localhost.dev.crt etc/ssl/private/localhost.dev.key

# default.conf 이동
mv ./default.conf /etc/nginx/conf.d/

# ssh 설정
ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N ""
/usr/sbin/sshd
adduser -D tjung
echo "tjung:123!@#" | chpasswd

nginx -g 'daemon off;'
