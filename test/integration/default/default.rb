control 'elasticsearch_setup' do
  impact 1.0
  title 'Check that Elasticsearch is running'

  describe systemd_service('elasticsearch') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe port(9200) do
    it { should be_listening }
    its('processes') { should include 'java' }
  end
end

control 'kibana_setup' do
  impact 1.0
  title 'Check that Kibana is running'

  describe systemd_service('kibana') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe port(5601) do
    it { should be_listening }
    its('processes') { should include 'node' }
  end
end
