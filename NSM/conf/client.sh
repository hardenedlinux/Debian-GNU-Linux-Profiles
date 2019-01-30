#!/usr/bin/env bash

CLIENT_PASS=broclient@123
KSPASS=bro@123
keytool -genkeypair -keystore client1.keystore.jks -storepass ${CLIENT_PASS} -alias client1 -keypass ${CLIENT_PASS} -va
lidity 365 -dname CN=client1,C=cn



keytool -certreq -keystore client1.keystore.jks -storepass ${CLIENT_PASS} -alias client1 -keypass ${CLIENT_PASS} -file
client1.csr



keytool -gencert -keystore mycastore.jks -storepass ${KSPASS} -alias myca -keypass ${KSPASS} -validity 365 -infile clie
nt1.csr -outfile client1.cer



keytool -printcert -file client1.cer



keytool -importcert -keystore client1.truststore.jks -storepass ${CLIENT_PASS} -alias myca -keypass ${CLIENT_PASS} -fil
e myca.cer



keytool -importcert -keystore client1.keystore.jks -storepass ${CLIENT_PASS} -alias myca -keypass ${CLIENT_PASS} -file
myca.cer



keytool -importcert -keystore client1.keystore.jks -storepass ${CLIENT_PASS} -alias client1 -keypass ${CLIENT_PASS} -fi
le client1.cer
