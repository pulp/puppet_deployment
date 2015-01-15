# This is a private class that handles Pulp server configuration.

class pulp::server::config {
    # Write server.conf file
    file { '/etc/pulp/server.conf':
        content => template('pulp/etc/pulp/server.conf.erb'),
        owner   => 'root',
        group   => 'apache',
        mode    => '0640'
    } -> exec { 'Migrate DB':
        command => '/usr/bin/pulp-manage-db && touch /var/lib/pulp/.puppet-pulp-manage-db',
        user    => 'apache',
        creates => '/var/lib/pulp/.puppet-pulp-manage-db'
    }


    file {'/etc/pulp/server/plugins.conf.d/docker_importer.json':
        ensure  => file,
        content => template('pulp/plugins/docker_importer.json'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file {'/etc/pulp/server/plugins.conf.d/yum_importer.json':
        ensure  => file,
        content => template('pulp/plugins/yum_importer.json'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file {'/etc/pulp/server/plugins.conf.d/puppet_importer.json':
        ensure  => file,
        content => template('pulp/plugins/puppet_importer.json'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file {'/etc/pulp/server/plugins.conf.d/iso_importer.json':
        ensure  => file,
        content => template('pulp/plugins/iso_importer.json'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    # Configure Apache
    augeas { 'wsgi-processes':
        changes => "set /files/etc/httpd/conf.d/pulp.conf/*[self::directive='WSGIDaemonProcess']/arg[4] processes=${pulp::server::wsgi_processes}",
    }
    augeas { 'wsgi-threads':
        changes => "set /files/etc/httpd/conf.d/pulp.conf/*[self::directive='WSGIDaemonProcess']/arg[6] threads=${pulp::server::wsgi_threads}",
    }
}
