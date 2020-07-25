---
page_title: "Manhattan"
---

[![Build Status](https://git.bink.com/DevOps/Cookbooks/manhattan/badges/master/pipeline.svg)](https://git.bink.com/DevOps/Cookbooks/manhattan)

TODO:
* clean up files
* update readme
* doc roles and the backwardsness of it
* doc the kibana piece
* clean up unneeded attribute
* fix hosts list in attributes
* look into ES cipher reduction though it makes curl sadface
* add comments
* look into removing the horrific performance logger thingy
* elasticsearch exporter

Installs elasticsearch opendistro



## Generating elasticsearch databag

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
openssl req -new -days 3650 -key node-key.pem -out node.csr -subj "/C=GB/ST=Berkshire/L=Ascot/O=Bink/OU=DevOps/CN=elasticsearch.bink.host"
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
