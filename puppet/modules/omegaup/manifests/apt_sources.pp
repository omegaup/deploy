class omegaup::apt_sources {
	# Packages
	class { 'apt':
		update => {
			frequency => 'daily',
		},
	}

	include apt

	apt::pin { 'vivid': priority => 700 }

	# HHVM
	apt::source { 'hhvm':
		location    => 'http://dl.hhvm.com/ubuntu',
		include     => {
			src       => false,
		},
		key         => {
			server    => 'hkp://keyserver.ubuntu.com:80',
			id        => '0x36aef64d0207e7eee352d4875a16e7281be7a449',
		},
	}

	# omegaUp
	apt::ppa { 'ppa:omegaup/omegaup': }
}
