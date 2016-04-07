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
        '/vagrant/puppet/files/install/68sshldpk.ldif',
    ],
    config_file => [
        '/vagrant/puppet/files/install/sshconfig.ldif',
        '/vagrant/puppet/files/install/replicationuser.ldif',
        '/vagrant/puppet/files/install/replicationchangelog.ldif',
        '/vagrant/puppet/files/install/replicationsupplier.ldif',
        '/vagrant/puppet/files/install/replicationagreement.ldif',
    ],
    add_org_entries => 'Yes',
    suffix      => port389_domain2dn($::domain),
  }

  exec { "create_password_policy":
    command   => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /vagrant/puppet/files/create_pwd_policy.ldif",
    tries       => 3,
    try_sleep   => 3,
    subscribe   => Service["dirsrv"],
    refreshonly => true
  }->
  exec { "create_security_policy":
    command     => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /vagrant/puppet/files/create_security_policy.ldif",
    unless      => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b 'cn=config' 'objectclass=*'|grep -i nsslapd-security | grep on",
    notify      => Ldap::Ou::Add['people']
  }


  ldap::ou::add { 'people':
    ldap_suffix => 'dc=arenstar,dc=net',
  }->
  ldap::ou::add { 'groups':
    ldap_suffix => 'dc=arenstar,dc=net',
  }->
  ldap::group::add { 'priv.ldap':
    ou          => 'ou=groups',
    ldap_suffix => 'dc=arenstar,dc=net',
    gidnumber   => '5000',
    memberuid   => 'jsmith',
  }->
  ldap::group::add { 'unpriv.ldap':
    ou          => 'ou=groups',
    ldap_suffix => 'dc=arenstar,dc=net',
    gidnumber   => '5001',
    memberuid   => 'mmustermann',
  }->
  ldap::user::add { 'thenewguy':
    ou          => 'ou=people',
    ldap_suffix => 'dc=arenstar,dc=net',
    givenname   => 'new',
    lastname    => 'guy',
    uidnumber   => '123456',
    gidnumber   => '123456',
  }->
  ldap::user::add { 'mmustermann':
    ou          => 'ou=people',
    ldap_suffix => 'dc=arenstar,dc=net',
    givenname   => 'max',
    lastname    => 'mustermann',
    uidnumber   => '10001',
    gidnumber   => '5001',
    password    => 'QaWsEd123',
    pubkey      => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7pQkiPe1whtRc3ymuQXcdvCiPRV3HdkMQEG2mLGo78UI2HReMj6o9szLsb/a8pQLA9bqzCrO96C3qDwwCAVZyMVaQkfVitx+F3EqQKUePuJGM1aFmRcGJmNSISFr7w1O1NJYZaU1qVmYGfhSNPXqgX23P1aeWB/mo2Y5bHjgUfhitz5Mkv7dRQnM98GR7u/YYMtY41duSSn4sCFSw25CFXQwr0uSUg7p1vAInBIS4M2BF5F9T7b6pQAjqIssMZdJ5tGlluhsQTcw48FoVOgqEmbDxVZmHnqj27LByU/NUN4ZiI2RZtXQQHUtyJEO8qJgE9PVXsxmxsVdTSuPe1AjZ',
  }->
  ldap::user::add { 'jsmith':
    ou          => 'ou=people',
    ldap_suffix => 'dc=arenstar,dc=net',
    givenname   => 'john',
    lastname    => 'smith',
    uidnumber   => '10000',
    gidnumber   => '5000',
    password    => 'Pa$$w0rd',
    pubkey      => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7pQkiPe1whtRc3ymuQXcdvCiPRV3HdkMQEG2mLGo78UI2HReMj6o9szLsb/a8pQLA9bqzCrO96C3qDwwCAVZyMVaQkfVitx+F3EqQKUePuJGM1aFmRcGJmNSISFr7w1O1NJYZaU1qVmYGfhSNPXqgX23P1aeWB/mo2Y5bHjgUfhitz5Mkv7dRQnM98GR7u/YYMtY41duSSn4sCFSw25CFXQwr0uSUg7p1vAInBIS4M2BF5F9T7b6pQAjqIssMZdJ5tGlluhsQTcw48FoVOgqEmbDxVZmHnqj27LByU/NUN4ZiI2RZtXQQHUtyJEO8qJgE9PVXsxmxsVdTSuPe1AjZ',
  }->
  ldap::user::modify_pubkey { 'jsmith':
    ou          => 'ou=people',
    ldap_suffix => 'dc=arenstar,dc=net',
    pubkey      => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7pQkiPe1whtRc3ymuQXcdvCiPRV3HdkMQEG2mLGo78UI2HReMj6o9szLsb/a8pQLA9bqzCrO96C3qDwwCAVZyMVaQkfVitx+F3EqQKUePuJGM1aFmRcGJmNSISFr7w1O1NJYZaU1qVmYGfhSNPXqgX23P1aeWB/mo2Y5bHjgUfhitz5Mkv7dRQnM98GR7u/YYMtY41duSSn4sCFSw25CFXQwr0uSUg7p1vAInBIS4M2BF5F9T7b6pQAjqIssMZdJ5tGlluhsQTcw48FoVOgqEmbDxVZmHnqj27LByU/NUN4ZiI2RZtXQQHUtyJEO8qJgE9PVXsxmxsVdTSuPe1AjZ',
  }->
  ldap::user::modify_pubkey { 'sthenewguy':
    ou          => 'ou=people',
    ldap_suffix => 'dc=arenstar,dc=net',
    pubkey      => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7pQkiPe1whtRc3ymuQXcdvCiPRV3HdkMQEG2mLGo78UI2HReMj6o9szLsb/a8pQLA9bqzCrO96C3qDwwCAVZyMVaQkfVitx+F3EqQKUePuJGM1aFmRcGJmNSISFr7w1O1NJYZaU1qVmYGfhSNPXqgX23P1aeWB/mo2Y5bHjgUfhitz5Mkv7dRQnM98GR7u/YYMtY41duSSn4sCFSw25CFXQwr0uSUg7p1vAInBIS4M2BF5F9T7b6pQAjqIssMZdJ5tGlluhsQTcw48FoVOgqEmbDxVZmHnqj27LByU/NUN4ZiI2RZtXQQHUtyJEO8qJgE9PVXsxmxsVdTSuPe1AjZ',
  }

  #anchor { 'begin': }  ->
  #  class  { 'ldap::ou::add': }    ->
  #  class  { 'ldap::group::add': } ->
  #  class  { 'ldap::user::add': }  ->
  #anchor { 'end': }


  ### Quick ldif backup 

  $cron_command = "/usr/sbin/db2ldif-online -P LDAP -D 'cn=Directory Manager' -j '/etc/dirsrv/manager-pass' -Z ldap -s 'dc=arenstar,dc=net' -a /var/backups/ldap-`date +%s`.ldif > /dev/null"

  file { 'dirsrv_backup_dir':
    ensure      => directory,
    name        => '/var/backups',
    owner       => 'dirsrv',
    group       => 'dirsrv',
    mode        => '0750',
    subscribe   => Service["dirsrv"],
  }->
  file { 'dirsrv-manager-pass':
    ensure  => present,
    name    => "/etc/dirsrv/manager-pass",
    content => 'password',
    owner   => dirsrv,
    group   => dirsrv,
    mode    => '0750',
  }->
  cron { "dirsrv-backup-ldap-cron":
    ensure      => present,
    command     => $cron_command,
    user        => 'dirsrv',
    hour        => '01',
    minute      => '05',
    weekday     => '*',
    environment => [ 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin', "MAILTO=contact@davidarena.net" ];
  }

}

define ldap::user::modify_pubkey (
  $pubkey,
  $ou,
  $ldap_suffix,
  $username  = $title
){
  file { "/tmp/modify_${username}_pubkey.ldif":
    content => template("/vagrant/puppet/templates/modify_user_pubkey.ldif.erb"),
  }
  exec { "modify-${username}-pubkey":
    command     => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -w password -f /tmp/modify_${username}_pubkey.ldif",
    subscribe   => File["/tmp/modify_${username}_pubkey.ldif"],
    onlyif      => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b \"uid=${username},${ou},${ldap_suffix}\" \"uid=${username}\"",
    refreshonly => true,
  }
}

define ldap::user::add (
  $uidnumber,
  $gidnumber,
  $ou,
  $ldap_suffix,
  $givenname,
  $lastname,
  $pubkey = '',
  $fullname = "${givenname} ${lastname}",
  $loginshell = '/bin/bash',
  $homedir = "/home/${title}",
  $password = fqdn_rand_string(10),
  $username = $title
){
  file { "/tmp/ldap_add_${username}.ldif":
    content => template("/vagrant/puppet/templates/add_user.ldif.erb"),
  }
  exec { "ldap-add-${username}":
    command => "/usr/bin/ldapadd -x -D 'cn=Directory Manager' -w password -f /tmp/ldap_add_${username}.ldif",
    unless  => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b \"uid=${username},${ou},${ldap_suffix}\" \"uid=${username}\"",
    require => File["/tmp/ldap_add_${username}.ldif"];
  }
}

define ldap::group::add (
  $ou,
  $ldap_suffix,
  $memberuid,
  $gidnumber,
  $group = $title
){
  file { "/tmp/ldap_add_group_${group}.ldif":
    content => template("/vagrant/puppet/templates/add_group.ldif.erb"),
  }
  exec { "ldap-add-${group}-group":
    command => "/usr/bin/ldapadd -x -D 'cn=Directory Manager' -w password -f /tmp/ldap_add_group_${group}.ldif",
    unless  => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b \"cn=${group},${ou},${ldap_suffix}\" \"cn=${group}\"",
    require => File["/tmp/ldap_add_group_${group}.ldif"];
  }
}

define ldap::ou::add (
  $ldap_suffix,
  $ou = $title
){
  file { "/tmp/ldap_add_ou_${ou}.ldif":
    content => template("/vagrant/puppet/templates/add_organisational_units.ldif.erb"),
  }
  exec { "ldap-add-${ou}-ou":
    command => "/usr/bin/ldapadd -x -D 'cn=Directory Manager' -w password -f /tmp/ldap_add_ou_${ou}.ldif",
    unless  => "/usr/bin/ldapsearch -x -D 'cn=Directory Manager' -w password -b \"ou=${ou},${ldap_suffix}\" \"ou=${ou}\"",
    require => File["/tmp/ldap_add_ou_${ou}.ldif"];
  }
}
