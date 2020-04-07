package 'elasticsearch'

service 'elasticsearch' do
  action :enable
end

template '/etc/elasticsearch/elasticsearch.yml' do
  source 'elasticsearch.yml.erb'
  owner 'root'
  group 'elasticsearch'
  mode 0660
  notifies :restart, 'service[elasticsearch]', :delayed
  variables(
    :hostname => node[:hostname],
  )
end

directory '/etc/elasticsearch/certs' do
  owner 'root'
  group 'elasticsearch'
  mode '0755'
end

certificates = data_bag_item(node.chef_environment, 'certificates')

file '/etc/elasticsearch/certs/elasticsearch.uksouth.bink.sh' do
  content Base64.decode64(certificates[:'elasticsearch.uksouth.bink.sh'])
  owner 'root'
  group 'elasticsearch'
  mode '0640'
  sensitive true
end

template '/etc/elasticsearch/jvm.options' do
  source 'jvm.options.erb'
  owner 'root'
  group 'elasticsearch'
  mode 0660
  notifies :restart, 'service[elasticsearch]', :delayed
end

append_if_no_line 'set maximum number of open files' do
  path '/etc/security/limits.conf'
  line 'elastic          -       nofile          65535'
end

replace_or_add 'uncomment pam_limits.so if commented' do
  path '/etc/pam.d/su'
  pattern /#session[ \t]+required[ \t]+pam_limits.so/
  line 'session    required   pam_limits.so'
  replace_only true
end

directory '/etc/systemd/system/elasticsearch.service.d' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute 'systemctl_daemon-reload' do
  command '/bin/systemctl daemon-reload'
  action :nothing
end

template '/etc/systemd/system/elasticsearch.service.d/override.conf' do
  source 'override.conf.erb'
  owner 'root'
  group 'elasticsearch'
  mode 0660
  notifies :run, 'execute[systemctl_daemon-reload]', :immediately
  notifies :restart, 'service[elasticsearch]', :delayed
end

execute 'sysctl_vm.swappiness' do
  command '/sbin/sysctl vm.swappiness=1'
  action :nothing
end

append_if_no_line 'set swappiness' do
  path '/etc/sysctl.conf'
  line 'vm.swappiness=1'
  notifies :run, 'execute[sysctl_vm.swappiness]', :immediately
end
