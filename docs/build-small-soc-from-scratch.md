## Using Logstash/Elasticsearch/Grafana to build a small SOC(Security Operation Center) from scratch



### Scenario: Detecting SSH Server brute-force

When you build a server on the Internet, a brute-force attack you can never avoid. We can use some combination to show this kind of threats.

#### Indexing

Using elasticsearch to indexing is a easy way to getting start

Download it from [https://www.elastic.co/downloads/elasticsearch](https://www.elastic.co/downloads/logstash)

Unpack it and run it foreground(for debug purpose)

`$ ./elasticsearch`

#### Collecting logs

First choice for collecting syslog and filtering and send it to elasticsearch is logstash, as known as the "L" in ELK

Download it from [https://www.elastic.co/downloads/logstash](https://www.elastic.co/downloads/logstash)

Unpack it and running foreground(for debug purpose)

`$ ./logstash -f <your configuration file>`

sshd.conf

```
input {
  file {
    path => [ "/var/log/auth.log" ]
    type => [ "auth"]
    start_position => "beginning"
  }
}
filter {
        if [type] == 'auth' {
                #grok { match => { 'message' => '%{SYSLOGTIMESTAMP:timestamp} %{HOSTNAME} %{WORD:program}%{GREEDYDATA:msgsplit}' }
                grok { match => { 'message' => '%{SYSLOGBASE}%{GREEDYDATA:msgsplit}' }
                }

                # SSH successful password login
                if "grokked" not in [tags] and "sshd" == [program] {
                        grok { match => [ "msgsplit", "[%{BASE10NUM}]: Accepted password for %{USERNAME:user} from %{IP:src_ip} port %{BASE10NUM}\s+ssh%{BASE10NUM}" ]
                        add_tag => [ "ssh_successful_login", "grokked" ]
                        tag_on_failure => [ ]
                        }
                }

                # SSH failed password login type 1
                if "grokked" not in [tags] and "sshd" == [program] {
                        grok { match => [
                                "msgsplit", "\[%{BASE10NUM}\]: Failed password for %{USERNAME:user} from %{IP:src_ip} port %{BASE10NUM}\s+ssh%{BASE10NUM}",
                                "msgsplit", "Too many authentication failures for %{USERNAME:user} from %{IP:src_ip} port %{BASE10NUM}\s+ssh%{BASE10NUM}",
                                "msgsplit", "Invalid user %{USERNAME:user} from %{IP:src_ip}"
                                ]
                        add_tag => [ "ssh_failed_login", "grokked" ]
                        tag_on_failure => [ ]
                        }
                }

                # SSH Brute force attemp
                if "grokked" not in [tags] and "sshd" == [program] {
                        grok { match => [ "msgsplit", "[%{BASE10NUM}]: Failed password for invalid user %{USERNAME:user} from %{IP:src_ip} port %{BASE10NUM}\s+ssh%{BASE10NUM}" ]
                        add_tag => [ "ssh_brute_force", "grokked" ]
                        tag_on_failure => [ ]
                        }
                }

                # Remove excess data
                if "grokked" in [tags] and "sshd" == [program]{
                        mutate {
                        remove_field => [ "message", "fields", "input_type", "offset", "source", "program", "msgsplit" ]
                        remove_tag => [ "beats_input_codec_plain_applied" ]
                        }
                }

        } #End if[type] == "auth"

	#Change syslog time format to valid time format for elasticsearch
        date {
                match => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
                target => "@timestamp"
        }
} # End Filter

output {
   #Output to  stdout, usualy for debug purpose
    stdout {
        codec => rubydebug
        }
}

output {
  elasticsearch {
    hosts => ["127.0.0.1:9200"]
    index => "logstash-%{+YYYY.MM}"
  }
}

```

This script is copy and modify from https://discuss.elastic.co/t/grok-with-conditional-patterns-and-adding-a-tag/43844/3

NOTE:
SSH Server should disable PAM authentication by setting `Use PAM` to `no` in `/etc/ssh/sshd_config`, otherwise they have different output in auth.log
sshd daemon should using "-D" option only, and should not using "-e", and setting `SyslogFacility AUTH` and `LogLevel INFO` in /etc/ssh/sshd_config   


#### Using Kibana for debugging the Lucene query

Kibana has a powerful panel call "Discover", we can debug the query in this panel.

Download it from [https://www.elastic.co/downloads/kibana](https://www.elastic.co/downloads/kibana)

Unpack it and run it foreground(for debug purpose)

`$ ./kibana`

Enter the url of kibana in your browser

`http://localhost:5601/`

Go to Management page and add new `Index Patterns`, in the configuration logstash we setting index pattern in "logstash-%{+YYYY.MM}", so we can using logstash-*

Offcial Docs: https://www.elastic.co/guide/en/kibana/current/tutorial-define-index.htm

Using Discover panel to debug the query

*(unfinished)*
