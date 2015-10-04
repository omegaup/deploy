FROM ubuntu:15.04

MAINTAINER Luis Héctor Chavez <lhchavez@omegaup.com>

# Update APT & install all needed packages
RUN apt-get -y update && apt-get -y install puppet software-properties-common git

# Install Puppet and its dependencies
ADD docker.pp /etc/puppet/manifests/
RUN mkdir -p /tmp
ADD puppet-modules.sh /tmp/
RUN /bin/bash /tmp/puppet-modules.sh

# Install the certificates
RUN mkdir -p /etc/omegaup/grader
ADD grader.jks /etc/omegaup/grader/keystore.jks

# See http://github.com/docker/docker/pull/9176 
ENV FACTER_mysql_password my-secret-pw
ENV FACTER_user root
RUN puppet apply /etc/puppet/manifests/docker.pp --verbose --detailed-exitcodes || [ $? -eq 2 ]

ADD https://github.com/omegaup/omegaup/raw/master/bin/grader.jar /grader.jar

# Finally run supervisord to reach a steady state.
EXPOSE 21680
VOLUME ["/var/log/omegaup", "/var/lib/omegaup"]
CMD ["/usr/bin/java", "-cp", "/usr/share/java/mysql.jar:/grader.jar", "com.omegaup.Service", "--config", "/etc/omegaup/grader/omegaup.conf", "--output", "/var/log/omegaup/service.log"]
