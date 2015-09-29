#/bin/bash

if [ ! -d /etc/puppet/modules ]; then
	mkdir -p /etc/puppet/modules
fi
if [ ! -d /etc/puppet/modules/concat ]; then
	puppet module install puppetlabs/concat --force
fi
if [ ! -d /etc/puppet/modules/stdlib ]; then
	puppet module install puppetlabs/stdlib --force
fi
if [ ! -d /etc/puppet/modules/mysql ]; then
	puppet module install puppetlabs/mysql --force
fi
if [ ! -d /etc/puppet/modules/vcsrepo ]; then
	puppet module install puppetlabs/vcsrepo --force
fi
if [ ! -d /etc/puppet/modules/apt ]; then
	puppet module install puppetlabs/apt --force
fi
if [ ! -d /etc/puppet/modules/nginx ]; then
	puppet module install jfryman/nginx --force
fi
if [ ! -d /etc/puppet/modules/nginx ]; then
	puppet module install jfryman/nginx --force
fi
if [ ! -d /etc/puppet/modules/omegaup ]; then
	git clone https://github.com/omegaup/puppet.git /etc/puppet/modules/omegaup
else
	(cd /etc/puppet/modules/omegaup && git pull --rebase)
fi
