# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
 config.vm.box = "https://download.gluster.org/pub/gluster/purpleidea/vagrant/centos-7.1/centos-7.1.box"
 config.vm.host_name = "puppettest"
 config.vm.synced_folder ".", "/etc/puppet/modules/pulp", type: "nfs", nfs_version: 4, nfs_udp: false

 config.vm.provider :libvirt do |domain|
   domain.memory = 2048
   domain.cpus   = 2
 end

 config.vm.provision "shell", inline: "puppet module install dprince-qpid"
 config.vm.provision "shell", inline: "puppet module install example42-yum"
 config.vm.provision "shell", inline: "puppet module install puppetlabs-mongodb"
 config.vm.provision "shell", inline: "puppet module install puppetlabs-stdlib"
 config.vm.provision :puppet, manifests_path: "vagrant/manifests/", synced_folder_type: "nfs"

end
