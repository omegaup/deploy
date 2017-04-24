#!/bin/bash -e

# Install dependencies.
[ "`dpkg-query -W -f='${db:Status-Abbrev}' git puppet-common`" == "ii ii " ] || apt install -y -q git puppet-common
[ "`gem list -i r10k`" == "true" ] || gem install -q r10k
(cd /vagrant && r10k puppetfile install)

# Install everything using Puppet
if grep xenial /etc/lsb-release > /dev/null ; then
	username=ubuntu
else
	username=vagrant
fi
FACTER_user="${username}" FACTER_mysql_password=omegaup FACTER_keystore_password=omegaup puppet apply --modulepath=/etc/puppet/modules /etc/puppet/modules/omegaup/manifests/vagrant.pp
