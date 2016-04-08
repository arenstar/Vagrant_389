# Vagrant 389 Setup

## What is this 389 Setup

___Based on Ubuntu 14.04 Trusty64___

This setup is a vagrant example to create 3 systems:

* **server.arenstar.net**  - [389 Server](http://directory.fedoraproject.org/ "389 Server")
* **replica.arenstar.net** - Replication [389 Server](http://directory.fedoraproject.org/ "389 Server")
* **client.arenstar.net**  - Client Authentication using [SSSD](https://fedorahosted.org/sssd/ "SSSD")

Provided, these systems together achieve:

* Basic LDAP Authentication over **_LDAP_**/**_TLS_** (389) **_LDAPS_** (636)
* SSH PubKey LDAP Authentication
* Puppet templates for Group and User Configuration
* Password Policy and Lockout Policy Configuration
* LDAP Sudo integration for group **priv.ldap**
* LDAP Sudo Auth via SSH-AGENT using [pam-ssh-agent-auth](http://pamsshagentauth.sourceforge.net/ "pam-ssh-agent-auth")
* Online Backup and Restore
* Multimaster Replication over TLS

It aims to solve some of the PCI-DSS scope for the following [PCIDSS v3](https://www.pcisecuritystandards.org/documents/PCI_DSS_v3.pdf "PCIDSS v3")

| PCI Requirement | Description |
| :---: | :--- |
| 8.1.4 | Observe user accounts to verify that any inactive accounts over **90 days old** are either removed or disabled. |
| 8.1.6 | Limit repeated access attempts by locking out the user ID after not more than **6 attempts**. |
| 8.1.7 | Set the lockout duration to a minimum of **30 minutes** or until administrator enables the user ID. |
| 8.1.8 | If a session has been idle for more than **15 minutes**, require the user to re-authenticate to re-activate the terminal or session. |
| 8.2.1 | Using strong cryptography, render all authentication credentials - **LDAPS/TLS** |
| 8.2.3 | Require a minimum password length of at least **7 characters**. / Use passwords containing both **numeric and alphabetic** characters. |
| 8.2.4 | Change user passwords at least every **90 days**. |
| 8.2.5 | Do not allow an individual to submit a new password that is the same as any of the last **4 passwords** he or she has used. |
| 8.2.6 | Set passwords/phrases for first-time use and upon reset to a unique value for each user, and change immediately after the first use. |


It creates 2 posix groups:

| Group |  ID   | sudo  |
| :---: | :---: | :---: |
| priv.ldap | 5000  | yes |
| unpriv.ldap | 5001  | no |

It creates 2 posix users:

| Username    | Password  | ID    | Group       |
| :---------: | :-------: | :---: | :---------: |
| jsmith      | Pa$$w0rd  | 10000 | priv.ldap   |
| mmustermann | QaWsEd123 | 10001 | unpriv.ldap |



This vagrant setup also configures multimaster replication between
server.arenstar.net and replica.arenstar.net 

## How do i run this setup?

Install vagrant and from the directory of this repository

```
$ vagrant box add trusty64 http://files.vagrantup.com/trust64.box
$ vagrant up
$ vagrant ssh
$ vagrant destroy
```

### Bringing up 389 over x11 ###
(Note: To get X11 on OSX install xquartz - http://www.xquartz.org/ )
```
$ vagrant ssh 389-server
$ sudo /usr/bin/389-console -a http://server.arenstar.net:9830

$ vagrant ssh 389-replica
$ sudo /usr/bin/389-console -a http://replica.arenstar.net:9830
```

### Testing password login for LDAP users
```
$ vagrant ssh 389-client
$ ssh jsmith@127.0.0.1 

$ vagrant ssh 389-client
$ su - mmustermann
```

### Testing SSH PubKey login for LDAP users
```
$ vagrant ssh 389-client
$ ssh -A -i /vagrant/pki/jsmith_private_ssh.key jsmith@127.0.0.1
```

### Testing SSH PubKey sudo passwordless login for LDAP users
Requires [pam-ssh-agent-auth](http://ppa.launchpad.net/cpick/pam-ssh-agent-auth/ubuntu/pool/main/p/pam-ssh-agent-auth/pam-ssh-agent-auth_0.10.2-0ubuntu0ppa1_amd64.deb"pam-ssh-agent-auth") >= 0.10.2 
http://pamsshagentauth.sourceforge.net/

```
$ vagrant ssh 389-client
$ ssh -A -i /vagrant/pki/jsmith_private_ssh.key jsmith@127.0.0.1
$ sudo su
```

### Return All Objects For A User
```
$ ldapsearch  -D "cn=Directory Manager" -w password -H ldap://server.arenstar.net -s base -b "uid=jsmith,ou=people,dc=arenstar,dc=net" "objectclass=*"
```


### Check Users Password
```
$ ldapwhoami -x -H ldap://server.arenstar.net -D "uid=mmustermann,ou=people,dc=arenstar,dc=net" -w QaWsEd123
dn: uid=mmustermann,ou=people,dc=arenstar,dc=net
$ ldapwhoami -x -H ldap://server.arenstar.net -D "uid=mmustermann,ou=people,dc=arenstar,dc=net" -w wrongpassword
ldap_bind: Invalid credentials (49)
```

### Print Entire Directory
```
$ ldapsearch -x -H ldaps://server.arenstar.net -b dc=arenstar,dc=net
```

### Checking Replication Status
Refer to "nsds5replicaLastUpdateStatus"
```
$ vagrant ssh 389-server
$ ldapsearch -D "cn=directory manager" -w password -s sub -b cn=config "(objectclass=nsds5ReplicationAgreement)"

# extended LDIF
#
# LDAPv3
# base <cn=config> with scope subtree
# filter: (objectclass=nsds5ReplicationAgreement)
# requesting: ALL
#

# replicaagreement, replica, dc\3Darenstar\2Cdc\3Dnet, mapping tree, config
dn: cn=replicaagreement,cn=replica,cn=dc\3Darenstar\2Cdc\3Dnet,cn=mapping tree,cn=config
objectClass: top
objectClass: nsds5replicationagreement
cn: replicaagreement
nsDS5ReplicaHost: replica.arenstar.net
nsDS5ReplicaPort: 389
nsDS5ReplicaBindDN: cn=replication manager,cn=config
nsDS5ReplicaBindMethod: SIMPLE
nsDS5ReplicaTransportInfo: TLS
nsDS5ReplicaRoot: dc=arenstar,dc=net
description: agreement between supplier and consumer
nsDS5ReplicaUpdateSchedule: 0000-2359 0123456
nsDS5ReplicatedAttributeList: (objectclass=*) $ EXCLUDE authorityRevocationList
nsDS5ReplicaCredentials: secret
nsds5replicareapactive: 0
nsds5replicaLastUpdateStart: 20160407115515Z
nsds5replicaLastUpdateEnd: 20160407115515Z
nsds5replicaChangesSentSinceStartup:
nsds5replicaLastUpdateStatus: 0 Replica acquired successfully: Incremental update succeeded
nsds5replicaUpdateInProgress: FALSE
nsds5replicaLastInitStart: 20160407115512Z
nsds5replicaLastInitEnd: 20160407115514Z
nsds5replicaLastInitStatus: 0 Total update succeeded

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
```

### Starting Replication 
```
$ vagrant ssh 389-server
$ ldapmodify -x  -D "cn=Directory Manager" -w password -f /vagrant/ldifs/modify_start_replication.ldif

modifying entry "cn=ReplicaAgreement,cn=replica,cn="dc=arenstar,dc=net",cn=mapping tree,cn=config"
```


### Backup & Restore
From the dirsrv directory eg: /etc/dirsrv/slapd-ldap
``` 
$ db2ldif-online -Z ldap -P LDAP -s 'dc=arenstar,dc=net' -D 'cn=Directory Manager' -w password -a /var/backups/ldap.ldif

Exporting to ldif file: /var/backups/ldap.ldif
Successfully added task entry "cn=export_2016_4_8_10_6_37, cn=export, cn=tasks, cn=config"

$ ldif2db-online -Z ldap -P LDAP -s 'dc=arenstar,dc=net' -D 'cn=Directory Manager' -w password -i /var/backups/ldap.ldif

Successfully added task entry "cn=import_2016_4_8_10_7_17, cn=import, cn=tasks, cn=config"
```
