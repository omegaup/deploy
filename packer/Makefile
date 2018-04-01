PACKER_VERSION=1.2.2

packer:
	wget https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip
	unzip packer_$(PACKER_VERSION)_linux_amd64.zip
	rm packer_$(PACKER_VERSION)_linux_amd64.zip

box/box.ovf:
	mkdir -p box
	curl http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-vagrant.box | tar -x -C box

all: packer box/box.ovf
	./packer build vagrant-box.json
