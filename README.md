# Vagrant 389 Setup

## What is this 389 Setup

This vagrant setup is a simple example to get a [389 Server](http://directory.fedoraproject.org/ "389 Server") setup with a client machine authenticating.
Based on Ubuntu 14.04 Trusty64
It aims to solve some of the PCI-DSS scope for the following 

8.1.6 Limit repeated access attempts by locking out the user ID after not more than six attempts.
8.1.7 Set the lockout duration to a minimum of 30 minutes or until administrator enables the user ID.
8.1.8 If a session has been idle for more than 15 minutes, require the user to re-authenticate to re-activate the terminal or session.

8.2.1 Using strong cryptography, render all authentication credentials - LDAPs
8.2.3 Require a minimum password length of at least seven characters.
8.2.3 Use passwords containing both numeric and alphabetic characters.
8.2.4 Change user passwords at least every 90 days.
8.2.5 Do not allow an individual to submit a new password that is the same as any of the last four passwords he or she has used.
8.2.6 Set passwords/phrases for first-time use and upon reset to a unique value for each user, and change immediately after the first use.

It creates 2 simple users:
 
John Test "jtest" with the password "Pa$$w0rd".
Max Mustermann "mmustermann" with the password "QaWsEd123".

This vagrant setup configures multimaster replication between
ldap.arenstar.net and replica.arenstar.net 

## How do i run this setup?

Install vagrant and from the directory of this repository

```
vagrant box add trusty64 http://files.vagrantup.com/trust64.box
vagrant up
vagrant ssh
vagrant destroy
```

### Bringing up 389 over x11 ###
(Note: To get X11 on OSX install xquartz - http://www.xquartz.org/ )
```
vagrant ssh 389-server
sudo /usr/bin/389-console -a http://ldap.arenstar.net:9830

vagrant ssh 389-replica
sudo /usr/bin/389-console -a http://replica.arenstar.net:9830
```

### Testing client to ldap users "jtest"
(Note: password is Pa$$w0rd)
```
vagrant ssh 389-client
ssh jtest@127.0.0.1 
```

### Some helpers
```
ldapsearch -D "cn=Directory Manager" -w password -p 389 -h ldap.arenstar.net -s base -b "uid=mmustermann,ou=people,dc=arenstar,dc=net" "objectclass=*"
ldapwhoami -vvv -h ldap.arenstar.net -p 389 -D "uid=mmustermann,ou=People,dc=arenstar,dc=net" -w Pa$$w0rd -x
ldapsearch -x -H ldaps://ldap.arenstar.net -b dc=arenstar,dc=net
ldapmodify -x  -D "cn=Directory Manager" -w password -f /vagrant/ldifs/66pwdPolicy.ldif
ldapsearch -D "cn=directory manager" -w password -s sub -b cn=config "(objectclass=nsds5ReplicationAgreement)"
```


