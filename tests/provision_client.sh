#!/bin/bash

wget --quiet http://apt.puppetlabs.com/puppetlabs-release-trusty.deb -O /tmp/puppetlabs-release-trusty.deb
dpkg -i /tmp/puppetlabs-release-trusty.deb
apt-get update
apt-get install -y puppet-common puppet ldapscripts git
sed -i '/templatedir/d' /etc/puppet/puppet.conf

puppet module install sgnl05-sssd
puppet module install saz-ssh
puppet module install saz-sudo

echo '192.168.56.10    ldap.arenstar.net' >> /etc/hosts
