class omegaup (
	$root = '/opt/omegaup',
) {
	# Definitions
	define config_php($mysql_db) {
		file { $title:
			ensure  => 'file',
			content => template('omegaup/config.php.erb'),
			owner   => 'vagrant',
			group   => 'vagrant',
		}
	}

	# Packages
	package { ['git', 'curl', 'unzip', 'openssh-client', 'zip',
						 'openjdk-8-jdk', 'ca-certificates']:
		ensure  => present,
	}

	package { 'hhvm':
		ensure  => present,
		require => Apt::Source['hhvm'],
	}

	# Users
	user { ['omegaup', 'www-data']:
		ensure => present,
	}

	# Common
	file { '/var/lib/omegaup':
		ensure => 'directory',
	}
	file { '/var/log/omegaup':
		ensure => 'directory',
	}
	file { '/var/www':
		ensure => 'directory',
	}

	# Repository
	file { $root:
		ensure => 'directory',
		owner  => 'vagrant',
	}
	vcsrepo { $root:
		ensure   => present,
		provider => git,
		source   => 'https://github.com/omegaup/omegaup.git',
		user     => 'vagrant',
		group    => 'vagrant',
		require  => File[$root],
	}
	file { "${root}/.git/hooks/pre-push":
		ensure  => 'link',
		target  => "${root}/stuff/git-hooks/pre-push",
		owner   => 'vagrant',
		group   => 'vagrant',
		require => Vcsrepo[$root],
	}
	exec { 'certmanager':
		command => "${root}/bin/certmanager init --password ${keystore_password}",
		user    => 'vagrant',
		group   => 'vagrant',
		creates => "${root}/ssl",
		require => [Vcsrepo[$root], Package['openjdk-8-jdk']],
	}

	# Web application
	file { ['/var/lib/omegaup/problems', '/var/lib/omegaup/problems.git']:
		ensure  => 'directory',
		owner   => 'www-data',
		group   => 'www-data',
		require => File['/var/lib/omegaup'],
	}
	file { '/var/log/omegaup/omegaup.log':
		ensure  => 'file',
		owner   => 'www-data',
		group   => 'www-data',
		require => File['/var/log/omegaup'],
	}
	file { '/var/www/omegaup.com':
		ensure  => 'link',
		target  => "${root}/frontend/www",
		require => [File['/var/www'], Vcsrepo[$root]],
	}
	file { ["${root}/frontend/www/img",
					"${root}/frontend/www/templates"]:
		ensure  => 'directory',
		owner   => 'www-data',
		group   => 'www-data',
		require => Vcsrepo[$root],
	}
	config_php { "${root}/frontend/server/config.php":
		mysql_db => 'omegaup',
		require => Vcsrepo[$root],
	}
	class { 'nginx': }
	nginx::resource::vhost { 'localhost':
		ensure        => present,
		listen_port   => 80,
		www_root      => "${root}/frontend/www",
		index_files   => ['index.php', 'index.html'],
		include_files => ["${root}/frontend/server/nginx.rewrites"],
	}
	nginx::resource::location { 'php':
		ensure               => present,
		vhost                => 'localhost',
		www_root             => "${root}/frontend/www",
		location             => '~ \.(hh|php)$',
		fastcgi              => '127.0.0.1:9000',
		proxy                => undef,
		fastcgi_script       => undef,
		location_cfg_prepend => {
			fastcgi_param     => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
			fastcgi_index     => 'index.php',
			fastcgi_keep_conn => 'on',
		}
	}
	service { 'hhvm':
		ensure  => running,
		enable  => true,
		require => Package['hhvm'],
	}

	class { "::omegaup::grader":
		root => $root
	}
}
