class omegaup::database (
	$root_password,
	$password
) {
	class { '::mysql::server':
		root_password => $root_password,
		service_provider => 'systemd',
	}

	class { '::mysql::bindings':
		java_enable => true,
	}

	include '::mysql::server'

	file { '/tmp/omegaup.sql':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/omegaup.sql',
	}

	file { '/tmp/omegaup-countries-and-states.sql':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/omegaup-countries-and-states.sql',
	}

	file { '/tmp/omegaup-test-data.sql':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/omegaup-test-data.sql',
	}

	mysql::db { 'omegaup':
		user     => 'omegaup',
		password => $password,
		host     => 'localhost',
		grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
		sql      => ['/tmp/omegaup.sql',
		             '/tmp/omegaup-test-data.sql',
								 '/tmp/omegaup-countries-and-states.sql'],
		require  => [File['/tmp/omegaup.sql'],
		             File['/tmp/omegaup-test-data.sql'],
								 File['/tmp/omegaup-countries-and-states.sql']],
	}

	mysql::db { 'omegaup-test':
		user     => 'omegaup',
		password => $mysql_password,
		host     => 'localhost',
		grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP'],
		sql      => ['/tmp/omegaup.sql',
								 '/tmp/omegaup-countries-and-states.sql'],
		require  => [File['/tmp/omegaup.sql'],
								 File['/tmp/omegaup-countries-and-states.sql']],
	}
}
