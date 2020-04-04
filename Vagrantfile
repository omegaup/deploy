# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	config.vm.box = "omegaup/dev-focal"

	# Redirige localhost:8080 hacia el puerto 80 de la VM
	config.vm.network :forwarded_port, guest: 80, host_ip: "127.0.0.1", host: 8080

	# Permite usar las llaves SSH del host en la VM
	config.ssh.forward_agent = true
	config.ssh.forward_x11 = true

	config.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--memory", "3072", "--cpus", "1"]
	end

	config.vm.provision :shell do |s|
		s.path = "linux-install.sh"
		s.env = {
			# Si tienes un fork de omegaUp en GitHub, agrega tu nombre de usuario
			# aquí para que tu fork esté disponible en /opt/omegaup como 'origin'.
			'github_username' => '',
		}
	end

	# Sincronizar un folder local con vagrant. Muy útil si quieres desarrollar
	# usando un IDE. No está activado por default porque vuelve bastante más
	# lenta la máquina virtual, y muchas veces ha ocurrido que se des-sincroniza
	# el estado entre la máquina virtual y el checkout externo del código.
	#
	# Una alternativa posiblemente mejor es usar VSCode como IDE, que tiene
	# soporte semi-nativo de SSH:
	# https://github.com/omegaup/omegaup/wiki/C%C3%B3mo-desarrollar-usando-VSCode-Remote
	#
	# Nota importante: Esto NO funciona en Windows, solo en Linux / macOS.
	#
	# La razón es porque git crea varios symlinks en /opt/omegaup, y Windows
	# considera esto como una operación privilegiada.  Existe una manera para
	# usarlo a partir de Windows 10 Build 14972, pero necesita que VirtualBox se
	# actualice con la nueva bandera descrita en
	#
	# https://blogs.windows.com/buildingapps/2016/12/02/symlinks-windows-10/#b1GbewbdoOuFHttq.97
	#
	# para que se pueda utilizar correctamente.
	enable_synced_folder = false
	config.vm.synced_folder "omegaup", "/opt/omegaup", create: true, disabled: !enable_synced_folder, type: "virtualbox"
end
