default['elasticsearch']['oss_url'] = 'https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-7.8.0-amd64.deb'

case chef_environment
when 'vagrant'
  default['elasticsearch']['heapsize'] = '1'
  default['elasticsearch']['nodes'] = ['monitoring-elasticsearch-01']
  default['kibana']['es_loadbalancer'] = ['https://localhost:9200']
  default['kibana']['external_url'] = 'http://localhost:5601'
when 'uksouth-elasticsearch'
  default['elasticsearch']['heapsize'] = '8'
  default['elasticsearch']['nodes'] = %w(elasticsearch-00 elasticsearch-01 elasticsearch-02)
  default['kibana']['es_loadbalancer'] = ['https://elasticsearch.bink.host:9200']
  default['kibana']['external_url'] = 'https://kibana.uksouth.bink.sh'
end
