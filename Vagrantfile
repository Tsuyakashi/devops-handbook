# replaced blocked cloud with mirror
ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

Vagrant.configure("2") do |config|
    config.vagrant.plugins = ["vagrant-libvirt"]
    config.vm.box = "bento/ubuntu-24.04"

    # global libvirt settings
    config.vm.provider "libvirt" do |lv|
        lv.storage_pool_name = "images" # Фикс конфликта пулов в Ubuntu
    end

    # master node
    config.vm.define "master" do |master|
        master.vm.hostname = "k8s-master"
        master.vm.network "private_network", ip: "192.168.56.10"
        
        master.vm.provider "libvirt" do |lv|
            lv.memory = 2048
            lv.cpus = 2 
        end
    end
  
    # worker node   
    config.vm.define "worker-1" do |worker|
        worker.vm.hostname = "k8s-worker-1"
        worker.vm.network "private_network", ip: "192.168.56.11"
        
        worker.vm.provider "libvirt" do |lv|
            lv.memory = 1536
            lv.cpus = 1
        end

      worker.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/site.yml"
        ansible.compatibility_mode = "2.0"
        ansible.limit = "all"
        ansible.groups = {
            "masters" => ["master"],
            "workers" => ["worker-1"]
        }
        end
    end
end