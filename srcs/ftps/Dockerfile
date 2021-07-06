FROM	alpine:3.12.0

LABEL	maintainer="tjung@student.42seoul.kr"

RUN		apk update \
		&& apk --update --no-cache add \
		vsftpd \
		openssl

COPY	./srcs/ftps_init.sh ./
RUN		chmod +x ./ftps_init.sh
COPY	./srcs/vsftpd.conf ./

EXPOSE	20 21 20001 20002

ENTRYPOINT	["/bin/sh", "ftps_init.sh"]
