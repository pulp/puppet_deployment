class {'::yum::repo::epel':}

class { '::qpid::server':
  config_file => '/etc/qpid/qpidd.conf'
}

class { '::mongodb::server':
  journal   => false,
  nojournal => true
}

# pulp classes
class { '::pulp::repo':
  repo_priority => 1
}
class { '::pulp::server':
  db_name      => 'pulp',
  db_seed_list => 'localhost:27017',
}
class { '::pulp::admin':
  verify_ssl => false
}
class { '::pulp::consumer':
  verify_ssl => false
}

# dependency packages
package { ['qpid-cpp-server-store', 'python-gofer-qpid', 'python-qpid', 'python-qpid-qmf', 'qpid-tools']:
  ensure => 'installed',
}

service { 'httpd':
  ensure => 'running',
  enable => true
}

# ordering
anchor { 'profile::pulp::server::start': }
anchor { 'profile::pulp::server::end': }

Anchor['profile::pulp::server::start']->
Class['::yum::repo::epel']->
Class['::mongodb::server']->
Class['::pulp::repo']->
Class['::qpid::server']->
Package['qpid-cpp-server-store']->
Package['python-qpid']->
Package['python-qpid-qmf']->
Package['python-gofer-qpid']->
Class['::pulp::server']->
Class['::pulp::admin']->
Class['::pulp::consumer']->
Service['httpd']->
Anchor['profile::pulp::server::end']
