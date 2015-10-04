class { '::omegaup::apt_sources': }

file { '/etc/omegaup': ensure => 'directory' }
file { ['/etc/omegaup/frontend', '/etc/omegaup/grader']:
	ensure => 'directory',
	require => File['/etc/omegaup'],
}

class { "::omegaup::grader":
	user => $user,
	services_ensure => stopped,
	embedded_runner => 'false',
	mysql_user => 'root',
	mysql_host => 'db',
}

class { '::omegaup':
	user => $user,
	mysql_user => 'root',
	mysql_host => 'db',
	services_ensure => stopped,
	require => Class["::omegaup::apt_sources"],
}
