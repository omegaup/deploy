class omegaup::minijail {
	package { 'omegaup-minijail':
		ensure  => present,
		require => Apt::Ppa['ppa:omegaup/omegaup'],
	}

	file { '/etc/sudoers.d/minijail':
		ensure  => 'file',
		source  => "puppet:///modules/omegaup/sudoers-minijail",
		owner   => 'root',
		group   => 'root',
		mode    => '0440',
		require => User['omegaup'],
	}
}
