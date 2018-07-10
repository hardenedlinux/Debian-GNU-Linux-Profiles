@load packages/metron-bro-plugin-kafka/Apache/Kafka
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
