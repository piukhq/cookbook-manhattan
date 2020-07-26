# Todo update so we do this block on a version update
unless node['packages'].keys.include?('elasticsearch-oss')
  es_path = Chef::Config[:file_cache_path] + '/elasticsearch.deb'

  remote_file 'elasticsearch_deb' do
    source node['elasticsearch']['oss_url']
    owner 'root'
    group 'root'
    mode '0644'
    path es_path
  end

  dpkg_package 'elasticsearch' do
    source es_path
  end

  file 'elasticsearch_deb' do
    path es_path
    action :delete
  end
end

package 'opendistroforelasticsearch'

execute 'update_elastic_security' do
  command '/usr/share/elasticsearch/plugins/opendistro_security/tools/securityadmin.sh -cacert /etc/elasticsearch/certs/ca.pem -cert /root/.es/admin.pem -key /root/.es/admin-key.pem -cd /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/ -nhnv'
  action :nothing
  retry_delay 30
  retries 3
end

service 'elasticsearch' do
  action :enable
end

template '/etc/elasticsearch/elasticsearch.yml' do
  source 'elasticsearch.yml.erb'
  owner 'root'
  group 'elasticsearch'
  mode '0660'
  notifies :restart, 'service[elasticsearch]', :delayed
  variables(
    hostname: node['hostname'],
    nodes: node['elasticsearch']['nodes']
  )
end

certificates = data_bag_item(node.chef_environment, 'certificates')

directory '/etc/elasticsearch/certs' do
  owner 'root'
  group 'elasticsearch'
  mode '0750'
end

file '/etc/elasticsearch/certs/ca.pem' do
  content Base64.decode64(certificates['ca_cert'])
  owner 'root'
  group 'elasticsearch'
  mode '0640'
  notifies :restart, 'service[elasticsearch]', :delayed
end
file '/etc/elasticsearch/certs/node.pem' do
  content Base64.decode64(certificates['node_cert'])
  owner 'root'
  group 'elasticsearch'
  mode '0640'
  notifies :restart, 'service[elasticsearch]', :delayed
end
file '/etc/elasticsearch/certs/node-key.pem' do
  content Base64.decode64(certificates['node_key'])
  owner 'root'
  group 'elasticsearch'
  mode '0640'
  sensitive true
  notifies :restart, 'service[elasticsearch]', :delayed
end

directory '/root/.es' do
  owner 'root'
  group 'root'
  mode '0750'
end
file '/root/.es/admin.pem' do
  content Base64.decode64(certificates['admin_cert'])
  owner 'root'
  group 'root'
  mode '0600'
end
file '/root/.es/admin-key.pem' do
  content Base64.decode64(certificates['admin_key'])
  owner 'root'
  group 'root'
  mode '0600'
  sensitive true
end

%w(esnode-key.pem esnode.pem kirk-key.pem kirk.pem root-ca.pem).each do |f|
  file "/etc/elasticsearch/#{f}" do
    action :delete
  end
end

template '/etc/elasticsearch/jvm.options' do
  source 'jvm.options.erb'
  owner 'root'
  group 'elasticsearch'
  mode '0660'
  notifies :restart, 'service[elasticsearch]', :delayed
  variables(
    heapsize: node['elasticsearch']['heapsize']
  )
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

cookbook_file '/etc/systemd/system/elasticsearch.service.d/override.conf' do
  source 'override.conf'
  owner 'root'
  group 'elasticsearch'
  mode '0660'
  action :create
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

%w(config.yml internal_users.yml roles.yml roles_mapping.yml).each do |f|
  cookbook_file "/usr/share/elasticsearch/plugins/opendistro_security/securityconfig/#{f}" do
    source "elastic_security/#{f}"
    owner 'root'
    group 'elasticsearch'
    mode '0640'
    # notifies :run, 'execute[update_elastic_security]', :delayed
  end
end
