FROM	alpine:3.12.0

LABEL	maintainer="tjung@student.42seoul.kr"

RUN		apk update \
		&& apk --update --no-cache add \
		mysql \
		mysql-client

COPY	./srcs/mysql_init.sh ./
RUN		chmod +x ./mysql_init.sh
COPY	./srcs/init_mysql.sql ./
COPY	./srcs/mariadb-server.cnf ./
COPY	./srcs/create_tables.sql ./
COPY	./srcs/pma.sql ./
COPY	./srcs/wordpress.sql ./
RUN		chmod 644 ./mariadb-server.cnf

EXPOSE	3306

ENTRYPOINT	["/bin/sh", "mysql_init.sh"]
