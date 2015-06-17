# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	config.vm.box = "omegaup-utopic"
	config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/utopic/current/utopic-server-cloudimg-amd64-vagrant-disk1.box"

	# Redirige localhost:8080 hacia el puerto 80 de la VM
	config.vm.network :forwarded_port, guest: 80, host: 8080
	# Expone el puerto del servicio del backend.
	config.vm.network :forwarded_port, guest: 21680, host: 21680

	# Permite usar las llaves SSH del host en la VM
	config.ssh.forward_agent = true
	config.ssh.forward_x11 = true

	config.vm.provider "virtualbox" do |vb|
		# Compilar grader y runner necesita al menos 2GB de memoria
		vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "1"]
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
				puppet module install puppetlabs/apt --force --modulepath '/vagrant/puppet/modules' --version 1.6.0
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
			'minijail_root' => '/var/lib/minijail',
			'mysql_password' => 'omegaup',
			'keystore_password' => 'omegaup',
		}
	end

	# Sincronizar un folder local con vagrant. Muy útil si no quieres developear adentro de la VM de Vagrant
	# INSTRUCCIONES:
	# corre vagrant up normalemente.
	# cambia disabled: false
	# corre vagrant reload
	# corre vagrant rsync   cada que hagas un cambio localmente para que se refleje en vagrant o vagrant rsync-auto para que mueva los cambios automáticamente. 
		config.vm.synced_folder "~/Documents/omegaup/omegaup-vagrant/omegaup", "/opt/omegaup", type: "rsync",
	    rsync__exclude: ".git/",
		rsync__args: "-rv",
		disabled: true
end
