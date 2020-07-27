---
page_title: "Manhattan"
---

[![Build Status](https://git.bink.com/DevOps/Cookbooks/manhattan/badges/master/pipeline.svg)](https://git.bink.com/DevOps/Cookbooks/manhattan)

This cookbook manages installing and configuring an OpenDistro ElasticSearch cluster as well as configuring OpenDistro Kibana. The reason for choosing OpenDistro is purely because its open, and security features are free as they should be, this allows us to configure SSO without paying a fortune.

## TODO

* look into ES cipher reduction though it makes curl sadface
* look into removing the horrific performance logger thingy
* Add SAN to node cert
* elasticsearch exporter

## How it works

### Elasticsearch

An encrypted Chef databag (detailed below) is created containing a Certificate Authority, a node certificate and an admin certificate. Each elasticsearch node will use the node cert for REST and transport communication (transport communication is intra-cluster communication). The nodes are configured to only allow transport traffic from a specific certificate DN (the node certificate), the node certificate is also whats presented from the loadbalancer when accessed from inside Azure.

Core elasticsearch roles and internal users are configured in `/usr/share/elasticsearch/plugins/opendistro_security/securityconfig/*.yml`, if those are edited, they will need to be inserted into a secure ES index using the `securityadmin.sh` script, examples of its use is in `./recipes/elasticsearch.rb`.

The nodes for the elasticsearch cluster are stored in the chef environment attribute `elasticsearch.nodes`, these nodes are inserted into each elasticsearch config so all the nodes know about eachother. When they start, they do some bookkeeping with the other nodes and then the cluster state turns green.

Apart from a select few internal users, Elasticsearch will authenticate users based on their OpenID token. The OpenID token is meant to be provided by Kibana.

### Kibana

The configuration of Kibana is extremely simple, a single config file. There is nothing complicated there, just the standard parameters to configure OpenID SSO.

Whilst Kibana is in this cookbook, its only for reference purposes and to be used when testing with test kitchen. In reality Kibana is deployed in the Tools Kubernetes cluster.

### Elasticsearch RBAC

Elasticsearch's RBAC system is split into 3 main parts:  users & backend roles, roles and role mappings. 

Users represent users stored within the elasticsearch internal user database. Backend roles would be the role defined by Azure AD SSO (Manfiest -> appRoles -> value).

Roles, as the name suggests define a subset of permissions, for example, "allow read and search access to the logstash-* index"

Role mappings, this is the slightly backwards piece. A Role mapping is created with the same name as the role you wish to map to, and then any users or backend roles you wish to use the role are added to the mapping. This means you can apply more than 1 role to a user/backend role. Which is the case for use of Kibana, the `kibana_user` role allows the use of Kibana and the `bink-developers` role allows the searching of `logstash-*` and `nginx-*`.

The inheritance looks something like this:

```
role             role mapping     backend role

kibana_user  <-  kibana_user  ->  bink-developers
                              ->  bink-devsecops
```


### Generating elasticsearch databag

```
mkdir certs
pushd certs
# Root CA
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -days 3650 -sha256 -key root-ca-key.pem -out root-ca.pem -subj "/C=GB/ST=Berkshire/L=Ascot/O=Bink/OU=DevOps/CN=elasticsearch CA"
# Admin cert
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
openssl req -new -days 3650 -key admin-key.pem -out admin.csr -subj "/C=GB/ST=Berkshire/L=Ascot/O=Bink/OU=DevOps/CN=elasticsearch-admin"
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem
# Node cert
openssl genrsa -out node-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node-key.pem
openssl req -new -days 3650 -key node-key.pem -out node.csr -subj "/C=GB/ST=Berkshire/L=Ascot/O=Bink/OU=DevOps/CN=elasticsearch.uksouth.bink.host"
openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node.pem
# Cleanup
rm -f admin-key-temp.pem admin.csr node-key-temp.pem node.csr

(
    echo '{'
    echo "  \""id"\"": "\""certificates"\"",
    echo "  \""ca_cert"\"": "\""$(base64 root-ca.pem)"\"",
    echo "  \""ca_key"\"": "\""$(base64 root-ca-key.pem)"\"",
    echo "  \""node_cert"\"": "\""$(base64 node.pem)"\"",
    echo "  \""node_key"\"": "\""$(base64 node-key.pem)"\"",
    echo "  \""admin_cert"\"": "\""$(base64 admin.pem)"\"",
    echo "  \""admin_key"\"": "\""$(base64 admin-key.pem)"\""
    echo '}'
) > certs.json

openssl rand -base64 512 | tr -d '\r\n' > encrypted_data_bag_secret

knife data bag create vagrant -z
knife data bag from file vagrant ./certs.json -z --secret-file ./encrypted_data_bag_secret

mv encrypted_data_bag_secret ../test/integration/encrypted_data_bag_secret_key
mv ~/data_bags/vagrant/certificates.json ../test/integration/data_bags/vagrant/certificates.json
```

## Warnings

### Ingest pipelines

When ingesting data into elasticsearch, it can run some basic Logstash like functionality to preprocess data. 

If the ingest pipeline fails, and ignore_error is not set to true, the data will be dropped silently.

If the user posting the data does not have permission to write to an index set by a pipeline, the data will be dropped silently.

You have been warned.
