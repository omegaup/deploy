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
  always_apt_update    => false,
  disable_keys         => undef,
  proxy_host           => false,
  proxy_port           => '8080',
  purge_sources_list   => false,
  purge_sources_list_d => false,
  purge_preferences_d  => false,
  update_timeout       => undef,
  fancy_progress       => undef,
}
class { 'apt::release':
  release_id => 'utopic',
}
Exec["apt_update"] -> Package <| |>
include apt

# Packages
package { ['vim', 'curl', 'phpunit', 'phpunit-selenium', 'gcc', 'g++', 'git',
           'fp-compiler', 'unzip', 'openssh-client', 'make', 'zip',
           'libcap-dev', 'libgfortran3', 'ghc', 'libelf-dev', 'libruby',
           'openjdk-8-jdk', 'ca-certificates']:
  ensure  => present,
}

# HHVM
apt::key { 'hhvm':
  ensure     => 'present',
  key_source => 'http://dl.hhvm.com/conf/hhvm.gpg.key',
  key        => '1BE7A449',
}
apt::source { 'hhvm':
  location    => 'http://dl.hhvm.com/ubuntu',
  release     => 'utopic',
  require     => Apt::Key['hhvm'],
  include_src => false,
}
package { 'hhvm':
  ensure  => present,
  require => Apt::Source['hhvm'],
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
}
class { '::mysql::bindings':
  java_enable => true,
}
include 'mysql::server'
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
  revision => 'utopic',
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
exec { 'minijail':
  command => "/usr/bin/make -C ${omegaup_root}/minijail",
  user    => 'vagrant',
  group   => 'vagrant',
  creates => "${omegaup_root}/minijail/minijail0",
  require => [Vcsrepo[$omegaup_root], Package['make'], Package['gcc'],
              Package['libcap-dev'], Package['libelf-dev']],
}
file { $minijail_root:
  ensure => 'directory',
}
file { ["${minijail_root}/bin", "${minijail_root}/dist",
        "${minijail_root}/lib"]:
  ensure  => 'directory',
  require => File[$minijail_root],
}
file { "${minijail_root}/bin/karel":
  ensure  => 'file',
  source  => "${omegaup_root}/bin/karel",
  require => [File["${minijail_root}/bin"], Vcsrepo[$omegaup_root]],
}
file { "${minijail_root}/bin/kcl":
  ensure  => 'file',
  source  => "${omegaup_root}/bin/kcl",
  require => [File["${minijail_root}/bin"], Vcsrepo[$omegaup_root]],
}
file { "${minijail_root}/bin/minijail0":
  ensure  => 'file',
  source  => "${omegaup_root}/minijail/minijail0",
  require => [File["${minijail_root}/bin"], Exec['minijail']],
}
file { "${minijail_root}/bin/libminijailpreload.so":
  ensure  => 'file',
  source  => "${omegaup_root}/minijail/libminijailpreload.so",
  require => [File["${minijail_root}/bin"], Exec['minijail']],
}
file { "${minijail_root}/bin/ldwrapper":
  ensure  => 'file',
  source  => "${omegaup_root}/minijail/ldwrapper",
  require => [File["${minijail_root}/bin"], Exec['minijail']],
}
file { "${minijail_root}/bin/minijail_syscall_helper":
  ensure  => 'file',
  source  => "${omegaup_root}/minijail/minijail_syscall_helper",
  require => [File["${minijail_root}/bin"], Exec['minijail']],
}
file { "${minijail_root}/lib/libkarel.py":
  ensure  => 'file',
  source  => "${omegaup_root}/stuff/libkarel.py",
  require => [File["${minijail_root}/lib"], Vcsrepo[$omegaup_root]],
}
file { "${minijail_root}/scripts":
  ensure  => 'directory',
  recurse => true,
  source  => "${omegaup_root}/stuff/minijail-scripts",
  require => [File[$minijail_root], Vcsrepo[$omegaup_root]],
}
file { '/tmp/mkroot':
  ensure => 'file',
  source => 'puppet:///modules/omegaup/mkroot',
}
exec { 'mkroot':
  command => "/usr/bin/python /tmp/mkroot",
  creates => "${minijail_root}/root",
  cwd     => $minijail_root,
  require => [File[$minijail_root], File['/tmp/mkroot'],
              Package['openjdk-8-jdk'], Exec['minijail'], Package['libruby'],
              Package['g++'], Package['gcc'], Package['ghc'],
              Package['fp-compiler']],
}
file { '/etc/sudoers.d/minijail':
  ensure  => 'file',
  content => "omegaup ALL = NOPASSWD: ${minijail_root}/bin/minijail0
omegaup ALL = NOPASSWD: ${minijail_root}/bin/minijail_syscall_helper

",
  mode    => '0440',
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
file { '/etc/init.d/omegaup':
  ensure  => 'file',
  source  => "puppet:///modules/omegaup/omegaup.service",
  mode    => '0755',
}
exec { "${omegaup_root}/bin/omegaup.conf":
  creates => "${omegaup_root}/bin/omegaup.conf",
  user    => 'vagrant',
  group   => 'vagrant',
  command => "/bin/sed -e \"s/db.user\\s*=.*\$/db.user=omegaup/;s/db.password\\s*=.*\$/db.password=${mysql_password}/;s/\\(.*\\.password\\)\\s*=.*\$/\\1=${keystore_password}/\" ${omegaup_root}/backend/grader/omegaup.conf.sample > ${omegaup_root}/bin/omegaup.conf",
  require => Vcsrepo[$omegaup_root],
}
file { ['/var/lib/omegaup/compile', '/var/lib/omegaup/grade',
        '/var/lib/omegaup/input']:
  ensure  => 'directory',
  owner   => 'omegaup',
  group   => 'omegaup',
  require => File['/var/lib/omegaup'],
}
service { 'omegaup':
  ensure  => running,
  enable  => true,
  require => [File['/etc/init.d/omegaup'], File['/var/lib/omegaup/grade'],
              File["${omegaup_root}/bin/omegaup.jks"],
              Exec["${omegaup_root}/bin/omegaup.conf"],
              Package['libmysql-java'], Mysql::Db['omegaup']],
}

# Web application
file { ['/var/lib/omegaup/problems', '/var/lib/omegaup/problems.git',
        '/var/lib/omegaup/submissions']:
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
    fastcgi_param     => 'SCRIPT_FILENAME \$document_root\$fastcgi_script_name',
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
