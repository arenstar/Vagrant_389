# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.synced_folder "../", "/vagrant_data" # Mount directory up a level so puppet module list can find modules
  config.vm.synced_folder ".", "/vagrant"

  config.ssh.forward_x11 = true
  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "512"]
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: :nfs,
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end

  config.vm.define "389-server", primary: true, autostart: true do |server|
    server.vm.box = "ubuntu/trusty64"
    server.vm.hostname = 'ldap.arenstar.net'
    server.vm.network :private_network, ip: "192.168.56.10"
    server.vm.provision :shell, :path => "tests/provision_server.sh"
    server.vm.provision :puppet, :manifests_path => ["vm","/vagrant/tests"], :manifest_file => "389-server.pp", :options => "--modulepath=/etc/puppet/modules --hiera_config /etc/hiera.yaml"
  end

  config.vm.define "389-client", autostart: true do |client|
    client.vm.box = "ubuntu/trusty64"
    client.vm.hostname = 'client.arenstar.net'
    client.vm.network  :private_network, ip: "192.168.56.11"
    client.vm.provision :shell, :path => "tests/provision_client.sh"
    client.vm.provision :puppet, :manifests_path => ["vm","/vagrant/tests"], :manifest_file => "389-client.pp", :options => "--modulepath=/etc/puppet/modules --hiera_config /etc/hiera.yaml"
  end

  config.vm.define "389-replica", autostart: true do |replica|
    replica.vm.box = "ubuntu/trusty64"
    replica.vm.hostname = 'replica.arenstar.net'
    replica.vm.network  :private_network, ip: "192.168.56.12"
    replica.vm.provision :shell, :path => "tests/provision_replica.sh"
    replica.vm.provision :puppet, :manifests_path => ["vm","/vagrant/tests"], :manifest_file => "389-replica.pp", :options => "--modulepath=/etc/puppet/modules --hiera_config /etc/hiera.yaml"
  end

end
