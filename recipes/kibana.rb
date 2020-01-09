package 'kibana'

service 'kibana' do
  action :enable
end

template '/etc/kibana/kibana.yml' do
  source 'kibana.yml.erb'
  owner 'root'
  group 'root'
  mode 0644
  notifies :restart, 'service[kibana]'
end
