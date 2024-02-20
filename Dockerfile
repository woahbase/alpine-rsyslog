# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
ENV S6_USER=rsyslog \
    S6_USERHOME=/var/lib/rsyslog
#
RUN set -xe \
    && apk add --no-cache --purge -uU \
        logrotate \
        rsyslog \
        # rsyslog-crypto \
        # rsyslog-http \
        rsyslog-tls \
        rsyslog-relp \
        rsyslog-mmjsonparse \
        rsyslog-mmutf8fix \
        tzdata \
    && mkdir -p /defaults \
    && mv /etc/rsyslog.conf /defaults/rsyslog.conf.default \
    && mv /etc/logrotate.d/rsyslog /defaults/rsyslog.logrotate.default \
    && mv /etc/logrotate.conf /defaults/logrotate.conf.default \
    && mv /etc/periodic/daily/logrotate /defaults/logrotate.cron.default \
    && adduser -h ${S6_USERHOME} -D -s /bin/false ${S6_USER} \
    && passwd -d -u ${S6_USER} \
    && rm -rf /var/cache/apk/* /tmp/*
#
COPY root/ /
#
VOLUME /var/log/ /var/spool/rsyslog
#
EXPOSE 514/tcp 514/udp 2514
#
ENTRYPOINT ["/init"]
