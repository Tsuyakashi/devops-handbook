ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

NODES = {
  "master-1" => { hostname: "k8s-master-1", ip: "192.168.56.10", memory: 1536, cpus: 1 },
  "master-2" => { hostname: "k8s-master-2", ip: "192.168.56.11", memory: 1536, cpus: 1 },
  "master-3" => { hostname: "k8s-master-3", ip: "192.168.56.12", memory: 1536, cpus: 1 },
  "worker-1" => { hostname: "k8s-worker-1", ip: "192.168.56.21", memory: 1024, cpus: 1 },
  "worker-2" => { hostname: "k8s-worker-2", ip: "192.168.56.22", memory: 1024, cpus: 1 }
}

# VIP для control plane — отдельная константа, используется в плейбуке
CONTROL_PLANE_VIP = "192.168.56.100"

Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-libvirt"]
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.boot_timeout = 300

  config.vm.provider "libvirt" do |lv|
    lv.storage_pool_name = "images"
  end

  NODES.each do |name, cfg|
    config.vm.define name do |node|
      node.vm.hostname = cfg[:hostname]
      node.vm.network "private_network", ip: cfg[:ip]

      node.vm.provider "libvirt" do |lv|
        lv.memory = cfg[:memory]
        lv.cpus   = cfg[:cpus]
      end
    end
  end

  config.vm.define "worker-2" do |last|
    last.vm.provision "ansible" do |ansible|
      ansible.playbook           = "ansible/site.yml"
      ansible.compatibility_mode = "2.0"
      ansible.limit              = "all"
      ansible.groups = {
        "masters"          => ["master-1", "master-2", "master-3"],
        "master_primary"   => ["master-1"],   # только он делает kubeadm init
        "master_secondary" => ["master-2", "master-3"],
        "workers"          => ["worker-1", "worker-2"]
      }
      ansible.host_vars = {
        "master-1" => { "ansible_host" => NODES["master-1"][:ip] },
        "master-2" => { "ansible_host" => NODES["master-2"][:ip] },
        "master-3" => { "ansible_host" => NODES["master-3"][:ip] },
        "worker-1" => { "ansible_host" => NODES["worker-1"][:ip] },
        "worker-2" => { "ansible_host" => NODES["worker-2"][:ip] }
      }
      ansible.extra_vars = {
        "control_plane_vip" => CONTROL_PLANE_VIP
      }
    end
  end
end