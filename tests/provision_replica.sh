#!/bin/bash

wget --quiet http://apt.puppetlabs.com/puppetlabs-release-trusty.deb -O /tmp/puppetlabs-release-trusty.deb
dpkg -i /tmp/puppetlabs-release-trusty.deb
apt-get update
apt-get install -y puppet-common puppet ldapscripts
sed -i '/templatedir/d' /etc/puppet/puppet.conf

puppet module install puppetlabs-java
puppet module install camptocamp-augeas
puppet module install jhoblitt-port389

echo "127.0.0.1 replica.arenstar.net replica" >> /etc/hosts
echo '192.168.56.10 server.arenstar.net' >> /etc/hosts
echo '192.168.56.11 client.arenstar.net' >> /etc/hosts
echo '192.168.56.12 replica.arenstar.net' >> /etc/hosts

### this does a sneaky link - BAD ( Should update module )
ln -fs /usr/sbin/setup-ds-admin /usr/sbin/setup-ds-admin.pl

### this does a naughty replace - BAD ( should update module )
sed -i 's/redhat/debian/g' /etc/puppet/modules/port389/manifests/params.pp

### this does a dirty patch -  BAD - need solution ( should update module )
patch /etc/puppet/modules/port389/manifests/instance.pp /vagrant/patch/389_instances.patch

### this does a naughty replace - BAD ( should update module )
sed -i 's/redhat/debian/g' /etc/puppet/modules/nsstools/manifests/params.pp
sed -i 's/nss-tools/libnss3-tools/g' /etc/puppet/modules/nsstools/manifests/params.pp

