class rabbitmq( $up = true ) {

    include yum::epel

    package { 'rabbitmq-server' :
        ensure  => '2.8.7-1',
        require => [  File[ 'epel.repo' ],
                      Yumrepo[ 'kermit-custom' ],
                      Yumrepo[ 'kermit-thirdpart' ], ],
    }

# replace default service script, cf :
# www.couyon.net/1/post/2012/07/so-you-want-to-run-rabbitmq-on-rhelcentos-6.html
# www.mentby.com/Group/rabbitmq-discuss/issues-on-rhel-62-with-rabbitmq-282.html
# Requires that you comment out in /etc/sudoers : Default requiretty


    file { '/etc/sudoers.d/rabbitmq' :
        ensure  => present,
        source  => 'puppet:///modules/rabbitmq/rabbitmq.sudoers',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
    }

    file { '/etc/init.d/rabbitmq-server' :
        ensure  => present,
        source  => 'puppet:///modules/rabbitmq/rabbitmq-server',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package[ 'rabbitmq-server' ],
    }

    file { '/var/run/rabbitmq' :
        ensure  => directory,
        owner   => 'rabbitmq',
        group   => 'rabbitmq',
        mode    => '0755',
        require => Package[ 'rabbitmq-server' ],
    }

    file { '.erlang.cookie' :
        ensure  => present,
        path    => '/var/lib/rabbitmq/.erlang.cookie',
        source  => 'puppet:///modules/rabbitmq/erlang.cookie',
        owner   => 'rabbitmq',
        group   => 'rabbitmq',
        mode    => '0400',
        require => Package[ 'rabbitmq-server' ],
    }

    file { '/etc/rabbitmq/ssl' :
        ensure  => directory,
        mode    => '0755',
        require => Package[ 'rabbitmq-server' ],
    }

    file { 'rabbitmq.config' :
        ensure  => present,
        path    => '/etc/rabbitmq/rabbitmq.config',
        source  => 'puppet:///modules/rabbitmq/rabbitmq.config',
        require => Package[ 'rabbitmq-server' ],
    }

    # You can generate the CA and the key with helper scripts from
    # git://github.com/joemiller/joemiller.me-intro-to-sensu.git

    file { 'cacert.pem' :
        ensure  => present,
        path    => '/etc/rabbitmq/ssl/cacert.pem',
        source  => 'puppet:///modules/rabbitmq/ssl/cacert.pem',
        require => File[ '/etc/rabbitmq/ssl' ],
    }

    file { 'server_cert.pem' :
        ensure  => present,
        path    => '/etc/rabbitmq/ssl/server_cert.pem',
        source  => 'puppet:///modules/rabbitmq/ssl/server_cert.pem',
        require => File[ 'cacert.pem' ],
    }

    file { 'server_key.pem' :
        ensure  => present,
        path    => '/etc/rabbitmq/ssl/server_key.pem',
        source  => 'puppet:///modules/rabbitmq/ssl/server_key.pem',
        require => File[ 'server_cert.pem' ],
    }

    # Problem : HOME must be set
    #rabbitmq_plugin { 'rabbitmq_management' :
    #      ensure   => present,
    #      provider => 'rabbitmqplugins',
    #}

    exec { 'enable rabbitmq_management' :
        path        => '/usr/bin:/usr/sbin:/bin',
        environment => 'HOME=/root',
        command     => 'rabbitmq-plugins enable rabbitmq_management',
        require     => Package[ 'rabbitmq-server' ],
        unless      =>
            '/usr/sbin/rabbitmq-plugins list -E | grep -q rabbitmq_management',
    }

    service { 'rabbitmq-server' :
        ensure    => $up? { true    => running,
                            'true'  => running,
                            default => stopped },
        enable    => $up? { true    => true,
                            'true'  => true,
                            default => false },
        hasstatus => false,
        require   => [  Package[ 'rabbitmq-server' ],
                        File[ '.erlang.cookie', 'server_key.pem',
                          'rabbitmq.config', '/etc/init.d/rabbitmq-server',
                          '/etc/sudoers.d/rabbitmq',
                          '/var/run/rabbitmq/' ],
                        #Rabbitmq_plugin[ 'rabbitmq_management' ], ],
                        Exec[ 'enable rabbitmq_management' ], ],
    }

    include firewall

    firewall { '100 RabbitMQ' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => '5672',
          action => 'accept',
    }

    firewall { '101 RabbitMQ SSL' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => '5671',
          action => 'accept',
    }

    firewall { '102 RabbitMQ epmd' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => '4369',
          action => 'accept',
    }

    firewall { '103 RabbitMQ Stomp' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => '6163',
          action => 'accept',
    }

    firewall { '104 RabbitMQ Erlang' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => [ '9100', '9101', '9102', '9103', '9104', '9105', ],
          action => 'accept',
    }

    firewall { '105 RabbitMQ WebUI' :
          chain  => 'INPUT',
          proto  => 'tcp',
          state  => 'NEW',
          dport  => '55672',
          action => 'accept',
    }

}
