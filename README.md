omegaUp deploy
==============

Setting up an omegaUp development environment is easy:

### Vagrant

Vagrant is the recommended way to setup your environment in Windows, Linux, and macOS:

1. Download and install [Vagrant](https://www.vagrantup.com/downloads.html).
2. Download and install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
3. Download [this repository](https://github.com/omegaup/deploy/archive/master.zip)
   and extract it somewhere.
4. Open the directory that contains `Vagrantfile` and run `vagrant up` in the
   commandline.

You can now access the development box through
[http://localhost:8080/](http://localhost:8080) and SSH into the box using
`vagrant ssh` in the same directory you ran the previous command.

### Bash-on-Ubuntu-on-Windows (experimental)

This has been reported to work for some people, but it might not work on your machine:

1. Enable [Bash on Windows 10](https://msdn.microsoft.com/commandline/wsl/install_guide)
2. Download [this repository](https://github.com/omegaup/deploy/archive/master.zip)
   and extract it somewhere accessible to `bash`.
3. From `bash`, go to the extracted directory and run `./windows-install.sh`.
 
If this doesn't work, please use Vagrant.
