FROM katzefudder/docker-ubuntu-14.04

MAINTAINER Florian Dehn <flo@katzefudder.de>

# define hostname
ENV HOSTNAME docker.local

LABEL Description="Frontend Server PHP 5.5" Vendor="katzefudder.de"

ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

# Tweaks to give Apache/PHP write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
	usermod -G staff www-data && \

RUN groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1)
RUN groupmod -g ${BOOT2DOCKER_GID} staff

RUN apt-get update && apt-get -y install apache2 ant php5 php5-cli \
libapache2-mod-php5 curl php5-mysql php5-gd php-pear php-apc php5-curl php5-intl php5-imap php5-ldap \
php5-mcrypt php5-xdebug php5-sqlite php5-apcu php5-mysql libssh2-1-dev libssh2-php exim4 \
php-pear graphviz mysql-client

# * * * * * * * * * adjust php ENV var settings
RUN sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/" /etc/php5/cli/php.ini

# * * * * * * * * * config php mods
RUN php5enmod imap mcrypt
RUN echo "apc.enabled=0" >> /etc/php5/mods-available/apcu.ini
RUN echo "xdebug.max_nesting_level = 400" >> /etc/php5/mods-available/xdebug.ini

# * * * * * * * * * setup Apache
RUN chown www-data: /var/www -R
RUN chmod -R 777 /var/www
ADD scripts/make_vhost.sh /tmp/
ADD scripts/vhost_template.txt /tmp/
RUN /tmp/make_vhost.sh ${HOSTNAME} /etc/apache2/sites-available/${HOSTNAME}.conf

RUN a2ensite ${HOSTNAME}.conf
RUN a2dissite 000-default
RUN a2enmod rewrite ssl
RUN mkdir -p /etc/apache2/ssl

# * * * * * * * * * generate SSL key
RUN openssl genrsa -out /etc/apache2/ssl/ssl.key 2048; openssl req -new -x509 -key /etc/apache2/ssl/ssl.key -out /etc/apache2/ssl/ssl.crt -days 3650 -subj /CN=${HOSTNAME}

RUN echo "ServerName ${HOSTNAME}" >> /etc/apache2/apache2.conf

# * * * * * * * * * install composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# * * * * * * * * * install Node.js
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install nodejs -y

# * * * * * * * * * install Grunt
RUN npm install -g grunt-cli

# * * * * * * * * * Root password set to a12sdf
RUN echo 'root:a12sdf' | chpasswd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# * * * * * * * * * start supervisor and manage ssh and apache2
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor
COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# * * * * * * * * * run Supervisor
CMD ["/usr/bin/supervisord"]

# * * * * * * * * * expose ports
EXPOSE 22 80 443