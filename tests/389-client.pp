node default {

  ### SSSD is now used in favour of pam_ldap for PAM -> https://fedorahosted.org/sssd/
  ### The following modules enables sss in pam/nsswitch instead of ldap 

  class {'::sssd':
    ensure    => present,
    mkhomedir => true,
    config    => {
      'sssd' => {
        'domains'               => 'default',
        'default_domain_suffix' => 'default',
        'config_file_version'   => 2,
        'reconnection_retries'  => 3,
        'sbus_timeout'          => 30,
        'services'              => ['nss', 'pam', 'ssh', 'sudo'],
        'debug_level'           => 3,
      },
      'domain/default' => {
        'enumerate'                  => true,
        'min_id'                     => 1000,
        'id_provider'                => 'ldap',
        'auth_provider'              => 'ldap',
        'cache_credentials'          => true,
        'ldap_id_use_start_tls'      => true,
        'ldap_tls_reqcert'           => 'never',
        'ldap_tls_cacert'            => '/vagrant/pki/arenstar_CA_cert.pem',
        'ldap_schema'                => 'rfc2307',
        'ldap_uri'                   => 'ldaps://ldap.arenstar.net',
        'ldap_search_base'           => 'dc=arenstar,dc=net',
        'ldap_account_expire_policy' => 'rhds',
        'ldap_access_order'          => 'filter, expire',
        'ldap_user_ssh_public_key'   => 'sshPublicKey',
        'debug_level'                => 3,
      },
      'nss' => {
        'filter_users'               => 'root',
        'filter_groups'              => 'root',
        'debug_level'                => 3,
      },
      'pam' => {
        'debug_level'                => 3,
      },
      'ssh' => {
        'debug_level'                => 3,
      },
      'sudo' => {
        'debug_level'                => 3,
      }
    } 
  }

  #### PCI-DSS 3.0 requirement 8.1.8 states: "If a session has been idle for more than 15 minutes, require the user to re-authenticate to re-activate the terminal or session." ###
  ### Set terminal timeout to 15 mins (900 seconds) and also removing history for security ###
  file { '/etc/profile.d/lockdown.sh':
    ensure => present,
    mode   => 0644,
    owner  => root,
    group  => root,
    #content => "TMOUT=900 \nexport TMOUT \nunset HISTFILE \nreadonly TMOUT\nreadonly HISTFILE \n";
    content => "TMOUT=900 \nexport TMOUT \nreadonly TMOUT\n";
  }

  class { 'ssh':
    storeconfigs_enabled => false,
    server_options => {
      'Port' => '22',
      'Protocol' => '2',
      'HostKey' => ['/etc/ssh/ssh_host_ed25519_key', '/etc/ssh/ssh_host_rsa_key','/etc/ssh/ssh_host_dsa_key','/etc/ssh/ssh_host_ecdsa_key'],
      'UsePrivilegeSeparation' =>  'yes',
      'AuthorizedKeysCommand' => '/usr/bin/sss_ssh_authorizedkeys',
      'AuthorizedKeysCommandUser' => 'root',
      'AuthorizedKeysFile' => '.ssh/authorized_keys',
      ##### 'AuthorizedKeysFile' => '/dev/null', ### if you want store key ONLY in ldap
      ###'ProxyCommand' => '/usr/bin/sss_ssh_knownhostsproxy -p %p %h'
      ###'GlobalKnownHostsFile' => '/var/lib/sss/pubconf/known_hosts'
      'UsePAM' => 'yes',
      'X11Forwarding' => 'no',
      'PermitRootLogin'=> 'no',
      'PasswordAuthentication' => 'no',
      'KeyRegenerationInterval' => '3600',
      'ServerKeyBits' => '1024',
      'SyslogFacility' => 'AUTH',
      'LogLevel' => 'INFO',
      'LoginGraceTime' => '120',
      'StrictModes' => 'yes',
      'RSAAuthentication' => 'yes',
      'PubkeyAuthentication' => 'yes',
      'IgnoreRhosts' => 'yes',
      'RhostsRSAAuthentication' => 'no',
      'HostbasedAuthentication' => 'no',
      'PermitEmptyPasswords' => 'no',
      'ChallengeResponseAuthentication' => 'no',
      'PasswordAuthentication' => 'yes',
      'PrintMotd' => 'no',
      'PrintLastLog' => 'yes',
      'TCPKeepAlive' => 'yes',
    },
  }

  class { 'sudo':
    purge               => false,
    config_file_replace => false,
  }
  sudo::conf { 'pcidss_group':
    priority => 10,
    content  => "%priv.ldap ALL=(ALL) ALL",
  }
  sudo::conf { 'keep_ssh_auth_sock':
    priority => 1,
    content  => "Defaults    env_keep += SSH_AUTH_SOCK",
  }


  apt::source { 'cpick-pam-ssh-agent-auth':
    location => 'http://ppa.launchpad.net/cpick/pam-ssh-agent-auth/ubuntu',
    repos    => 'main',
    key      => {
      'id'     => '4E6DB95B30E2F7E1A2AF0F45F7B3DC819A7B416C',
      'server' => 'keyserver.ubuntu.com',
    },
  }

  package {
    'pam-ssh-agent-auth':
      ensure  => latest,
      require => Class['apt::update'];
  }

  pam {
    'pam_ssh_agent_auth sudo auth':
      ensure    => present,
      service   => 'sudo',
      type      => 'auth',
      control   => 'sufficient',
      module    => 'pam_ssh_agent_auth.so',
      #arguments => ['file=/etc/security/authorized_keys','authorized_keys_command=/usr/bin/sss_ssh_authorizedkeys'],
      arguments => ['authorized_keys_command=/usr/bin/sss_ssh_authorizedkeys'],
      position  => 'after module pam_env.so';
  }
}
