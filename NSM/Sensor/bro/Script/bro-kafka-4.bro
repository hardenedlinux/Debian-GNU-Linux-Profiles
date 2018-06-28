redef Kafka::kafka_conf = table( ["metadata.broker.list"] = "node1:6667"
, ["security.protocol"] = "SASL_PLAINTEXT"
, ["sasl.kerberos.keytab"] = "/etc/security/keytabs/metron.headless.keytab"
, ["sasl.kerberos.principal"] = "metron@EXAMPLE.COM"
);
redef Kafka::topic_name = "bro";
redef Kafka::tag_json = T;

event bro_init() &priority=-5
  {
  # handles HTTP
  Log::add_filter(HTTP::LOG, [
$name = "kafka-http",
  $writer = Log::WRITER_KAFKAWRITER,
  $pred(rec: HTTP::Info) = { return ! (( |rec$id$orig_h| == 128 || |rec$id$resp_h| == 128 )); },
  $config = table(
["metadata.broker.list"] = "localhost:9092"
)
]);
}