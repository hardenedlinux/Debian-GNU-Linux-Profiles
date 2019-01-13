#!/usr/bin/env bash

/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic http
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic dns
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic software
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic x509
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic ssh
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic ssl
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic smb
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic smb_files
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic smb_mapping
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic smtp
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic protocol-orig
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic protocol-resp
/opt/kafka/bin/kafka-acls.sh --authorizer kafka.security.auth.SimpleAclAuthorizer --authorizer-properties zookeeper.connect=node1:2181 --add --allow-principal User:metron --topic pe
