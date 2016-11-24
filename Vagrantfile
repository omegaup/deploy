# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	config.vm.box = "omegaup-wily"
	config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/wily/current/wily-server-cloudimg-amd64-vagrant-disk1.box"

	# Redirige localhost:8080 hacia el puerto 80 de la VM
	config.vm.network :forwarded_port, guest: 80, host: 8080
	# Expone el puerto del servicio del backend.
	config.vm.network :forwarded_port, guest: 21680, host: 21680

	# Permite usar las llaves SSH del host en la VM
	config.ssh.forward_agent = true
	config.ssh.forward_x11 = true

	config.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "1"]
	end

	config.vm.provision :shell do |shell|
		shell.inline = "
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
				puppet module install puppet-nginx --force
			fi
			if [ ! -d /etc/puppet/modules/pear ]; then
				puppet module install rafaelfc/pear --force
			fi
			if [ ! -d /etc/puppet/modules/omegaup ]; then
				git clone https://github.com/omegaup/puppet.git /etc/puppet/modules/omegaup
			else
				(cd /etc/puppet/modules/omegaup && git pull)
			fi
			# Instala todo usando Puppet
			FACTER_mysql_password=omegaup FACTER_keystore_password=omegaup puppet apply /etc/puppet/modules/omegaup/manifests/vagrant.pp"
	end

	# Sincronizar un folder local con vagrant. Muy útil si quieres desarrollar usando un IDE.
	# INSTRUCCIONES:
	# * Ejecuta `vagrant up` normalemente.
	# * Ajusta "<path a tu omegaup local>"
	# * Cambia la propiedad 'disabled' a false
	# * Ejecuta `vagrant reload`
	# * Ejecuta `vagrant rsync` cada que hagas un cambio localmente para que se
	#   refleje en vagrant o `vagrant rsync-auto` para que se actualice
	#   automáticamente. 
	config.vm.synced_folder "<path a tu omegaup local>", "/opt/omegaup", type: "rsync",
		rsync__exclude: ".git/",
		rsync__args: "-rv",
		disabled: true
end
