ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

# Режим кластера: :single или :ha
CLUSTER_MODE = :single

NODES = if CLUSTER_MODE == :ha
  {
    "master-1" => { hostname: "k8s-master-1", ip: "192.168.56.10", memory: 1536, cpus: 1 },
    "master-2" => { hostname: "k8s-master-2", ip: "192.168.56.11", memory: 1536, cpus: 1 },
    "master-3" => { hostname: "k8s-master-3", ip: "192.168.56.12", memory: 1536, cpus: 1 },
    "worker-1" => { hostname: "k8s-worker-1", ip: "192.168.56.21", memory: 1024, cpus: 1 },
    "worker-2" => { hostname: "k8s-worker-2", ip: "192.168.56.22", memory: 1024, cpus: 1 }
  }
else
  {
    "master-1" => { hostname: "k8s-master-1", ip: "192.168.56.10", memory: 2048, cpus: 2 },
    "worker-1" => { hostname: "k8s-worker-1", ip: "192.168.56.21", memory: 1536, cpus: 1 }
  }
end

CONTROL_PLANE_VIP = "192.168.56.100"
LAST_NODE = NODES.keys.last

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

  config.vm.define LAST_NODE do |last|
    last.vm.provision "ansible" do |ansible|
      ansible.playbook           = "ansible/site.yml"
      ansible.compatibility_mode = "2.0"
      ansible.limit              = "all"
      ansible.groups = if CLUSTER_MODE == :ha
        {
          "masters"          => ["master-1", "master-2", "master-3"],
          "master_primary"   => ["master-1"],
          "master_secondary" => ["master-2", "master-3"],
          "workers"          => ["worker-1", "worker-2"]
        }
      else
        {
          "masters"          => ["master-1"],
          "master_primary"   => ["master-1"],
          "master_secondary" => [],
          "workers"          => ["worker-1"]
        }
      end

      ansible.host_vars = NODES.transform_values { |cfg| { "ansible_host" => cfg[:ip] } }

      env_vars = {}
      if File.exist?(".env")
        File.readlines(".env").each do |line|
          line = line.strip
          next if line.empty? || line.start_with?("#")
          
          if line.include?("=")
            key, value = line.split("=", 2)
            # Очищаем от возможных пробелов и лишних кавычек
            cleaned_key = key.strip.downcase
            cleaned_value = value.strip.gsub(/^["']|["']$/, "")
            
            env_vars[cleaned_key] = cleaned_value
          end
        end
      end

      ansible.extra_vars = { 
        "control_plane_vip" => CONTROL_PLANE_VIP,
        "github_user"       => env_vars["github_user"] || "default_user",
        "github_token"      => env_vars["github_token"] || "default_token"
      }
    end
  end
end