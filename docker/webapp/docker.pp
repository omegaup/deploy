class { '::omegaup::apt_sources': }

class { '::omegaup':
	user => $user,
	mysql_user => 'root',
	mysql_host => 'db',
	require => Class["::omegaup::apt_sources"],
}

