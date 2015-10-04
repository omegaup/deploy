class { '::omegaup::apt_sources': }

file { '/etc/omegaup': ensure => 'directory' }
file { '/etc/omegaup/frontend':
	ensure => 'directory',
	require => File['/etc/omegaup'],
}

class { '::omegaup':
	user => $user,
	grader_host => 'https://omegaup_grader:21680',
	mysql_user => 'root',
	mysql_host => 'omegaup_db',
	services_ensure => stopped,
	require => Class["::omegaup::apt_sources"],
}
