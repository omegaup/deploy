class { '::omegaup::apt_sources': }

class { '::omegaup::database':
  root_password => $mysql_password,
	password      => $mysql_password,
}

class { '::omegaup::certmanager': }
file { '/etc/omegaup': ensure => 'directory' }
file { ['/etc/omegaup/frontend', '/etc/omegaup/grader']:
	ensure  => 'directory',
	require => File['/etc/omegaup'],
}
omegaup::certmanager::cert { '/etc/omegaup/frontend/certificate.pem':
  hostname => 'localhost',
	owner    => 'www-data',
	mode     => '0600',
	require  => [File['/etc/omegaup/frontend'], User['www-data']],
}
omegaup::certmanager::cert { '/etc/omegaup/grader/keystore.jks':
	hostname => 'localhost',
  password => $keystore_password,
	owner    => 'omegaup',
	mode     => '0600',
	require  => [File['/etc/omegaup/grader'], User['omegaup']],
}

class { '::omegaup::minijail': }
class { '::omegaup::grader':
	require => Omegaup::Certmanager::Cert['/etc/omegaup/grader/keystore.jks'],
}

class { '::omegaup':
	development_environment => true,
	mysql_password          => $mysql_password,
	require                 => [Class["::omegaup::database"],
	                            Class["::omegaup::apt_sources"]],
}
