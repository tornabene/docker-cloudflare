FROM ubuntu:trusty
MAINTAINER Tindaro Tornabene <tindaro.tornabene@gmail.com>

# Install packages
RUN apt-get update && \
 DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
 DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor pwgen && \
 apt-get -y install git apache2 libapache2-mod-php5 php5-mysql php5-pgsql php5-gd php-pear php-apc curl && \
 curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin && \
 mv /usr/local/bin/composer.phar /usr/local/bin/composer

# Enable apache rewrite module
RUN a2enmod rewrite

# Add image configuration and scripts
ADD start.sh /start.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf

# Configure /app folder
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html

# Install packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor pwgen && \
  apt-get -y install mysql-client && \
  apt-get -y install postgresql-client &&\
  apt-get install -y curl git



# install package building helpers
RUN apt-get -y --force-yes install dpkg-dev debhelper

# install dependancies
RUN apt-get -y build-dep pure-ftpd

# build from source
RUN mkdir /tmp/pure-ftpd/ && \
	cd /tmp/pure-ftpd/ && \
	apt-get source pure-ftpd && \
	cd pure-ftpd-* && \
	sed -i '/^optflags=/ s/$/ --without-capabilities/g' ./debian/rules && \
	dpkg-buildpackage -b -uc

# install the new deb files
RUN dpkg -i /tmp/pure-ftpd/pure-ftpd-common*.deb
RUN apt-get -y install openbsd-inetd
RUN dpkg -i /tmp/pure-ftpd/pure-ftpd_*.deb

# Prevent pure-ftpd upgrading
RUN apt-mark hold pure-ftpd pure-ftpd-common

# setup ftpgroup and ftpuser
RUN groupadd ftpgroup
RUN useradd -g ftpgroup -d /dev/null -s /etc ftpuser


WORKDIR /var/www
git clone --branch 7.x-1.x http://git.drupal.org/project/cloudflare.git

EXPOSE 80
EXPOSE 20 21

CMD ["/run.sh"]

