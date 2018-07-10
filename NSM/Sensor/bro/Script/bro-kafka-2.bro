@load $HOME/src/memetron-bro-plugin-kafka/Apache/Kafka/logs-to-kafka.bro
redef Kafka::topic_name = "";
redef Kafka::tag_json = T;

event bro_init()
  {
  # handles HTTP
  local http_filter: Log::Filter = [
$name = "kafka-http",
  $writer = Log::WRITER_KAFKAWRITER,
  $config = table(
["metadata.broker.list"] = "localhost:9092"
),
$path = "http"
];
Log::add_filter(HTTP::LOG, http_filter);

}