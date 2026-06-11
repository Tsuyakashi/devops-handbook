ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

NODES = {
  "master" => {
    hostname: "k8s-master",
    ip:       "192.168.56.10",
    memory:   2048,
    cpus:     2
  },
  "worker-1" => {
    hostname: "k8s-worker-1",
    ip:       "192.168.56.11",
    memory:   1536,
    cpus:     1
  },
  "worker-2" => {
    hostname: "k8s-worker-2",
    ip:       "192.168.56.12",
    memory:   1536,
    cpus:     1
  }
}
	
Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-libvirt"]
  config.vm.box = "bento/ubuntu-24.04"

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
        "masters" => ["master"],
        "workers" => ["worker-1", "worker-2"]
      }
      ansible.host_vars = {
        "master"   => { "ansible_host" => NODES["master"][:ip] },
        "worker-1" => { "ansible_host" => NODES["worker-1"][:ip] },
	"worker-2" => { "ansible_host" => NODES["worker-2"][:ip] }
      }
    end
  end
end
