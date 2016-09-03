#!/bin/bash -e

sudo apt-get install -y -q puppet-common git
sudo gem install r10k
sudo r10k puppetfile install
sudo FACTER_user=`whoami` puppet apply puppet/manifests/windows.pp
