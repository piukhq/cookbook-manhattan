apt_repository 'elasticsearch' do
  uri 'https://artifacts.elastic.co/packages/7.x/apt'
  components ['main']
  distribution 'stable'
  key 'https://artifacts.elastic.co/GPG-KEY-elasticsearch'
  action :add
  deb_src false
end

if node.chef_environment == 'vagrant'
  hosts = search(:node, "*:*")
  template "/etc/hosts" do
    source "hosts.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      :hosts => hosts,
      :hostname => node[:hostname],
      :fqdn => node[:fqdn]
    )
  end
end

if node.role?('elasticsearch')
  include_recipe 'manhattan::elasticsearch'
end

if node.role?('kibana')
  include_recipe 'manhattan::kibana'
end
