node default {

  include java
  include augeas

  class { 'port389':
    ensure                     => 'present',
    package_ensure             => 'apache2',
    package_name               => [
      '389-admin',
      '389-admin-console',
      'libadminutil0',
      'libadminutil-dev',
      '389-console',
      '389-ds',
      '389-ds-base',
      '389-ds-base-dev',
      '389-ds-base-libs',
      '389-ds-console',
      '389-ds-console-doc',
    ],
    enable_tuning              => true,
    user                       => 'dirsrv',
    group                      => 'dirsrv',
    admin_domain               => $::domain,
    config_directory_admin_id  => 'admin',
    config_directory_admin_pwd => 'password',
    config_directory_ldap_url  => "ldap://${::fqdn}:389/o=NetscapeRoot",
    full_machine_name          => $::fqdn,
    server_admin_port          => '9830',
    server_admin_id            => 'admin',
    server_admin_pwd           => 'password',
    server_ipaddress           => '0.0.0.0',
    root_dn                    => 'cn=Directory Manager',
    root_dn_pwd                => 'password',
    server_port                => '389',
    enable_ssl                 => true,
    enable_server_admin_ssl    => false,
    ssl_server_port            => '636',
    ssl_cert                   => '/vagrant/pki/ldap.arenstar.net_cert.pem',
    ssl_key                    => '/vagrant/pki/ldap.arenstar.net.key',
    ssl_ca_certs               => {
      'Arenstar CA' => '/vagrant/pki/arenstar_CA_cert.pem'
    },
    require                    => Class['augeas'],
  }

  port389::instance { 'ldap':
    config_file => [
        '/vagrant/ldifs/install/arenstarrootdb.ldif',
        '/vagrant/ldifs/install/replicationuser.ldif',
        '/vagrant/ldifs/install/replicationchangelog.ldif',
        '/vagrant/ldifs/install/replicationconsumer.ldif',
        '/vagrant/ldifs/install/replicationagreement.ldif',
    ],
    suffix      => port389_domain2dn($::domain),
  }

  #exec { "create_consumer":
  #  command   => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /vagrant/ldifs/create_consumer.ldif",
  #  tries       => 3,
  #  try_sleep   => 3,
  #  subscribe   => Service["dirsrv"],
  #  refreshonly => true
  #}
}
