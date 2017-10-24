## Using FreeRADIUS with MySQL backend

#### OS: Debian 9.2

### Note: DO NOT USE Debian TESTING with FreeRADIUS 3.0.15

Install freeradius server (3.0.12) with openssl 1.1.0f 

```
apt update
apt install freeradius -y 
```

#### stop service

```
systemctl stop freeradius
```

#### Add user (files)
add user on top of `users` file

```
bob     Cleartext-Password := "hello"
        Reply-Message := "Hello, %{User-Name}"
```

#### Change default eap method

modify `/etc/freeradius/3.0/mods-enabled/eap`

```
eap {
        default_eap_type = peap

...
}
```

#### Add NAS(Network Access Server)

modify `/etc/freeradius/3.0/clients.conf`
add following content

```
client ruckus {
       ipaddr = 192.168.1.0/24
       secret = testing123
}
```

#### Run RADIUS server in debug mode

```
freeradius -X
```
using username "bob" and password "hello" to test EAP-PEAP
#### Mysql backend

After testing PEAP in iOS/Android/Windows we can try mysql backend

Install mysql and mysql modules for freeradius

```
apt install mysql-server freeradius-mysql -y
```
Create freeradius database
```
mysql -u root -p
mysql> CREATE DATABASE radius;
mysql> GRANT ALL ON radius.* TO radius@localhost IDENTIFIED BY "radpass";
```
Import schema
```
mysql -uroot -p radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql
```

##### Enable Mysql module

```
cd /etc/freeradius/3.0/mods-enabled
ln -s  ../mods-available/sql sql
```

modify mysql driver `/etc/freeradius/mods-enabled/sql`
```
sql {
        # The sub-module to use to execute queries. This should match
        # the database you're attempting to connect to.
        #
        #    * rlm_sql_mysql
        #    * rlm_sql_mssql
        #    * rlm_sql_oracle
        #    * rlm_sql_postgresql
        #    * rlm_sql_sqlite
        #    * rlm_sql_null (log queries to disk)
        #
        driver = "rlm_sql_mysql"

...
}
```
modify connection info `/etc/freeradius/mods-enabled/sql` 
```
sql {
...
        server = "localhost"
        port = 3306
        login = "radius"
        password = "radpass"
...
}
```


setting the backend in /etc/freeradius/site-enabled/default

```
authorize {
...
      sql

...
}
```

setting the backend in /etc/freeradius/site-enabled/inner-tunnel

```
authorize {
...
      sql

...
}
```

add user
```
mysql>insert into radcheck (username,attribute,op,value) VALUES ('mysqluser1','Cleartext-Password',':=','testpass');
INSERT INTO radusergroup VALUES ('mysqluser1','dynamic',1);
```

#### Autostart Service

```
systemctl enable freeradius
```


Reference:   
http://wiki.freeradius.org/guide/SQL-HOWTO   
http://linuxlasse.net/linux/howtos/Freeradius_and_MySQL   
