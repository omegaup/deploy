#!/bin/bash -e

# Install dependencies.
[ "`dpkg-query -W -f='${db:Status-Abbrev}' git puppet-common`" == "ii ii " ] || sudo apt install -y -q git puppet-common
[ "`gem list -i r10k`" == "true" ] || sudo gem install -q r10k
sudo r10k puppetfile install

# Install everything using Puppet
sudo FACTER_user=`whoami` -- puppet apply --modulepath=/etc/puppet/modules /etc/puppet/modules/omegaup/manifests/windows.pp
