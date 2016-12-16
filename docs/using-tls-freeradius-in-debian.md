###Using TLS FreerRADIUS in Debian

#####Keyword: 802.1x, EAP-TLS   

####Scenario   

In our company, we are planing upgrade our network from no authorization required or no strong authorization required to a strong authorization required network.
In order to do that, I decide to build a FreeRADIUS server with EAP-TLS support.

####Download sourcecode and signature

    $ wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-server-3.0.12.tar.gz   
    $ wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-server-3.0.12.tar.gz.sig   


####Verify sourcecode   

    $ gpg --search-keys 0x995B4F85   
    $ gpg --verify freeradius-server-3.0.12.tar.gz.sig   

####Build dependencies[1]   

    $ sudo apt install build-essential     

####Extract files

    $ tar zxvf freeradius-server-3.0.12.tar.gz   

####Configure and build

    $ cd freeradius-server-3.0.12   
    $ ./configure   
    $ make   
    $ sudo make install   

####Configuration

Because our build from sourc code, so we should copy the init.d scripts to `/etc/init.d/`
Go to `freeradius-server-3.0.12/scripts/` copy `rc.radiusd` to `/etc/init.d/radiusd`   

We could using `radius -X` to run in foregound and check if the configuration has problem.   
In freeradius-server-3.0.12 it would check the libssl version. If you using 1.0.1t it would ask you to check if there has a patch to `CVE-2016-6304`   
In Debian 8 (DEC 10 2016) using `libssl1.0.0/stable,now 1.0.1t-1+deb8u5` has this patch, so we should manually add a expection in *security section* of configuration file.   

edit the `/usr/local/etc/raddb/radiusd.conf` find the `security {..}` change   

    allow_vulnerable_openssl = no   

to   

    allow_vulnerable_openssl = 'CVE-2016-6304'   

If you are new with freeradius. You can configure an basic radius to verify the function of freeradius.   
######For test only purpose
edit `/usr/local/etc/raddb/clients.conf` add a client.   

    client test123 {   
            ipaddr = 192.168.1.2   #for example you can using WPA2-enterprise for test, this ip should be your wireless controller's IP  
            secret = test123   
    }   
    
edit `/usr/local/etc/raddb/users` and add an username"test" and has passowrd "test"          

    test Cleartext-Password := "test"   
    
Then you can using your phone or laptop to test access wireless network via 802.1x using EAP-MD5(The default EAP type in freeradius is MD5 see`/usr/local/etc/raddb/mods-enabled/eap`)   

######For what we really want EAP-TLS[2]   
We should edit the `/usr/local/etc/raddb/mods-enabled/eap` for change the default `EAP Type` from `md5` to `tls`   
Before we using tls, we should generate the certificate and key for Server, Client, and CA.   
gen-root-ca.sh   

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
gen-server-cert-and-cert.sh   

    #!/bin/bash

    gen_template()
    {
    cat <<EOF> radius-server.tmpl
    cn = "TYA Radius Server"
    organization = "TYA Company Limited."
    unit = "TYA Infrastructure Assurance"
    country = "CN"
    expiration_days = "365"
    dns_name = "radius.xxx.com"
    signing_key
    tls_www_server
    EOF
    }

    gen_ecc_key()
    {
    certtool --generate-privkey --ecc --sec-param high -d 2 > radius-server-ecdsa-key.pem
    }

    gen_rsa_key()
    {
    certtool --generate-privkey --rsa --sec-param medium -d 2 > radius-server-rsa-key.pem
    }
    
    sign_ecc_cert()
    {
    certtool --generate-certificate \
             --load-ca-privkey root-ca-ecdsa-key.pem \
             --load-ca-certificate root-ca-ecdsa-cert.pem \
             --load-privkey radius-server-ecdsa-key.pem \
             --template radius-server.tmpl \
             --outfile radius-server-ecdsa-cert.pem \
             --hash=SHA384
    }
    sign_rsa_cert()
    {
    certtool --generate-certificate \
             --load-ca-privkey root-ca-ecdsa-key.pem \
             --load-ca-certificate root-ca-ecdsa-cert.pem \
             --load-privkey radius-server-rsa-key.pem \
             --template radius-server.tmpl \
             --outfile radius-server-rsa-cert.pem \
             --hash=SHA384
    }
    #gen_template
    #gen_ecc_key
    #sign_ecc_cert
    gen_template
    gen_rsa_key
    sign_rsa_cert
    
gen-radius-client-cert-and-key.sh   

    #!/bin/bash
    gen_rsa_key()
    {
    certtool --generate-privkey --rsa --sec-param high > radius-client-rsa-key.pem
    }

    gen_template()
    {
    cat <<EOF> client-cert.tmpl
    country = CN
    organization = "TYA Company Limited."
    unit = "CISRT"                            
    cn = "username"
    tls_www_client
    signing_key
    EOF
    }
    #unit option: You can take it as your division name
    #cn option: You can take it as your username

    gen_client_cert()
    {
    certtool --generate-certificate \
             --load-ca-privkey root-ca-ecdsa-key.pem \
	     --load-ca-certificate root-ca-ecdsa-cert.pem \
	     --load-privkey radius-client-rsa-key.pem \
	     --template client-cert.tmpl \
	     --outfile radius-client-rsa-cert.pem \
	     --hash=SHA384
    }

    gen_rsa_key
    gen_template
    gen_client_cert

Edit the `/usr/local/etc/raddb/mods-enabled/eap`   

    eap{
            default_eap_type = tls   
        
            ...   
        }
And configure the `tls-common` section and `tls` section
    
    tls-config tls-common {
            private_key_password = whatever   #if you using a encrypted key, you should put the passphrase in here
            private_key_file = ${certdir}/server.key   
            
            certificate_file = ${certdir}/server.crt   
            ca_file = ${cadir}/ca.pem   #if you using a intermediate certificate authority, you should put your intermediate CA and root CA's certificate in same file, the order is `intermediate CA` and then `root CA`   
            ca_path = ${cadir}   
    }
    
    tls {
            tls = tls-common   
            virtual-server = check-eap-tls   
    }   
And we should copy the `check-eap-tls` virtual server from '/usr/local/etc/raddb/sites-available/' to `/usr/local/etc/raddb/sites-enabled/`

We should using `radiusd -X` to check if there is problem in our configuration.

####Configuration for NAS (Network Access Server) Client
######RUCKUS Zonedirector 1200
Go to `Configure` --> `AAA Servers` --> `Create New`   

    Name: freeradius
    Type: RADIUS
    Auth Method: CHAP
    IP Address: 192.168.1.99 #Server IP on your radius server.
    Port: 1812
    Shared Secret*: test123
And then Prss `OK` to create an AAA server profile.   
   
Go to `Configure` --> `WLANs` --> `Create New`   

    Authentication Options: 802.1x EAP   
    Encryption Options: WPA2
    Authentication Server: freeradius
       
######Linksys WRT1900ACS with openwrt   
Change `wpad-mini` to `wpad-full`   

   opkg update
   opkg remove wpad-mini
   opkg install wpad

Open Web GUI
Go to `Network` --> `Wifi` --> `add`
Interface Configuration   

    Encryption: WPA2-EAP
    Cipher:auto
    Radius-Authentication-Server: 192.168.1.99
    Radius-Authentication-Port: 1812
    Radius-Authentication-Secret: test123   
    
####Configuration for Clients(EAP-TLS)   
######For Android user connect wireless network using EAP-TLS   
Import root CA certificate:   
Copy your root CA ceritificate to your sdcard   
`Setting` --> `Security` --> `Install from Storage`   
Choose your CA certificate,   

    Certificate Name:radius-ca   
    Credential use: Wi-Fi   
And press OK
Import client credentials:   
first, you should bundle your key and certificate to p12 format   

    certtool --to-p12 --load-privkey user-key.pem --pkcs-cipher 3des-pkcs12 --load-certificate user-cert.pem --outfile user.p12 --outder   
Copy `p12` file to your sdcard.
`Setting` --> `Security` --> `Install from Storage`   
Choose your client certificate and key file,   

    Certificate Name:radius-client   
    Credential use: Wi-Fi   

Reference:   
[1] http://wiki.freeradius.org/building/Home   
[2] http://networkradius.com/doc/3.0.10/raddb/tls/tls-config_tls-common.html
