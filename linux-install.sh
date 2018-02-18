#!/bin/bash

set -e

# Install dependencies.
install_packages () {
	local package_names=()

	while [[ $# -gt 1 ]]; do
		local package_name="$1"
		shift 1
		[ "`dpkg-query -W -f='${db:Status-Abbrev}' \"${package_name}\"`" == "ii " ] || package_names+=("${package_name}")
	done
	[[ ${#package_names[@]} -gt 0 ]] || return 0

	apt update --assume-yes --quiet
	apt install --assume-yes --quiet ${package_names[*]}
}

install_r10k () {
	[[ "`gem list -i r10k`" == "true" ]] && return 0

	gem install -q r10k
}

install_packages puppet-common ruby git
install_r10k
(cd /vagrant && r10k puppetfile install)

puppet apply --modulepath=/etc/puppet/modules /etc/puppet/modules/omegaup/manifests/vagrant.pp
