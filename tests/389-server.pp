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
    schema_file => [
        '/vagrant/ldifs/install/68sshldpk.ldif',
    ],
    config_file => [
        '/vagrant/ldifs/install/sshconfig.ldif',
        '/vagrant/ldifs/install/replicationuser.ldif',
        '/vagrant/ldifs/install/replicationchangelog.ldif',
        '/vagrant/ldifs/install/replicationsupplier.ldif',
        '/vagrant/ldifs/install/replicationagreement.ldif',
    ],
    add_org_entries => 'Yes',
    suffix      => port389_domain2dn($::domain),
  }

  exec { "create_password_policy":
    command   => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /vagrant/ldifs/create_pwd_policy.ldif",
    tries       => 3,
    try_sleep   => 3,
    subscribe   => Service["dirsrv"],
    refreshonly => true
  }->
  exec { "create_organisation_units":
    command     => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /vagrant/ldifs/create_organisational_units.ldif",
    unless      => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b 'ou=people,dc=arenstar,dc=net' 'ou=people'",
  }->
  exec { "create_groups":
    command   => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /vagrant/ldifs/create_groups.ldif",
    unless    => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b 'cn=priv.ldap,ou=groups,dc=arenstar,dc=net' 'cn=priv.ldap'"
  }->
  exec { "create_user":
    command   => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /vagrant/ldifs/create_user.ldif",
    unless    => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b 'uid=jsmith,ou=people,dc=arenstar,dc=net' 'uid=jsmith'"
  }



  ### Quick ldif backup 

  file { 'dirsrv_backup_dir':
    ensure  => directory,
    name    => '/var/backups',
    owner   => 'dirsrv',
    group   => 'dirsrv',
    mode    => '0750';
  }

  file { 'dirsrv-manager-pass':
    ensure  => present,
    name    => "/etc/dirsrv/manager-pass",
    content => 'password',
    owner   => dirsrv,
    group   => dirsrv,
    mode    => '0750',
  }

  $cron_command = "/usr/sbin/db2ldif-online -P LDAP -D 'cn=Directory Manager' -j '/etc/dirsrv/manager-pass' -Z ldap -a '/var/backups/ldap.ldif' -s 'dc=arenstar,dc=net' > /dev/null"

  cron { "dirsrv-backup-ldap-cron":
    ensure      => present,
    command     => $cron_command,
    user        => 'dirsrv',
    hour        => '01',
    minute      => '05',
    weekday     => '*',
    environment => [ 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin', "MAILTO=david@arenstar.net" ];
  }
}
