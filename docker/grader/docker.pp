file { '/etc/omegaup': ensure => 'directory' }
file { '/etc/omegaup/grader':
	ensure => 'directory',
	require => File['/etc/omegaup'],
}

class { "::omegaup::grader":
	user => $user,
	services_ensure => stopped,
	embedded_runner => 'false',
	frontend_host => 'http://omegaup_frontend',
	mysql_user => 'root',
	mysql_host => 'omegaup_db',
}
