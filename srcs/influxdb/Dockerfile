FROM	alpine:3.12.0

LABEL	maintainer="tjung@student.42seoul.kr"

RUN		apk update \
		&& apk --update --no-cache add \
		influxdb

RUN			mkdir -p /var/lib/influxdb

EXPOSE	8086

ENTRYPOINT	[ "/usr/sbin/influxd" ]
