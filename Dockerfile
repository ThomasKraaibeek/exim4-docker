FROM debian:buster-slim

RUN set -eux; \
	apt-get update; \
	apt-get install -y \
		exim4-daemon-light \
		tini \
	; \
	rm -rf /var/lib/apt/lists/*; \
	ln -svfT /etc/hostname /etc/mailname

# https://blog.dhampir.no/content/exim4-line-length-in-debian-stretch-mail-delivery-failed-returning-message-to-sender
# https://serverfault.com/a/881197
# https://bugs.debian.org/828801

VOLUME [ "/opt/ssl" ]

#Trying to get SMTPS to work
RUN echo "IGNORE_SMTP_LINE_LENGTH_LIMIT='true'" >> /etc/exim4/exim4.conf.localmacros
RUN echo "REMOTE_SMTP_SMARTHOST_HOSTS_REQUIRE_TLS = *">> /etc/exim4/exim4.conf.localmacros
RUN echo "REQUIRE_PROTOCOL = smtps">> /etc/exim4/exim4.conf.localmacros
RUN echo "MAIN_HARDCODE_PRIMARY_HOSTNAME = localhost" >> /etc/exim4/exim4.conf.localmacros
#TLS
RUN echo "MAIN_TLS_ENABLE = 1">> /etc/exim4/exim4.conf.localmacros
RUN echo "MAIN_TLS_CERTIFICATE=/opt/ssl/localhost.crt" >> /etc/exim4/exim4.conf.localmacros
RUN echo "MAIN_TLS_PRIVATEKEY=/opt/ssl/localhost.key" >> /etc/exim4/exim4.conf.localmacros
RUN echo "daemon_smtp_ports = 25 : 465" >> etc/exim4/exim4.conf.localmacros
RUN echo "tls_on_connect_ports = 465" >> /etc/exim4/exim4.conf.localmacros

RUN echo "dc_other_hostnames='localhost'" >> /etc/exim4/update-exim4.conf.conf
RUN echo "dc_eximconfig_configtype='satellite'" >> /etc/exim4/update-exim4.conf.conf
RUN echo "dc_smarthost='localhost::465'" >> /etc/exim4/update-exim4.conf.conf

RUN echo "localhost:admin:pass" >> /etc/exim4/passwd.client



RUN set -eux; \
	mkdir -p /var/spool/exim4 /var/log/exim4; \
	chown -R Debian-exim:Debian-exim /var/spool/exim4 /var/log/exim4
VOLUME ["/var/spool/exim4", "/var/log/exim4"]

COPY set-exim4-update-conf docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 25 465 587 
CMD ["exim", "-bd", "-v"]
