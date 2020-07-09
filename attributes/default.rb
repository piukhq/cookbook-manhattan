case chef_environment
when 'vagrant'
  default['elasticsearch']['heapsize'] = '1'
  default['elasticsearch']['nodes'] = ['monitoring-elasticsearch-01']
  default['kibana']['es_nodes'] = ['https://monitoring-elasticsearch-01:9200']
when 'uksouth-monitoring'
  default['elasticsearch']['heapsize'] = '8'
  default['elasticsearch']['nodes'] = %w(monitoring-elasticsearch-01 monitoring-elasticsearch-02 monitoring-elasticsearch-03)
  default['kibana']['es_nodes'] = %w(https://monitoring-elasticsearch-01:9200 https://monitoring-elasticsearch-02:9200 https://monitoring-elasticsearch-03:9200)
end
