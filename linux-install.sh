#!/bin/bash

set -e

CURRENT_DIR=/vagrant

if [ ! -d "${CURRENT_DIR}" ]; then
	CURRENT_DIR=$(dirname "$0")
fi

# Install dependencies.
install_packages () {
	local package_names=()

	while [[ $# -gt 1 ]]; do
		local package_name="$1"
		shift 1
		[ "`dpkg-query -W -f='${db:Status-Abbrev}' \"${package_name}\"`" == "ii " ] || package_names+=("${package_name}")
	done
	[[ ${#package_names[@]} -gt 0 ]] || return 0

	sudo apt update --assume-yes --quiet
	sudo apt install --assume-yes --quiet ${package_names[*]}
}

install_r10k () {
	[[ "`gem list -i r10k`" == "true" ]] && return 0

	sudo gem install -q r10k
}

install_hiera_yaml () {
	local hiera_yaml=/etc/puppet/hiera.yaml
	local vm_yaml=/etc/puppet/code/environments/production/hieradata/vm.yaml
	if [ ! -f "${hiera_yaml}" ]; then
		sudo mkdir -p "$(dirname "${hiera_yaml}")"
		sudo tee "${hiera_yaml}" > /dev/null <<EOF
---
:backends:
  - yaml
:yaml:
  :datadir: "/etc/puppet/code/environments/%{environment}/hieradata"
:hierarchy:
  - vm
EOF
	fi
	if [ ! -f "${vm_yaml}" ]; then
		sudo mkdir -p "$(dirname "${vm_yaml}")"
		sudo tee "${vm_yaml}" > /dev/null <<EOF
---
EOF
	fi
	if [ -n "${github_username}" ] && \
	   curl --silent --fail --head "https://api.github.com/repos/${github_username}/omegaup" > /dev/null; then
		sudo tee "${vm_yaml}" > /dev/null <<EOF
---
omegaup::github_remotes:
  origin: ${github_username}/omegaup
EOF
	fi
}

install_packages puppet-common ruby git
install_r10k
install_hiera_yaml
(cd "${CURRENT_DIR}" && sudo r10k puppetfile install)

sudo puppet apply --modulepath=/etc/puppet/modules /etc/puppet/modules/omegaup/manifests/vagrant.pp
