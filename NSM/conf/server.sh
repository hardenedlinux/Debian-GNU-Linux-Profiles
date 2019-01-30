#!/usr/bin/env bash

KSPASS=bro@123

keytool -genkeypair -keystore server.keystore.jks -storepass ${KSPASS} -alias server -keypass ${KSPASS} -validity 365 -
dname CN=Zeek,C=cn


keytool -certreq -keystore server.keystore.jks -storepass ${KSPASS} -alias server -keypass ${KSPASS} -file server.csr


keytool -gencert -keystore mycastore.jks -storepass ${KSPASS} -alias myca -keypass ${KSPASS} -validity 365 -infile serv
er.csr -outfile server.cer


keytool -printcert -file server.cer


keytool -importcert -keystore server.truststore.jks -storepass ${KSPASS} -alias myca -keypass ${KSPASS} -file myca.cer




keytool -importcert -keystore server.keystore.jks -storepass ${KSPASS} -alias myca -keypass ${KSPASS} -file myca.cer


keytool -importcert -keystore server.keystore.jks -storepass ${KSPASS} -alias server -keypass ${KSPASS} -file server.ce
r
