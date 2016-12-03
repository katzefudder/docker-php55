FROM katzefudder/docker-ubuntu-14.04

MAINTAINER Florian Dehn <flo@katzefudder.de>

LABEL Description="Frontend Server PHP 5.5" Vendor="katzefudder.de"

ENV TERM=xterm DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install apache2 php5 php5-cli \
libapache2-mod-php5 curl php5-mysql php5-gd php-pear php-apc php5-curl php5-intl php5-imap php5-ldap \
php5-mcrypt php5-xdebug php5-sqlite php5-apcu php5-mysql libssh2-1-dev libssh2-php exim4 \
php-pear graphviz mysql-client openssh-server ruby ruby-dev && \
apt-get clean && \
rm -Rf /var/lib/apt/lists/*

# * * * * * * * * * adjust php ENV var settings
RUN sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/" /etc/php5/cli/php.ini

COPY scripts/xdebug.ini /usr/local/etc/php/conf.d/

# * * * * * * * * * config php mods & xdebug settings
RUN php5enmod imap mcrypt
RUN echo "apc.enabled=0" >> /etc/php5/mods-available/apcu.ini

# * * * * * * * * * setup Apache
RUN chown www-data: /var/www -R && chmod -R 777 /var/www
ADD scripts/make_vhost.sh /tmp/
ADD scripts/vhost_template.txt /tmp/
RUN /tmp/make_vhost.sh docker-php55 /etc/apache2/sites-available/docker-php55.conf

RUN a2ensite docker-php55.conf && a2dissite 000-default && a2enmod rewrite ssl && mkdir -p /etc/apache2/ssl

# * * * * * * * * * add SSH public key


RUN mkdir /root/.ssh/ && chmod 700 /root/.ssh/
ADD keys/docker.pub /root/.ssh/docker.pub
RUN cat /root/.ssh/docker.pub >> /root/.ssh/authorized_keys && chmod 644 /root/.ssh/authorized_keys

# * * * * * * * * * generate SSL key
RUN openssl genrsa -out /etc/apache2/ssl/ssl.key 2048; \
	openssl req -new -x509 -key /etc/apache2/ssl/ssl.key -out /etc/apache2/ssl/ssl.crt -days 3650 -subj /CN=docker-php55

# * * * * * * * * * set server name
RUN echo "ServerName docker.local" >> /etc/apache2/apache2.conf

# * * * * * * * * * install composer && nodejs
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN apt-get install nodejs -y && npm install -g grunt-cli && npm install -g bower
RUN gem install compass

# * * * * * * * * * prepare directories
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd

# * * * * * * * * * startup
COPY scripts/startup.sh /tmp/startup.sh
CMD ["/tmp/startup.sh"]

WORKDIR /var/www

# * * * * * * * * * expose ports
EXPOSE 22 80 443