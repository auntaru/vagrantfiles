# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.define :node1, primary: true do |node1|
    node1.vm.box = "centos/7"
    node1.vm.hostname = "mdbgal1"
    #node1.vm.box_version = "2020.01"
    node1.vm.network "private_network", ip: "192.168.33.11"
    node1.vm.provider "virtualbox" do |vb|
      vb.cpus = "2"
      vb.memory = "1024"
    end
    node1.vm.provision :shell do |shell|
      shell.path = "provision.sh"
      shell.args = ["--wsrep-new-cluster"]
    end
  end
  config.vm.define :node2 do |node2|
    node2.vm.box = "centos/7"
    node2.vm.hostname = "mdbgal2"
    #node2.vm.box_version = "2020.01"
    node2.vm.network "private_network", ip: "192.168.33.12"
    node2.vm.provider "virtualbox" do |vb|
      vb.cpus = "2"
      vb.memory = "1024"
    end
    node2.vm.provision :shell do |shell|
      shell.path = "provision.sh"
      shell.args = []
    end
  end
  config.vm.define :node3 do |node3|
    node3.vm.box = "centos/7"
    node3.vm.hostname = "garb3"
    #node3.vm.box_version = "2020.01"
    node3.vm.network "private_network", ip: "192.168.33.13"
    node3.vm.provider "virtualbox" do |vb|
      vb.cpus = "2"
      vb.memory = "1024"
    end
    node3.vm.provision :shell do |shell|
      shell.path = "provision.sh"
      shell.args = []
    end
  end
end
