FROM ubuntu:15.04

MAINTAINER Luis Héctor Chavez <lhchavez@omegaup.com>

RUN apt-get -y update && apt-get -y install software-properties-common
RUN add-apt-repository ppa:omegaup/omegaup
RUN locale-gen --purge en_US.UTF-8
RUN apt-get -y update && apt-get -y install omegaup-minijail

ADD https://github.com/omegaup/omegaup/raw/master/bin/runner.jar /runner.jar

RUN mkdir -p /etc/omegaup/runner
ADD omegaup.conf /etc/omegaup/runner/omegaup.conf
ADD runner.jks /etc/omegaup/runner/keystore.jks

RUN mkdir -p /var/log/omegaup
RUN mkdir -p /var/lib/omegaup/{compile,input}

EXPOSE 21681
VOLUME ["/var/log/omegaup"]
CMD ["/usr/bin/java", "-jar", "/runner.jar", "--config", "/etc/omegaup/runner/omegaup.conf", "--output", "/var/log/omegaup/runner.log"]
