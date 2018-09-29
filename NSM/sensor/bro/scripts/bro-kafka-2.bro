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
local filt = Log::get_filter(HTTP::LOG,"default");
filt$include = set("ts","uid","uri","user_agent","id.orig_h");
# handles DNS
local dns_filter: Log::Filter = [
$name = "kafka-dns",
$writer = Log::WRITER_KAFKAWRITER,
$config = table(
["metadata.broker.list"] = "localhost:9092"
),
$path = "dns"
];
Log::remove_default_filter(DNS::LOG);
Log::add_filter(DNS::LOG, [$name="new-default",
$include=set("ts","id.orig_h","query")]);

#handles sysload
local sys_filter: Log::Filter = [
$name = "kafka-dns",
$writer = Log::WRITER_KAFKAWRITER,
$config = table(
["metadata.broker.list"] = "localhost:9092"
),
$path = "dns"
];
Log::remove_default_filter(Syslog::LOG);
local sys_filter: Log::Filter = [$name="syslog-filter", $path="syslog", $pred=filter_pred];
Log::add_filter(Syslog::LOG, sys_filter);
}