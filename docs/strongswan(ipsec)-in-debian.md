##Scenario

Android users use strongswan client to connect VPN gateway(host). Make sure connection between host and client
remain secrecy and integrity. (enable PFS by using DH groups)

##Keyword: ikev2, pfs, ipsec, android

##Install Strongswan

###Download sourcecode and signature


    $ wget https://download.strongswan.org/strongswan-5.5.1.tar.gz   
    $ wget https://download.strongswan.org/strongswan-5.5.1.tar.gz.sig   

###Verify signature

    $ gpg --verify strongswan-5.5.1.tar.gz.sig   
    gpg: Signature made Thu 20 Oct 2016 05:17:21 AM EDT using RSA key ID B34DBA77  
    gpg: Can't check signature: No public key

Adding pubkey

    $ gpg --search-keys 0xb34dba77

    gpg: searching for "0xb34dba77" from hkp server keys.gnupg.net   
    (1)	Andreas Steffen <andreas.steffen@strongswan.org>   
    3072 bit RSA key B34DBA77, created: 2009-06-12   
    (2)	Andreas Steffen <andreas.steffen@strongswan.org>   
    1024 bit RSA key B34DBA77, created: 2014-06-16 (revoked)   
    Keys 1-2 of 2 for "0xb34dba77".  Enter number(s), N)ext, or Q)uit > 1   
    gpg: requesting key B34DBA77 from hkp server keys.gnupg.net   
    gpg: /root/.gnupg/trustdb.gpg: trustdb created   
    gpg: key B34DBA77: public key "Andreas Steffen   
    <andreas.steffen@strongswan.org>" imported   
    gpg: no ultimately trusted keys found   
    gpg: Total number processed: 1   
    gpg:               imported: 1  (RSA: 1)   

Verify

    $ gpg --verify strongswan-5.5.1.tar.gz.sig   
    gpg: Signature made Thu 20 Oct 2016 05:17:21 AM EDT using RSA key ID B34DBA77   
    gpg: Good signature from "Andreas Steffen <andreas.steffen@strongswan.org>"   
    gpg: WARNING: This key is not certified with a trusted signature!   
    gpg:          There is no indication that the signature belongs to the owner.   
    Primary key fingerprint: 948F 158A 4E76 A27B F3D0  7532 DF42 C170 B34D BA77   

###Extract files

    $ tar zxvf strongswan-5.5.1.tar.gz


###Building strongswan

Install building dependencies

    $ sudo yum install libcurl-devel openssl-devel systemd-devel
    $ cd strongswan-5.5.1/   

Configure

    $ ./configure --prefix=/usr --sysconfdir=/etc --enable-aes \
            --enable-des --enable-sha1 --enable-md4 --enable-md5 \
            --enable-eap-md5 --enable-eap-identity --enable-hmac \
            --enable-kernel-libipsec --enable-dhcp --enable-eap-mschapv2 \
            --enable-eap-dynamic --enable-kernel-netlink --enable-attr \
            --enable-resolve --enable-socket-default --disable-gmp \
            --enable-openssl --enable-gcm --enable-eap-radius \
            --enable-aesni --enable-curl --enable-stroke --enable-fips-prf \
            --enable-systemd   

Make & Install

    $ sudo make && make install


##Configuration

Generate Self-sign Root Certificate Authority

gen-root-ca.sh

    $ cat >gen-root-ca.sh<<EOF   
    #!/bin/bash   
    
    gen_template()
    {
    cat <<EOF> root-ca.tmpl
    cn = "TYA Company Limited Root Certificate Authority"
    organization = "TYA Company Limited."
    unit = "TYA Infrastructure Assurance"
    country = "CN"
    expiration_days = "720"
    ca
    signing_key
    cert_signing_key
    crl_signing_key
    EOF
    }

    gen_ecc_key()
    {   
    certtool --generate-privkey --ecc --sec-param high -d 2 > root-ca-ecdsa-key.pem   
    }

    gen_ecc_cert()   
    {
    certtool --generate-self-signed \
             --load-privkey root-ca-ecdsa-key.pem \
             --template root-ca.tmpl \
             --outfile root-ca-ecdsa-cert.pem \
             --hash=SHA384
    }

    gen_template
    gen_ecc_key
    gen_ecc_cert
    EOF


gen-server-key-and-cert.sh


    cat >gen-server-key-and-cert.sh<<EOF
    #!/bin/bash

    gen_template()
    {
    cat <<EOF> vpn-server.tmpl
    cn = "TYA VPN Server"
    organization = "TYA Company Limited."
    unit = "TYA Infrastructure Assurance"
    country = "CN"
    expiration_days = "365"
    dns_name = "ikev2.xxx.com"
    signing_key
    tls_www_server
    EOF
    }

    gen_ecc_key()
    {
    certtool --generate-privkey --ecc --sec-param high -d 2 > vpn-server-ecdsa-key.pem
    }

    gen_rsa_key()
    {
    certtool --generate-privkey --rsa --sec-param medium -d 2 > vpn-server-rsa-key.pem
    }
    
    sign_ecc_cert()
    {
    certtool --generate-certificate \
             --load-ca-privkey root-ca-ecdsa-key.pem \
             --load-ca-certificate root-ca-ecdsa-cert.pem \
             --load-privkey vpn-server-ecdsa-key.pem \
             --template vpn-server.tmpl \
             --outfile vpn-server-ecdsa-cert.pem \
             --hash=SHA384
    }
    sign_rsa_cert()
    {
    certtool --generate-certificate \
             --load-ca-privkey root-ca-ecdsa-key.pem \
             --load-ca-certificate root-ca-ecdsa-cert.pem \
             --load-privkey vpn-server-rsa-key.pem \
             --template vpn-server.tmpl \
             --outfile vpn-server-rsa-cert.pem \
             --hash=SHA384
    }
    #gen_template
    #gen_ecc_key
    #sign_ecc_cert
    gen_template
    gen_rsa_key
    sign_rsa_cert
    EOF


please edit 'dns_name = "ikev2.xxx.com"' in "gen-server-key-and-cert.sh"
before run "gen-root-ca.sh" and "gen-server-key-and-cert.sh" on your own
machine. Because strongswan android client use IKEv2 only, and  

`host name configured with a VPN profile in the app *must be* 
contained in the gateway certificateas subjectAltName.`

                                    quote from strongswan client in google play

(https://play.google.com/store/apps/details?id=org.strongswan.android&hl=zh_CN)

When you setting a profile in your android client, you should use hostname
rather than ip, and server certificate's dns_name should point to your
strongswan server ip. So you can add a dns record in your local dns server and
configurate android phone to use this dns server.

And upload server certificate and privkey in strongswan server

for certificate

    /etc/ipsec.d/certs/vpn-server-rsa-cert.pem

for privkey

    /etc/ipsec.d/private/vpn-server-rsa-key.pem

set permissions

    $ chmod 600 /etc/ipsec.d/private/vpn-server-rsa-key.pem


###Configuration in Strongswan Server

/etc/ipsec.conf

    $ cat > /etc/ipsec.conf <<EOF
    config setup
        strictcrlpolicy=yes
        uniqueids = never

    conn android
        keyexchange=ikev2
        left=%defaultroute
        leftauth=pubkey
        leftsubnet=0.0.0.0/0
        leftcert=vpn-server-rsa-cert.pem
        right=%any
        rightauth=eap-mschapv2
        rightsourceip=10.0.0.0/24
        eap_identity=%any
        ike=aes256gcm16-sha512-modp4096!
        esp=aes128gcm16-sha512-ecp256!
        auto=add
    EOF

/etc/strongswan.conf

    $ cat > /etc/ipsec.secrets <<EOF
    : RSA  vpn-server-rsa-key.pem

    testuser : EAP "M2I3ZDFkNWE5Mjk51NzNhZGUz"
    EOF

/etc/strongswan.conf

    $ cat > /etc/strongswan.conf <<EOF
    charon {
        load = aes des sha1 sha2 md4 md5 pem pkcs1 gmp random nonce x509 curl gcm \
               revocation hmac xcbc stroke kernel-netlink socket-default fips-prf \
               eap-mschapv2 eap-identity updown openssl 
    }
    EOF

    $ sudo systemctl enable strongswan
    $ sudo systemctl start strongswan

    $ sudo systemctl status strongswan
    
    ● strongswan.service - strongSwan IPsec IKEv1/IKEv2 daemon using ipsec.conf
    Loaded: loaded (/usr/lib/systemd/system/strongswan.service; disabled; vendor preset: disabled)
    Active: active (running) since Sat 2016-11-05 03:48:01 EDT; 5s ag
    Main PID: 31585 (starter)
    CGroup: /system.slice/strongswan.service
               ├─31585 /usr/libexec/ipsec/starter --daemon charon --nofork
               └─31594 /usr/libexec/ipsec/charon

    Nov 05 03:48:01 debian charon[31594]: 00[CFG]   loaded EAP secret for testuser
    Nov 05 03:48:01 debian charon[31594]: 00[LIB] loaded plugins: charon aes des sha1 sha2 md...ssl
    Nov 05 03:48:01 debian charon[31594]: 00[JOB] spawning 16 worker threads
    Nov 05 03:48:01 debian ipsec_starter[31585]: charon (31594) started after 20 ms
    Nov 05 03:48:01 debian charon[31594]: 05[CFG] received stroke: add
    connection 'android'
    Nov 05 03:48:01 debian charon[31594]: 05[CFG] adding virtual IP address pool 10.0.0.0/24
    Nov 05 03:48:01 debian charon[31594]: 05[CFG]   loaded certificate    "CN=TYA VPN Server, OU...em'
    Nov 05 03:48:01 debian charon[31594]: 05[CFG]   id '%any' not confirmed by certificate, d...CN'
    Nov 05 03:48:01 debian charon[31594]: 05[CFG] added configuration 'android'
    Nov 05 03:48:01 debian ipsec[31585]: charon (31594) started after 20 ms
    Hint: Some lines were ellipsized, use -l to show in full.

###Firewall

    $ vim /etc/sysctl.conf
    net.ipv4.ip_forward=1
    sysctl -p

    $ iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    (for test purpose)

##Android Client setting

###Download android client

https://play.google.com/store/apps/details?id=org.strongswan.android&hl=zh_CN

###Import root ca

Because our server certificate is signed by self-signed root ca, so we should
import this root ca certificate on the phone.

push root-ca-ecdsa-cert.pem in your android phone.

And

Setting --> Security --> Import Certificate from storage

Find your self-signed root ca certificate.

#Strongswan android client

Server
ikev2.xxx.com

VPN Type
IKEv2 EAP (Username/Password)

Username
testuser
Password(optional)
M2I3ZDFkNWE5Mjk51NzNhZGUz

CA certificate
Don't select automatically
Select CA certificate  ---->  USER  ---->  TYA Company Limited.

and save
