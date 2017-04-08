# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	config.vm.box = "omegaup-wily-2017"
	config.vm.box_url = "https://s3.amazonaws.com/omegaup-dist/omegaup-wily-2017-base.box"

	# Redirige localhost:8080 hacia el puerto 80 de la VM
	config.vm.network :forwarded_port, guest: 80, host_ip: "127.0.0.1", host: 8080
	# Expone el puerto del servicio del backend.
	config.vm.network :forwarded_port, guest: 21680, host_ip: "127.0.0.1", host: 21680

	# Permite usar las llaves SSH del host en la VM
	config.ssh.forward_agent = true
	config.ssh.forward_x11 = true

	config.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "1"]
	end

	config.vm.provision :shell, path: "linux-install.sh"

	# Sincronizar un folder local con vagrant. Muy útil si quieres desarrollar usando un IDE.
	config.vm.synced_folder "omegaup", "/opt/omegaup", create: true, disabled: true
end
