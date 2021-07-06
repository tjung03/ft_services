FROM	alpine:3.12.0

LABEL	maintainer="tjung@student.42seoul.kr"

RUN		apk update \
			&& apk --update --no-cache add \
			nginx \
			openssl \
			openssh-server

COPY	./srcs/nginx_init.sh ./
RUN		chmod +x ./nginx_init.sh
COPY	./srcs/default.conf ./

#	index.html 이동
COPY	./srcs/index.html	/var/www/html/

EXPOSE	80 443 22

ENTRYPOINT	["/bin/sh", "nginx_init.sh"]
