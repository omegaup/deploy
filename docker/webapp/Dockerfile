
FROM ubuntu:15.04

MAINTAINER Alan Gonzalez <alanboy@alanboy.net>

# Install basic stuff
RUN apt-get install -qq -y vim
RUN apt-get install -qq -y curl
RUN apt-get update -qq -y
RUN apt-get install -qq -y nginx mysql-client git phpunit phpunit-selenium php5-fpm g++ fp-compiler unzip openssh-client make zip libcap-dev libgfortran3 ghc libelf-dev 
RUN apt-get install -qq -y wget
RUN apt-get install -qq -y software-properties-common

# This is a requirement of docker, not omegaup
RUN apt-get -y install supervisor

# Install hhvm
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
RUN add-apt-repository 'deb http://dl.hhvm.com/ubuntu vivid main'
RUN apt-get update
RUN apt-get install -qq -y hhvm

RUN apt-get install -qq -y sudo

# Install OmegaUp
RUN mkdir /opt/omegaup
RUN git clone https://github.com/omegaup/omegaup.git /opt/omegaup

ENV OMEGAUP_ROOT /opt/omegaup
ENV WWW_ROOT /var/www/omegaup.com
ENV USER `whoami`
ENV KEYSTORE_PASSWORD omegaup
ENV MYSQL_DB_NAME omegaup
ENV MYSQL_JAR ~/.ivy2/cache/mysql/mysql-connector-java/jars/mysql-connector-java-5.1.29.jar
ENV HOSTNAME localhost
ENV MINIJAIL_ROOT /var/lib/minijail

RUN ln -s $OMEGAUP_ROOT/frontend/www $WWW_ROOT
WORKDIR /opt/omegaup/

RUN stuff/install-githooks.sh
RUN git submodule update --init

RUN  mkdir -p `dirname $WWW_ROOT`
RUN  ln -s $OMEGAUP_ROOT/frontend/www $WWW_ROOT
RUN  mkdir $WWW_ROOT/img
RUN  chown www-data.www-data $WWW_ROOT/img
RUN  mkdir $WWW_ROOT/templates
RUN  chown www-data.www-data $WWW_ROOT/templates

# Setup nginx
ADD setupnginx.sh /opt/setupnginx.sh
RUN chmod +x /opt/setupnginx.sh
RUN /opt/setupnginx.sh

RUN update-rc.d -f php5-fpm remove
RUN update-rc.d hhvm defaults

# supervisord config file
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Install config.php
WORKDIR $OMEGAUP_ROOT/frontend/server/


# See http://github.com/docker/docker/pull/9176 
ENV MYSQL_ROOT_PASSWORD my-secret-pw

RUN echo "<?php" > config.php
RUN echo "define('OMEGAUP_DB_USER', 'root');" >> config.php
RUN echo "define('OMEGAUP_DB_PASS', '$MYSQL_ROOT_PASSWORD');" >> config.php
RUN echo "define('OMEGAUP_DB_NAME', '$MYSQL_DB_NAME');" >> config.php
RUN echo "define('OMEGAUP_DB_HOST', 'db');" >> config.php

# Set up the log.
RUN mkdir -p /var/log/omegaup/
RUN touch /var/log/omegaup/omegaup.log
RUN chown www-data.www-data /var/log/omegaup/omegaup.log

ADD init_db.sh /opt/init_db.sh
RUN chmod +x /opt/init_db.sh

CMD ["/usr/bin/supervisord"]
#
