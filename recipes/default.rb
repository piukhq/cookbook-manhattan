# Install Java11

apt_repository 'openjdk' do
  uri 'ppa:openjdk-r/ppa'
end

package 'openjdk-11-jdk'
package 'unzip'

# Install opendistro repo
apt_repository 'elasticsearch' do
  arch 'amd64'
  uri 'https://d3g5vo6xdbdb9a.cloudfront.net/apt'
  components ['main']
  distribution 'stable'
  key 'https://d3g5vo6xdbdb9a.cloudfront.net/GPG-KEY-opendistroforelasticsearch'
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
