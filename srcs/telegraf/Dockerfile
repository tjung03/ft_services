FROM	alpine:3.12.0

LABEL	maintainer="tjung@student.42seoul.kr"

RUN			apk update \
			&& apk --update --no-cache add \
			telegraf --repository=https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/

RUN			mkdir -p /etc/telegraf

ENTRYPOINT	["/usr/bin/telegraf"]
