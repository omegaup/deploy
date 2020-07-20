PACKER_VERSION=1.6.0

.PHONY: all
all: packer_virtualbox-ovf_virtualbox.box packer box/box.ovf

packer_virtualbox-ovf_virtualbox.box: vagrant-box.json | packer box/box.ovf
	./packer build vagrant-box.json

packer:
	wget https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip
	unzip packer_$(PACKER_VERSION)_linux_amd64.zip
	rm packer_$(PACKER_VERSION)_linux_amd64.zip

box/box.ovf:
	rm -rf box .tmp.box
	mkdir -p .tmp.box
	curl http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-vagrant.box | tar -x -C .tmp.box
	./resize.py .tmp.box
	mv .tmp.box box
