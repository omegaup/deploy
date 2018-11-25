PACKER_VERSION=1.3.5

.PHONY: all
all: packer box/box.ovf
	./packer build vagrant-box.json

packer:
	wget https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip
	unzip packer_$(PACKER_VERSION)_linux_amd64.zip
	rm packer_$(PACKER_VERSION)_linux_amd64.zip

box/box.ovf:
	mkdir -p box
	curl http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64-vagrant.box | tar -x -C box
