

#!/usr/bin/env bash


KSPASS=bro@123
keytool -genkeypair -keystore mycastore.jks -storepass ${KSPASS} -alias myca -validity 365 -dname CN=ca,C=cn -ext bc:c
# export
keytool -exportcert -keystore mycastore.jks -storepass ${KSPASS} -alias myca -rfc -file myca.cer

# check
keytool -list -keystore mycastore.jks -storepass ${KSPASS}
keytool -printcert -file myca.cer
