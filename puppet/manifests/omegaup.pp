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

# Packages
class { 'apt':
  update => {
	  frequency => 'daily',
	},
}

include apt

apt::pin { 'vivid': priority => 700 }
package { ['vim', 'curl', 'phpunit', 'phpunit-selenium', 'gcc', 'g++',
					 'git', 'unzip', 'openssh-client', 'zip', 'openjdk-8-jdk',
					 'ca-certificates']:
  ensure  => present,
}
Class['apt::update'] -> Package<| |>

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
package { 'hhvm':
  ensure  => present,
  require => Apt::Source['hhvm'],
}

# Minijail
apt::ppa { 'ppa:omegaup/omegaup': }
package { 'omegaup-minijail':
  ensure  => present,
	require => Apt::Ppa['ppa:omegaup/omegaup'],
}

# Users
user { ['omegaup', 'www-data']:
  ensure => present,
}

# Common
file { '/var/lib/omegaup':
  ensure => 'directory',
}
file { '/var/log/omegaup':
  ensure => 'directory',
}
file { '/var/www':
  ensure => 'directory',
}

# MySQL
class { '::mysql::server':
  root_password => $mysql_password,
	service_provider => 'systemd',
}
class { '::mysql::bindings':
  java_enable => true,
}
include '::mysql::server'
file { '/tmp/omegaup-test-data.sql':
  ensure => 'file',
  source => 'puppet:///modules/omegaup/test-data.sql',
}
mysql::db { 'omegaup':
  user     => 'omegaup',
  password => $mysql_password,
  host     => 'localhost',
  grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
  sql      => ["${omegaup_root}/frontend/private/bd.sql",
               "${omegaup_root}/frontend/private/countries_and_states.sql",
               '/tmp/omegaup-test-data.sql'],
  require  => [Vcsrepo[$omegaup_root], File['/tmp/omegaup-test-data.sql']],
}

# SBT
exec { 'update-ca-certificates':
  command => '/usr/sbin/update-ca-certificates -f',
  creates => '/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts',
  require => Package['ca-certificates'],
}
file { '/usr/bin/sbt':
  ensure  => 'file',
  content => '#!/bin/sh
java -Xss1M -XX:+CMSClassUnloadingEnabled -jar `dirname $0`/sbt-launch.jar "$@"',
  mode    => 'a+x',
  require => Exec['update-ca-certificates'],
}
remote_file { '/usr/bin/sbt-launch.jar':
  source => 'https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.7/sbt-launch.jar',
}

# Repository
file { $omegaup_root:
  ensure => 'directory',
  owner  => 'vagrant',
}
vcsrepo { $omegaup_root:
  ensure   => present,
  provider => git,
  source   => 'https://github.com/omegaup/omegaup.git',
  user     => 'vagrant',
  group    => 'vagrant',
  require  => File[$omegaup_root],
}
file { "${omegaup_root}/.git/hooks/pre-push":
  ensure  => 'link',
  target  => "${omegaup_root}/stuff/git-hooks/pre-push",
  owner   => 'vagrant',
  group   => 'vagrant',
  require => Vcsrepo[$omegaup_root],
}
exec { 'certmanager':
  command => "${omegaup_root}/bin/certmanager init --password ${keystore_password}",
  user    => 'vagrant',
  group   => 'vagrant',
  creates => "${omegaup_root}/ssl",
  require => [Vcsrepo[$omegaup_root], Package['openjdk-8-jdk']],
}

# minijail
file { '/etc/sudoers.d/minijail':
  ensure  => 'file',
  content => "omegaup ALL = NOPASSWD: /var/lib/minijail/bin/minijail0
",
  mode    => '0440',
  require => User['omegaup'],
}

# Grader service
file { "${omegaup_root}/bin/omegaup.jks":
  source  => "${omegaup_root}/backend/grader/omegaup.jks",
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
file { "${omegaup_root}/bin/omegaup.conf.sample":
  ensure  => 'file',
  source  => "puppet:///modules/omegaup/omegaup.conf.sample",
  mode    => '0644',
  require => Vcsrepo[$omegaup_root],
}
exec { "${omegaup_root}/bin/omegaup.conf":
  creates => "${omegaup_root}/bin/omegaup.conf",
  user    => 'vagrant',
  group   => 'vagrant',
  command => "/bin/sed -e \"s/db.user\\s*=.*\$/db.user=omegaup/;s/db.password\\s*=.*\$/db.password=${mysql_password}/;s/\\(.*\\.password\\)\\s*=.*\$/\\1=${keystore_password}/\" ${omegaup_root}/bin/omegaup.conf.sample > ${omegaup_root}/bin/omegaup.conf",
  require => File["${omegaup_root}/bin/omegaup.conf.sample"],
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
              File["${omegaup_root}/bin/omegaup.jks"],
              Exec["${omegaup_root}/bin/omegaup.conf"],
              Package['libmysql-java'], Mysql::Db['omegaup']],
}

# Web application
file { ['/var/lib/omegaup/problems', '/var/lib/omegaup/problems.git']:
  ensure  => 'directory',
  owner   => 'www-data',
  group   => 'www-data',
  require => File['/var/lib/omegaup'],
}
file { '/var/log/omegaup/omegaup.log':
  ensure  => 'file',
  owner   => 'www-data',
  group   => 'www-data',
  require => File['/var/log/omegaup'],
}
file { '/var/www/omegaup.com':
  ensure  => 'link',
  target  => "${omegaup_root}/frontend/www",
  require => [File['/var/www'], Vcsrepo[$omegaup_root]],
}
file { ["${omegaup_root}/frontend/www/img",
        "${omegaup_root}/frontend/www/templates"]:
  ensure  => 'directory',
  owner   => 'www-data',
  group   => 'www-data',
  require => Vcsrepo[$omegaup_root],
}
file { "${omegaup_root}/frontend/server/config.php":
  ensure  => 'file',
  content => "<?php
define('OMEGAUP_DB_USER', 'omegaup');
define('OMEGAUP_DB_PASS', '${mysql_password}');
define('OMEGAUP_DB_NAME', 'omegaup');",
  owner   => 'vagrant',
  group   => 'vagrant',
  require => Vcsrepo[$omegaup_root],
}
class { 'nginx': }
nginx::resource::vhost { 'localhost':
  ensure        => present,
  listen_port   => 80,
  www_root      => "${omegaup_root}/frontend/www",
  index_files   => ['index.php', 'index.html'],
  include_files => ["${omegaup_root}/frontend/server/nginx.rewrites"],
}
nginx::resource::location { 'php':
  ensure               => present,
  vhost                => 'localhost',
  www_root             => "${omegaup_root}/frontend/www",
  location             => '~ \.(hh|php)$',
  fastcgi              => '127.0.0.1:9000',
  proxy                => undef,
  fastcgi_script       => undef,
  location_cfg_prepend => {
    fastcgi_param     => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
    fastcgi_index     => 'index.php',
    fastcgi_keep_conn => 'on',
  }
}
service { 'hhvm':
  ensure  => running,
  enable  => true,
  require => Package['hhvm'],
}

# Test setup
mysql::db { 'omegaup-test':
  user     => 'omegaup',
  password => $mysql_password,
  host     => 'localhost',
  grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP'],
  sql      => ["${omegaup_root}/frontend/private/bd.sql",
               "${omegaup_root}/frontend/private/countries_and_states.sql"],
  require  => Vcsrepo[$omegaup_root],
}
file_line { 'hhvm include_path':
  line    => 'include_path = /usr/share/php:.',
  path    => '/etc/hhvm/php.ini',
  require => Package['hhvm'],
}
file { "${omegaup_root}/frontend/tests/test_config.php":
  ensure  => 'file',
  content => "<?php
define('OMEGAUP_DB_USER', 'omegaup');
define('OMEGAUP_DB_PASS', '${mysql_password}');
define('OMEGAUP_DB_NAME', 'omegaup-test');",
  owner   => 'vagrant',
  group   => 'vagrant',
  require => Vcsrepo[$omegaup_root],
}
file { "${omegaup_root}/frontend/tests/controllers/omegaup.log":
  ensure  => 'file',
  owner   => 'vagrant',
  group   => 'vagrant',
  require => Vcsrepo[$omegaup_root],
}
file { ["${omegaup_root}/frontend/tests/controllers/problems",
    "${omegaup_root}/frontend/tests/controllers/submissions"]:
  ensure  => 'directory',
  owner   => 'vagrant',
  group   => 'vagrant',
  require => Vcsrepo[$omegaup_root],
}
