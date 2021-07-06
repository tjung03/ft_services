#!/bin/sh

# make user
mkdir -p /ftps/tjung
adduser --home=/ftps/tjung -D tjung
echo "tjung:123!@#" | chpasswd
echo "tjung" > /etc/vsftpd/vsftpd.userlist

touch /var/log/vsftpd.log

# ssl
openssl req -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=KR/ST=Seoul/L=Seoul/O=42Seoul/OU=Jung/CN=localhost" -keyout vsftpd.key -out vsftpd.crt
mv vsftpd.crt /etc/ssl/certs/
mv vsftpd.key /etc/ssl/private/
chmod 600 /etc/ssl/certs/vsftpd.crt /etc/ssl/private/vsftpd.key

# vsftpd.conf 이동
mv ./vsftpd.conf /etc/vsftpd/vsftpd.conf

# vsftpd foreground 실행
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
