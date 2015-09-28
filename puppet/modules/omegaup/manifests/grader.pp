class omegaup::grader (
	$root,
) {
	class { '::omegaup::minijail': }

	file { "${root}/bin/omegaup.jks":
		source  => "${root}/backend/grader/omegaup.jks",
		require => Exec['certmanager'],
	}
	file { '/var/log/omegaup/service.log':
		ensure  => 'file',
		owner   => 'omegaup',
		group   => 'omegaup',
		require => File['/var/log/omegaup'],
	}
	file { '/etc/systemd/system/omegaup.service':
		ensure  => 'file',
		source  => "puppet:///modules/omegaup/omegaup.service",
		mode    => '0644',
	}
	file { "${root}/bin/omegaup.conf":
		ensure  => 'file',
		owner   => 'vagrant',
		group   => 'vagrant',
		mode    => '0644',
		content => template('omegaup/omegaup.conf.erb'),
		require => [Vcsrepo[$root]],
	}
	file { '/tmp/mkhexdirs.sh':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/mkhexdirs.sh',
		mode   => '0700',
	}
	exec { "submissions-directory":
		creates => '/var/lib/omegaup/submissions',
		command => '/tmp/mkhexdirs.sh /var/lib/omegaup/submissions www-data www-data',
		require => [File['/tmp/mkhexdirs.sh'], User['www-data']],
	}
	exec { "grade-directory":
		creates => '/var/lib/omegaup/grade',
		command => '/tmp/mkhexdirs.sh /var/lib/omegaup/grade omegaup omegaup',
		require => [File['/tmp/mkhexdirs.sh'], User['omegaup']],
	}
	file { ['/var/lib/omegaup/compile', '/var/lib/omegaup/input']:
		ensure  => 'directory',
		owner   => 'omegaup',
		group   => 'omegaup',
		require => File['/var/lib/omegaup'],
	}
	service { 'omegaup':
		ensure  => running,
		enable  => true,
		provider => 'systemd',
		require => [File['/etc/systemd/system/omegaup.service'],
								Exec['grade-directory'],
								File["${root}/bin/omegaup.jks"],
								File["${root}/bin/omegaup.conf"]],
	}
}
