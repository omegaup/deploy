# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	config.vm.box = "omegaup-xenial"
	config.vm.box_url = "http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-vagrant.box"

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

	# Sincronizar un folder local con vagrant. Muy útil si quieres desarrollar
	# usando un IDE.  Esto NO funciona en Windows, solo en Linux / macOS.
	#
	# La razón es porque el script de instalación intenta crear un symlink en
	# /opt/omegaup, y Windows considera esto como una operación privilegiada.
	# Existe una manera para usarlo a partir de Windows 10 Build 14972, pero
	# necesita que Puppet se actualice con la nueva bandera descrita en
	#
	# https://blogs.windows.com/buildingapps/2016/12/02/symlinks-windows-10/#b1GbewbdoOuFHttq.97
	#
	# para que se pueda utilizar correctamente.
	config.vm.synced_folder "omegaup", "/opt/omegaup", create: true, disabled: true
end
