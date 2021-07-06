#!/bin/sh

mkdir -p /run/mysqld

#	mysql 설정 파일 이동
mv ./mariadb-server.cnf /etc/my.cnf.d/

sleep 5

#	mysql 세팅
mysql_install_db --user=root

/usr/bin/mysqld --user=root &

mysql -u root --skip-password > /dev/null 2>&1
until [ $? -ne "1" ]
do
	sleep 2
	mysql -u root --skip-password > /dev/null 2>&1
done

mysql -u root --skip-password < /pma.sql
mysql -u root --skip-password < /create_tables.sql
mysql -u root --skip-password < /init_mysql.sql

sleep 5
mysql -u root --skip-password wordpress < /wordpress.sql > /dev/null 2>&1
echo "do"
until [ $? != 1 ]
do
	sleep 1
	mysql -u root --skip-password wordpress < /wordpress.sql > /dev/null 2>&1
done
echo "done"

/usr/bin/mysqladmin -u root --skip-password shutdown

mysqld --user=root
