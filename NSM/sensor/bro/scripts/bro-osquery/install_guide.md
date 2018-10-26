# Installation Guide #

## 1. Osquery

### Compile Osquery

The most recent osquery development required for bro-osquery is currently located in the [osquery fork by iBigQ](https://github.com/iBigQ/osquery). It is based on osquery version 3.2.6 and is upgraded to the latest osquery version when possible.

```
git clone --recursive https://github.com/iBigQ/osquery
cd osquery
make deps
./tools/provision.sh install osquery/osquery-local/caf
./tools/provision.sh install osquery/osquery-local/broker
SKIP_BRO=False make && sudo make install
```

This installation includes the latest development version of the communication library broker that comes with e.g. SSL support.

### Init Service
Optionally, please see the official [osquery documentation](http://http://osquery.readthedocs.io/en/stable/installation/install-linux/#running-osquery) on how to install osquery daemon as a service.

### Configuration File
You can specify the configuration options required for bro-osquery either on the command line or in the configuration file of osquery. Optionally, please see the official [osquery documentation](http://osquery.readthedocs.io/en/stable/deployment/configuration/#configuration-components) on how to write the configuration file. Possible options are as follows:

```json
{
  "options": {
    "disable_distributed": "false",
    "distributed_interval": "0",
    "distributed_plugin": "bro",

    "bro_ip": "192.168.137.1",
    "bro_port": "9999",

    "bro_groups": {
        "group1": "geo/de/hamburg",
        "group2": "orga/uhh/cs/iss"
    },

    "logger_plugin": "bro",
    "log_result_events": "false",

    "disable_events": "0",
    "disable_audit": "0",
    "audit_persist": "1",
    "audit_allow_config": "1",
    "audit_allow_sockets": "1"
  }
}
```

## 2. Bro

### Compile Bro and Dependencies

Build Bro from source to include the latest development features, including the new broker version.

```
git clone --recursive https://github.com/bro/bro
cd bro
./configure && make && sudo make install
```

### Osquery Framework

The Bro scripts have to be extended to be able to talk to osquery hosts. Please find the scripts in the [bro-osquery repository](https://github.com/bro/bro-osquery) repository in the folder named `osquery`.
To make the scripts available in Bro, either copy/link this folder into *$PREFIX/share/bro/site* (see [Bro manual](https://www.bro.org/sphinx/quickstart/index.html#bro-scripts)) or make the environment variable BROPATH to point to the framework folder (see [Bro manual](https://www.bro.org/sphinx/quickstart/index.html#telling-bro-which-scripts-to-load)).
