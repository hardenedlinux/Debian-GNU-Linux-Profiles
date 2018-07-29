event bro_init()
{
Log::remove_default_filter(DNS::LOG);
Log::add_filter(DNS::LOG, [$name="new-default",
$include=set("ts","id.orig_h","query")]);
}
