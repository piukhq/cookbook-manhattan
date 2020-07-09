package 'kibana'

service 'kibana' do
  action :enable
end

template '/etc/kibana/kibana.yml' do
  source 'kibana.yml.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[kibana]', :delayed
end

directory '/etc/kibana/certs' do
  owner 'root'
  group 'root'
  mode '0755'
end

certificates = data_bag_item(node.chef_environment, 'certificates')

file '/etc/kibana/certs/ca.pem' do
  content Base64.decode64(certificates[:'ca.pem'])
  mode '0644'
  sensitive true
end
