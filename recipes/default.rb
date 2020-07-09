apt_repository 'elasticsearch' do
  uri 'https://artifacts.elastic.co/packages/7.x/apt'
  components ['main']
  distribution 'stable'
  key 'https://artifacts.elastic.co/GPG-KEY-elasticsearch'
  action :add
  deb_src false
end

if node.chef_environment == 'vagrant'
  cookbook_file '/etc/hosts' do
    source 'hosts'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
end

if node.role?('elasticsearch')
  include_recipe 'manhattan::elasticsearch'
end

if node.role?('kibana')
  include_recipe 'manhattan::kibana'
end
