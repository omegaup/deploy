# Definitions
define remote_file($source=undef, $mode='0644', $owner=undef, $group=undef) {
  exec { "wget_${title}":
    command => "/usr/bin/wget -q ${source} -O ${title}",
    creates => $title,
  }

  file { $title:
    ensure  => 'file',
    mode    => $mode,
    owner   => $owner,
    group   => $group,
    require => Exec["wget_${title}"],
  }
}
class { 'apt':
  update => {
    frequency => 'daily',
  },
}

# Pre-stage
stage { 'pre':
  before => Stage['main'],
}
class pre {
  exec { 'stop_runner':
    command => '/usr/sbin/service runner stop',
    returns => [0, 1],
  }
}
class { 'pre':
  stage => 'pre',
}

# Packages
include apt
include archive::prerequisites
Exec["apt_update"] -> Package <| |>
apt::pin { 'utopic': priority => 700 }
apt::pin { 'utopic-updates': priority => 700 }
apt::pin { 'utopic-security': priority => 700 }
package { ['git', 'openjdk-8-jre', 'ca-certificates']:
  ensure  => present,
}

# Users
user { ['omegaup']:
  ensure => present,
}

# Execution environment
file { ["$omegaup_root", "${omegaup_root}/bin", "${omegaup_root}/compile",
	"${omegaup_root}/input"]:
  ensure => 'directory',
  owner  => 'omegaup',
}
archive { 'minijail':
  ensure => present,
  url => 'https://deploy.omegaup.com/distrib/minijail.tar.bz2',
  target => "${omegaup_root}",
  extension => 'tar.bz2',
  digest_type => 'sha1',
  checksum => true,
  strip_components => 1,
}
file { '/etc/sudoers.d/minijail':
  ensure  => 'file',
  content => "omegaup ALL = NOPASSWD: ${omegaup_root}/minijail/bin/minijail0
",
  mode    => '0440',
}
remote_file { "${omegaup_root}/bin/runner.jar":
  source => 'https://deploy.omegaup.com/distrib/runner.jar',
  require => File["${omegaup_root}/bin"],
}

# Runner service
file { '/etc/init.d/runner':
  ensure  => 'file',
  source  => "puppet:///modules/omegaup/runner.service",
  mode    => '0755',
}
service { 'runner':
  ensure  => running,
  enable  => true,
  require => [File['/etc/init.d/runner'],
              File["${omegaup_root}/bin/runner.jar"],
              Archive['minijail'],
              File['/etc/sudoers.d/minijail']]
}
