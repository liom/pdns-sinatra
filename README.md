# Overview

Provides a REST interface for updating the domains and records tables of a Power DNS server using a MySQL backend. A successful registration of a domain name will require:
1) a domain record of type 'NATIVE'
2) an SOA record establishing the authority of the Power DNS server over that domain
3) additional records (eg. 'A', 'MX') to establish aliases and services the DNS server should report for the domain.

Two endpoints are provided for updating the record types:
* ```/api/domain/\[domain name\]```
* ```/api/record/\[domain name\]```

Both endpoints accept PUT and POST HTTP reqeusts. Both PUT and POST behave identically in this application: they will establish a new record when none exists, and will overwrite exsiting records on subsequent calls.

The domain endpoint accepts a JSON document containing a 'type' field. To establish a basic domain registration the type should be 'NATIVE'. eg:

```{ "type": "NATIVE" }```

The record endpoint accepts a JSON document in one of two formats, a multiple record format:
```{ "records": [
  ... array of records
    ]}```
or a single record format:
```{  "name":"foo.com",
      "type":"SOA",
      "content":"localhost admin@foo.com 1",
      "ttl":2000
    }```

# Usage

```
ruby domain-controller.rb [config_file [environment]]
```
### Arguments
config_file
: yaml file containing DB information for various environments (default: /etc/pdns/pdns-rest.yaml)

environment
: key to the envronment to use in the config_file (default: test)

# Configuration
1) Power DNS should be installed with the mysql adapter
2) A MySQL database should be created as described [here](http://doc.powerdns.com/configuring-db-connection.html#configuring-mysql)
3) A configuration file is required to set the database connection information. The configuration file should use the YAML format. It should be divided up into sections to identify configuration for the possible runtime environments (eg. development, test, prod). Below is an example of the configuration that should be provided for each environment:
```
test:
   db_name: pdns
   db_user: pdns
   db_pass: opensesame
   db_host: localhost
   port: 9000
```
An example configuration file (pdns-rest.yaml.example) is included in the root directory of this project.

# Testing
1) Install three additional gems:
  * mysql
  * rspec
  * autotest (optional)
2) Create a testing database named 'pdns_test', and a user with the login test/test. Create the same schems in this database as used in production (see Configuration above). ***Data will be destroyed between tests***