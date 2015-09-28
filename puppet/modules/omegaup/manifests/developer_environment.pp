class omegaup::developer_environment (
	$root = '/opt/omegaup',
) {
	# Packages
	package { ['vim', 'phpunit', 'phpunit-selenium', 'gcc', 'g++',
						 'silversearcher-ag']:
		ensure  => present,
	}

	# Definitions
	define remote_file($source=undef, $mode='0644', $owner=undef, $group=undef) {
		exec { "wget_${title}":
			command => "/usr/bin/wget -q ${source} -O ${title}",
			creates => $title,
		}

		file { $title:
			ensure  => 'file',
			mode    => $mode,
			owner   => $owner,
			group   => $group,
			require => Exec["wget_${title}"],
		}
	}

	# SBT
	exec { 'update-ca-certificates':
		command => '/usr/sbin/update-ca-certificates -f',
		creates => '/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts',
		require => Package['ca-certificates'],
	}
	file { '/usr/bin/sbt':
		ensure  => 'file',
		source  => 'puppet:///modules/omegaup/sbt',
		owner   => 'root',
		group   => 'root',
		mode    => 'a+x',
		require => Exec['update-ca-certificates'],
	}
	remote_file { '/usr/bin/sbt-launch.jar':
		source => 'https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.7/sbt-launch.jar',
	}

	# Test setup
	file_line { 'hhvm include_path':
		line    => 'include_path = /usr/share/php:.',
		path    => '/etc/hhvm/php.ini',
		require => Package['hhvm'],
	}
	config_php { "${root}/frontend/tests/test_config.php":
		mysql_db => 'omegaup-test',
		require => Vcsrepo[$root],
	}
	file { "${root}/frontend/tests/controllers/omegaup.log":
		ensure  => 'file',
		owner   => 'vagrant',
		group   => 'vagrant',
		require => Vcsrepo[$root],
	}
	file { ["${root}/frontend/tests/controllers/problems",
			"${root}/frontend/tests/controllers/submissions"]:
		ensure  => 'directory',
		owner   => 'vagrant',
		group   => 'vagrant',
		require => Vcsrepo[$root],
	}
}
