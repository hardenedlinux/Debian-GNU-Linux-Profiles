# Using Nginx as SSL tunnel for http service (SSL Mutual Authencitation for normal service)

System: Debian 9

We are using ElasticSearch as our example

## For server side 
### Pre-install packages 
Install sudo and set capabilities for usual user, example(user name is test): 
```
# apt install sudo -y && USER="test"; chmod 640 /etc/sudoers && sed -i "/^root/a\\${USER}   ALL=(ALL:ALL) ALL" /etc/sudoers && chmod 440 /etc/sudoers 
sudo apt install curl libcurl4-gnutls-dev -y 
```

### Install ElasticSearch

```
sudo apt install openjdk-8-jdk -y
sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo apt update
sudo apt-get install elasticsearch -y
```
changing the binding address as 127.0.0.1

Starting the service
```
sudo systemctl start elasticsearch
```

Using the curl to check if it's working
```
curl http://127.0.0.1:9200
```

And return 

```
{
  "name" : "ktiZiXR",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "H5PnL1q1SSGxcASCfx2c5g",
  "version" : {
    "number" : "6.6.1",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "1fd8f69",
    "build_date" : "2019-02-13T17:10:04.160291Z",
    "build_snapshot" : false,
    "lucene_version" : "7.6.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

### Install nginx of backports repo
```
sudo sh -c 'printf "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list'
sudo apt update
sudo apt install -t stretch-backports nginx -y
```

### Create CA and sign certificate

```
sudo apt install gnutls-bin -y
```

save following command as gen-root-ca.sh
```
#!/bin/bash   

gen_template()
{
cat <<EOF> root-ca.tmpl
cn = "ES Root Certificate Authority"
organization = "x"
unit = "Infrastructure Assurance"
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
```
after running the script.

we got ca certificate `root-ca-ecdsa-cert.pem` and the private key `root-ca-ecdsa-key.pem`

create the server's private key

```
certtool --generate-privkey --rsa --sec-param high > server-rsa-key.pem
```

Create Server's certificate template

```
cat <<EOF> server-cert.tmpl
country = CN
organization = "x"
unit = "ES"
cn = "esserver"
tls_www_server
signing_key
EOF
```

Sign the server's certificate

```
certtool --generate-certificate \
         --load-ca-privkey root-ca-ecdsa-key.pem \
     --load-ca-certificate root-ca-ecdsa-cert.pem \
     --load-privkey server-rsa-key.pem \
     --template server-cert.tmpl \
     --outfile server-rsa-cert.pem \
     --hash=SHA384
```

move the certificate and private key to /etc/ssl/

### Configurate the Nginx

To be a reverse proxy with ssl on

edit the  `/etc/nginx/sites-enabled/default`
```
server {
        listen 443 default_server;
        server_name rsserver;
        ssl on;
        ssl_certificate /etc/ssl/server-rsa-cert.pem;
        ssl_certificate_key /etc/ssl/server-rsa-key.pem;
        ssl_session_cache shared:SSL:10m;
        index index.html;
        
        location / {
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_pass http://127.0.0.1:9200/;
                proxy_redirect http:// https://;
        }
}
```
Restart the nginx
```
sudo systemctl restart nginx
```

Check it with curl

```
curl https://127.0.0.1 -k

{
  "name" : "ktiZiXR",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "H5PnL1q1SSGxcASCfx2c5g",
  "version" : {
    "number" : "6.6.1",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "1fd8f69",
    "build_date" : "2019-02-13T17:10:04.160291Z",
    "build_snapshot" : false,
    "lucene_version" : "7.6.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

So it's working for reverse proxy with nginx

For client authencication we should add our CA certificate and enable the verify `ssl_verify_client on`

now the `/etc/nginx/sites-enabled/default` should look like below

```
server {
        listen 443 default_server;

        server_name rsserver;
        ssl on;
        ssl_certificate /etc/ssl/server-rsa-cert.pem;
        ssl_certificate_key /etc/ssl/server-rsa-key.pem;
        ssl_session_cache shared:SSL:10m;

        ssl_client_certificate /etc/ssl/root-ca-ecdsa-cert.pem;
        ssl_verify_client on;

        index index.html;

        location / {
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_pass http://127.0.0.1:9200/;
                proxy_redirect http:// https://;
        }
}
```

Restart the nginx
```
sudo systemctl restart nginx
```

And using curl to check again
```
curl https://127.0.0.1 -k

<html>
<head><title>400 No required SSL certificate was sent</title></head>
<body bgcolor="white">
<center><h1>400 Bad Request</h1></center>
<center>No required SSL certificate was sent</center>
<hr><center>nginx/1.14.1</center>
</body>
</html>
```
Because we don't provide the certificate signed by our CA, so we can't access this service

We could using the client's nginx certificate on client for testing purpose. Need client certificate signed by our CA. An example is as follows:

```
curl  --key /etc/ssl/client-rsa-key.pem --cert /etc/ssl/client-rsa-cert.pem https://127.0.0.1 -k

{
  "name" : "ktiZiXR",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "H5PnL1q1SSGxcASCfx2c5g",
  "version" : {
    "number" : "6.6.1",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "1fd8f69",
    "build_date" : "2019-02-13T17:10:04.160291Z",
    "build_snapshot" : false,
    "lucene_version" : "7.6.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```
So the Client authentication is working.

### Sign the client's certificate

Additional, we have to sign the client's cert

create the client's private key

```
certtool --generate-privkey --rsa --sec-param high > client-rsa-key.pem
```

Create Server's certificate template

```
cat <<EOF> client-cert.tmpl
country = CN
organization = "x"
unit = "ES"
cn = "esclient"
tls_www_client
signing_key
EOF
```

Sign the client's certificate

```
certtool --generate-certificate \
         --load-ca-privkey root-ca-ecdsa-key.pem \
     --load-ca-certificate root-ca-ecdsa-cert.pem \
     --load-privkey client-rsa-key.pem \
     --template client-cert.tmpl \
     --outfile client-rsa-cert.pem \
     --hash=SHA384
```

## For client side

### Pre-Install packages 
Install sudo and set capabilities for usual user, example(user name is test): 
```
# apt install  sudo -y && USER="test"; chmod 640 /etc/sudoers && sed -i "/^root/a\\${USER}   ALL=(ALL:ALL) ALL" /etc/sudoers && chmod 440 /etc/sudoers 
sudo apt install curl libcurl4-gnutls-dev -y 
```

### Install nginx of backports repo 
```
sudo sh -c 'printf "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list'
sudo apt update
sudo apt install -t stretch-backports nginx -y
```
and copy `root-ca-ecdsa-cert.pem`, `client-rsa-key.pem` and `client-rsa-cert.pem` to client's server /etc/ssl/

Configure the nginx as reserve proxy


/etc/nginx/sites-enabled/default
```
server {
        listen 127.0.0.1:9200 default_server;
	    server_name rsclient;

        location / {
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
		        proxy_ssl_certificate /etc/ssl/client-rsa-cert.pem;
		        proxy_ssl_certificate_key /etc/ssl/client-rsa-key.pem;
                proxy_pass https://192.168.200.131/;
                proxy_redirect http:// https://;
        }
}
```

Restart the service
```
sudo systemctl restart nginx
```
Using the Curl to check the Service
```
curl http://127.0.0.1:9200


{
  "name" : "ktiZiXR",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "H5PnL1q1SSGxcASCfx2c5g",
  "version" : {
    "number" : "6.6.1",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "1fd8f69",
    "build_date" : "2019-02-13T17:10:04.160291Z",
    "build_snapshot" : false,
    "lucene_version" : "7.6.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

Until now, we finish the client authentication. Means the server can verify the client is authentic.

After that, We need to configurate the client to verify the server.


### Verify the Server

edit the  `/etc/nginx/sites-enabled/default`

```server {
        listen 127.0.0.1:9200 default_server;
        server_name rsclient;

        location / {
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_ssl_certificate /etc/ssl/client-rsa-cert.pem;
                proxy_ssl_certificate_key /etc/ssl/client-rsa-key.pem;

                proxy_ssl_trusted_certificate /etc/ssl/root-ca-ecdsa-cert.pem;
                proxy_ssl_verify       on;
                proxy_ssl_verify_depth 2;

                proxy_pass https://esserver/;
                proxy_redirect http:// https://;
        }

}
```
Right now we using `esserver` as domain name ( common name )

When we verify the server, we need to verify their `cn` (common name).
We sign the server's certificate with `cn` `esserver` so we need to use it, in our nginx config, otherwise 
Nginx will encounter error

```
upstream SSL certificate does not match "192.168.200.131" while SSL handshaking to upstream, client: 127.0.0.1, server: 127.0.0.1:9200, upstream: "192.168.200.131:443", bytes from/to client:0/0, bytes from/to upstream:0/0
```

And add the `esserver` to `/etc/hosts`
```
sudo echo "192.168.200.131 esserver" >> /etc/hosts
```

And then restart the nginx service

```
sudo systemctl restart nginx
```

testing

```
curl http://127.0.0.1:9200 -k
{
  "name" : "ktiZiXR",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "H5PnL1q1SSGxcASCfx2c5g",
  "version" : {
    "number" : "6.6.1",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "1fd8f69",
    "build_date" : "2019-02-13T17:10:04.160291Z",
    "build_snapshot" : false,
    "lucene_version" : "7.6.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

Right now, we finish SSL Mutual Authentication
