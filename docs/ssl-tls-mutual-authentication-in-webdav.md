## SSL/TLS Mutual Authentication in Webdav
##### Copyright (c) TYA
##### Homepage: http://tya.company/


#####Update Repositories and Download Apache2
```
apt-get update
apt-get apache2
```

#####Mount Extenal Storage

```
mkdir /data/
mount /dev/sdb /data/
```

#####Setting Directories
```
mkdir -p /data/www/webdav
chown -R www-data:www-data /dev/www
```

#####Enable mod_ssl/mod_dav/mod_dav_fs/mod_dav_lock
```
a2enmod ssl
a2enmod dav
a2enmod dav_fs
a2enmod dav_lock
```

#####Configure Apache2
```
cat >/etc/apache2/sites-enabled/000-webdav-mutual-ssl.conf <EOF
DavLockDB /var/www/DavLock
<VirtualHost *:443>
        DocumentRoot  "/data/www/webdav"

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        
        #Enable SSL/TLS Authentication for Server
        SSLEngine on
        SSLCertificateFile    ${PATH to your server cert}
        SSLCertificateKeyFile ${PATH to your server key}

        #Enable SSL/TLS Authentication
        SSLVerifyClient require

        #If you using intermediate CA you should take care of VerifyDepth
        #
        #                   +-------+
        #                   |Root CA|
        #                   +-------+
        #                     |
        #                     |
        #              +---------------+
        #              | Webdav Sub-CA |
        #              +---------------+
        #                |     |     |
        #                |     |     |
        #              USER1 USER2 USERn
        #
        #
        SSLVerifyDepth 2
        SSLCACertificateFile ${PATH to your CA cert bundle}
        SSLCertificateChainFile ${PATH to your CA cert bundle}
        #"bundle" is your ROOT CA certificate and Sub-CA certificate
        # cat root-ca.pem sub-ca.pem > ca-bundle.pem

        #Verify Client's Certificate.
        <Location />
            DAV On
            SSLVerifyClient require
            SSLVerifyDepth 2
            SSLRequire %{SSL_CLIENT_I_DN_CN} eq "xxxx Company WebDav Certificate Authority"

            #%{SSL_CLIENT_I_DN_CN} is your issuer Common Name, if your infrastructure have
            #a lot of sub-ca, you should use x509 attribute to distinguish user.

        </Location>

        <Directory /data/www/webdav>
            Options Indexes FollowSymLinks MultiViews
            DAV On
            Satisfy Any
            Allow from all
            SSLVerifyClient on
            SSLVerifyDepth 2
            SSLRequire %{SSL_CLIENT_I_DN_CN} eq "xxx Company Limited Certificate Authority"
        </Directory>

        <Directory /data/www/webdav/group1>
            DAV On
            Satisfy Any
            Allow from all
            SSLVerifyClient on
            SSLVerifyDepth 2
            SSLRequire %{SSL_CLIENT_I_DN_CN} eq "xxx Company WebDav Certificate Authority" and %{SSL_CLIENT_S_DN_OU} eq "GROUP NAME"
            
            #As we know, the client(subject) certificate has “organization unit” attribute we could use it to distinguish different
            #Group
        </Directory>

        <Directory /data/www/webdav/group/user1>
            DAV On
            Satisfy Any
            Allow from all
            SSLVerifyClient on
            SSLVerifyDepth 2
            SSLRequire %{SSL_CLIENT_I_DN_CN} eq "xxx Company WebDav Certificate Authority" and %{SSL_CLIENT_S_DN_OU} eq "GROUP NAME" and %{SSL_CLIENT_S_DN_CN} eq "user1"
        </Directory>
</VirtualHost>
EOF
```

#####Reload Services
```
service apache2 reload
```

######Reference: 
######[1] http://unix.stackexchange.com/questions/123001/is-there-a-multi-user-webdav-server-available-for-linux
######[2] https://www.gnutls.org/manual/html_node/certtool-Invocation.html
