class { '::omegaup::apt_sources': }

class { '::omegaup::database':
  root_password => $mysql_password,
	password => $mysql_password,
}

class { '::omegaup::developer_environment': }
class { '::omegaup::minijail': }
class { '::omegaup::grader': }

class { '::omegaup':
	require => [Class["::omegaup::database"],
	            Class["::omegaup::apt_sources"]],
}
