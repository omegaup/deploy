from fabric.api import *
from fabric.contrib.files import exists
import StringIO
import hashlib
import os.path
import pipes
import tarfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(env['real_fabfile']),  '..'))

def stabletar(root, output, paths=None):
	if not paths:
		paths = [root]
	inode_map = {}
	with tarfile.open(output, mode='w:bz2') as tar:
		for p in paths:
			if p != root:
				info = tar.tarinfo(p)
				info.mtime = 0
				info.name = os.path.relpath(p, root)
				info.type = tarfile.DIRTYPE
				info.uname = info.gname = 'root'
				info.mode = 0755
				tar.addfile(info)
			for parent, dirs, files in os.walk(p):
				for d in sorted(dirs):
					path = os.path.join(parent, d)
					arcpath = os.path.relpath(path, root)
					info = tar.tarinfo(path)
					info.mtime = 0
					info.name = arcpath
					info.type = tarfile.DIRTYPE
					info.uname = info.gname = 'root'
					info.mode = os.lstat(path).st_mode
					tar.addfile(info)
				for f in sorted(files):
					path = os.path.join(parent, f)
					arcpath = os.path.relpath(path, root)
					if os.path.islink(path):
						info = tar.tarinfo(path)
						info.mtime = 0
						info.name = arcpath
						info.type = tarfile.SYMTYPE
						info.uname = info.gname = 'root'
						info.linkname = os.readlink(path)
						info.mode = os.lstat(path).st_mode
						tar.addfile(info)
					else:
						st = os.stat(path)
						if st.st_ino in inode_map:
							orig_path, orig_st = inode_map[st.st_ino]
							info = tarfile.TarInfo(arcpath)
							info.mtime = orig_st.st_mtime
							info.type = tarfile.LNKTYPE
							info.uname = info.gname = 'root'
							info.linkname = orig_path
							info.mode = orig_st.st_mode
							info.st_type = tarfile.LNKTYPE
							tar.addfile(info)
						else:
							inode_map[st.st_ino] = (arcpath, st)
							tar.add(path, arcpath)

def sha1sum(path):
	if not os.path.exists(path):
		return None
	h = hashlib.sha1()
	with open(path, 'rb') as f:
		while True:
			block = f.read(4096)
			if not block: break
			h.update(block)
	return h.hexdigest()

@task
@runs_once
def prepare_minijail(update=True):
	if update not in ('False', False):
		local('sudo apt-get update')
		local('sudo apt-get upgrade -y')
		local('sudo apt-get install -y vim curl gcc g++ git fp-compiler unzip '
		      'openssh-client make zip libcap-dev libgfortran3 ghc libelf-dev '
		      'libruby openjdk-8-jdk ca-certificates libghc-vector-dev '
		      'libghc-mtl-dev libghc-logict-dev libghc-lens-dev libghc-pipes-dev '
		      'libghc-mwc-random-dev libghc-hashtables-dev libghc-aeson-dev '
		      'libghc-hashmap-dev')
		local('sudo apt-get autoremove -y')
		with lcd(ROOT):
			local('git pull --rebase')
			local('git submodule update --init')

	with lcd(ROOT):
		local('make -C minijail')
		local('sudo rm -rf distrib')
		local('mkdir distrib')
		for f in ['', 'bin', 'lib', 'scripts']:
			os.mkdir('%s/distrib/minijail/%s' % (ROOT, f))
			os.utime('%s/distrib/minijail/%s' % (ROOT, f), (0, 0))
		for f in ['minijail0', 'ldwrapper', 'libminijailpreload.so']:
			local('sudo ln minijail/%s distrib/minijail/bin/' % f)
		for f in ['karel', 'kcl']:
			local('sudo ln bin/%s distrib/minijail/bin' % f)
		local('sudo ln stuff/libkarel.py distrib/minijail/lib')
		with lcd('distrib/minijail'):
			local('sudo %s/stuff/mkroot' % ROOT)
		for root, dirs, files in os.walk('%s/stuff/minijail-scripts' % ROOT):
			for f in files:
				local('sudo ln %s/%s distrib/minijail/scripts/%s' %
					(root, f, f))
		stabletar(os.path.join(ROOT, 'distrib'),
		          os.path.join(ROOT, 'distrib/minijail.tar.bz2'),
		          [os.path.join(ROOT, 'distrib/minijail')])
		local('sudo rm -rf distrib/minijail')

		if not os.path.exists('/var/www/distrib'):
			local('sudo mkdir /var/www/distrib')
		current = sha1sum('%s/distrib/minijail.tar.bz2' % ROOT)
		previous = sha1sum('/var/www/distrib/minijail.tar.bz2')
		if previous is None or current != previous:
			local('sudo mv distrib/minijail.tar.bz2 /var/www/distrib')
			local('echo \'%s  minijail.tar.bz2\' | sudo tee /var/www/distrib/minijail.tar.bz2.sha1')
		local('sudo rm -rf distrib')

@task
@runs_once
def prepare(update=True):
	with lcd(ROOT):
		local('sudo cp bin/runner.jar /var/www/distrib')
		local('sudo cp stuff/runner.service /var/www/distrib')
	prepare_minijail(update)

def upload(local, remote):
	local_sha1 = sha1sum(local)
	remote_sha1 = run('sha1sum %s' % (pipes.quote(remote)),
		warn_only=True, quiet=True)
	if remote_sha1.succeeded:
		remote_sha1 = remote_sha1.split()[0]
	else:
		remote_sha1 = ''
	if local_sha1 != remote_sha1:
		put(local, remote)
		return True
	return False

@task
def init(grader="omegaup.com"):
	hostname = env['host']
	key = os.path.join(ROOT, 'ssl', hostname + '.jks')
	if not os.path.exists(key):
		local('%s/bin/certmanager runner --hostname %s --output %s' %
			(ROOT, pipes.quote(hostname), pipes.quote(key)))
	sudo('mkdir -p /etc/omegaup')
	put(key, '/etc/omegaup/omegaup.jks', use_sudo=True)
	conf = """{
	"logging": {
		"file": "/opt/omegaup/runner.log"
	},
	"common": {
		"roots": {
			"compile": "/opt/omegaup/compile",
			"input": "/opt/omegaup/input"
		},
		"paths": {
			"minijail": "/opt/omegaup/minijail"
		}
	},
	"runner": {
		"port": 21681,
		"register_url": "https://%s:21680/endpoint/register/",
		"deregister_url": "https://%s:21680/endpoint/deregister/",
		"hostname": "%s"
	},
	"ssl": {
		"keystore_path": "/etc/omegaup/omegaup.jks",
		"truststore_path": "/etc/omegaup/omegaup.jks"
	}
}""" % (grader, grader, hostname)
	put(StringIO.StringIO(conf), '/etc/omegaup/omegaup.conf', use_sudo=True)
	sudo('apt-get install git puppet-common')

@task
def deploy():
	if not exists('deploy'):
		run('git clone https://github.com/omegaup/deploy')
	with cd('deploy'):
		run('git pull --rebase')
		run('puppet module install --modulepath puppet/modules puppetlabs/apt')
		run('puppet module install --modulepath puppet/modules gini/archive')
		sudo('sudo FACTER_omegaup_root=/opt/omegaup puppet apply --verbose --modulepath puppet/modules puppet/manifests/runner.pp')
