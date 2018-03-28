@load Bro/Kafka/logs-to-kafka.bro
redef Kafka::topic_name = "";
redef Kafka::logs_to_send = set(Conn::LOG, HTTP::LOG, DNS::LOG, SMTP::LOG , SSL::LOG);
redef Kafka::kafka_conf = table(["metadata.broker.list"] = "localhost:9092");