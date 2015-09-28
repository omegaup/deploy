FROM ubuntu:15.04

MAINTAINER Alan Gonzalez <alanboy@alanboy.net>

# Update APT & install all needed packages
RUN apt-get -y update && apt-get -y install puppet software-properties-common supervisor git

# Install Puppet and its dependencies
ADD docker.pp /etc/puppet/manifests/
RUN mkdir -p /tmp
ADD puppet-modules.sh /tmp/
RUN /bin/bash /tmp/puppet-modules.sh

# See http://github.com/docker/docker/pull/9176 
ENV FACTER_mysql_password my-secret-pw
ENV FACTER_user root
RUN puppet apply /etc/puppet/manifests/docker.pp --verbose --detailed-exitcodes || [ $? -eq 2 ]

# Install supervisord since Docker expects to run a single process
ADD supervisord.conf /etc/supervisor/conf.d/omegaup.conf

# Finally run supervisord to reach a steady state.
EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/omegaup.conf"]
