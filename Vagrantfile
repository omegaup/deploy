# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	config.vm.box = "omegaup-vivid"
	config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/vivid/current/vivid-server-cloudimg-amd64-vagrant-disk1.box"

	# Redirige localhost:8080 hacia el puerto 80 de la VM
	config.vm.network :forwarded_port, guest: 80, host: 8080
	# Expone el puerto del servicio del backend.
	config.vm.network :forwarded_port, guest: 21680, host: 21680

	# Permite usar las llaves SSH del host en la VM
	config.ssh.forward_agent = true
	config.ssh.forward_x11 = true

	config.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--memory", "1024", "--cpus", "1"]
	end

	config.vm.provision :shell do |shell|
		shell.inline = "
			if [ ! -d /vagrant/puppet/modules/concat ]; then
				puppet module install puppetlabs/concat --force --modulepath '/vagrant/puppet/modules'
			fi
			if [ ! -d /vagrant/puppet/modules/stdlib ]; then
				puppet module install puppetlabs/stdlib --force --modulepath '/vagrant/puppet/modules'
			fi
			if [ ! -d /vagrant/puppet/modules/mysql ]; then
				puppet module install puppetlabs/mysql --force --modulepath '/vagrant/puppet/modules'
			fi
			if [ ! -d /vagrant/puppet/modules/vcsrepo ]; then
				puppet module install puppetlabs/vcsrepo --force --modulepath '/vagrant/puppet/modules'
			fi
			if [ ! -d /vagrant/puppet/modules/apt ]; then
				puppet module install puppetlabs/apt --force --modulepath '/vagrant/puppet/modules'
			fi
			if [ ! -d /vagrant/puppet/modules/nginx ]; then
				puppet module install jfryman/nginx --force --modulepath '/vagrant/puppet/modules'
			fi"
	end

	# Instala todo usando Puppet
	config.vm.provision :puppet do |puppet|
		puppet.manifests_path = 'puppet/manifests'
		puppet.module_path = 'puppet/modules'
		puppet.manifest_file = 'omegaup.pp'
		puppet.facter = {
			'omegaup_root' => '/opt/omegaup',
			'mysql_password' => 'omegaup',
			'keystore_password' => 'omegaup',
		}
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
