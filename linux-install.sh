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

	# We haven't set up date/time yet, so the package list may have a valid time that's yet to occur.
	sudo apt update --assume-yes --quiet -o Acquire::Check-Date=false
	sudo apt install --assume-yes --quiet -o Acquire::Check-Date=false ${package_names[*]} ntpdate
	# Now we can update the VM's time so that any future operations work well.
	sudo ntpdate pool.ntp.org
}

install_r10k () {
	[[ "`gem list -i r10k`" == "true" ]] && return 0

	sudo gem install -q r10k
}

install_hiera_yaml () {
	local hiera_yaml=/etc/puppet/hiera.yaml
	local vm_yaml=/etc/puppet/code/hiera/vm.yaml
	if [ ! -f "${hiera_yaml}" ]; then
		sudo mkdir -p "$(dirname "${hiera_yaml}")"
	fi
	sudo tee "${hiera_yaml}" > /dev/null <<EOF
---
version: 5

defaults:
  datadir: "/etc/puppet/code/hiera"
  data_hash: yaml_data

hierarchy:
  - name: "Vagrant VM"
    path: "vm.yaml"
EOF
	if [ ! -f "${vm_yaml}" ]; then
		sudo mkdir -p "$(dirname "${vm_yaml}")"
		sudo tee "${vm_yaml}" > /dev/null <<EOF
---
version: 5

php::globals::php_version: '7.4'
EOF
	fi
	if [ -n "${github_username}" ] && \
	   curl --silent --fail --head "https://api.github.com/repos/${github_username}/omegaup" > /dev/null; then
		sudo tee "${vm_yaml}" > /dev/null <<EOF
---
version: 5

php::globals::php_version: '7.4'

omegaup::github_remotes:
  origin: ${github_username}/omegaup
EOF
	fi
}

install_packages puppet ruby git virtualbox-guest-dkms virtualbox-guest-x11
install_r10k
install_hiera_yaml
sudo r10k puppetfile install --puppetfile="${CURRENT_DIR}/Puppetfile"

# Some dependent modules outside of our control use deprecated features.
sudo puppet apply --disable_warnings=deprecations /usr/share/puppet/modules/omegaup/manifests/vagrant.pp
