#!/bin/bash -e

# Install dependencies.
[ "`dpkg-query -W -f='${db:Status-Abbrev}' git puppet-common`" == "ii ii " ] || apt install -y -q git puppet-common
[ "`gem list -i r10k`" == "true" ] || gem install -q r10k
(cd /vagrant && r10k puppetfile install)

# Install everything using Puppet
FACTER_user=vagrant FACTER_mysql_password=omegaup FACTER_keystore_password=omegaup puppet apply --modulepath=/etc/puppet/modules /etc/puppet/modules/omegaup/manifests/vagrant.pp
