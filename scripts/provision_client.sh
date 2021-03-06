#!/bin/bash

wget --quiet http://apt.puppetlabs.com/puppetlabs-release-trusty.deb -O /tmp/puppetlabs-release-trusty.deb
dpkg -i /tmp/puppetlabs-release-trusty.deb
apt-get update
apt-get install -y puppet-common puppet ldapscripts git
sed -i '/templatedir/d' /etc/puppet/puppet.conf

puppet module install sgnl05-sssd
puppet module install saz-ssh
puppet module install saz-sudo
puppet module install herculesteam-augeasproviders_pam
puppet module install puppetlabs-apt


echo "127.0.0.1 client.arenstar.net client" >> /etc/hosts
echo '192.168.56.10 server.arenstar.net' >> /etc/hosts
echo '192.168.56.11 client.arenstar.net' >> /etc/hosts
echo '192.168.56.12 replica.arenstar.net' >> /etc/hosts
