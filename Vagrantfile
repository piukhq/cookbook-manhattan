Vagrant.configure('2') do |v|
  v.vm.box = 'bento/ubuntu-18.04'
  v.berkshelf.enabled = true
  (1..3).each do |i|
    v.vm.define "monitoring-elasticsearch-0#{i}" do |b|
      b.vm.hostname = "monitoring-elasticsearch-0#{i}"
      b.vm.provider :virtualbox do |p| 
        p.customize ["modifyvm", :id, "--memory", "2048"] 
      end
      b.vm.network :private_network, ip: "172.28.128.6#{i}"
      b.vm.provision 'chef_solo' do |c|
        c.version = '14.7.17'
        c.cookbooks_path = '../'
        c.roles_path = 'roles'
        c.add_role('elasticsearch')
        c.environments_path = 'environments'
        c.environment = 'vagrant'
      end
    end
  end
  v.vm.define 'monitoring-kibana-01' do |b|
    b.vm.hostname = 'monitoring-kibana-01'
    b.vm.network :private_network, ip: "172.28.128.60"
    b.vm.network "forwarded_port", guest: 5601, host: 5601
    b.vm.provision 'chef_solo' do |c|
      c.cookbooks_path = '../'
      c.version = '14.7.17'
      c.roles_path = 'roles'
      c.add_role('kibana')
      c.environments_path = 'environments'
      c.environment = 'vagrant'
    end
  end
end
