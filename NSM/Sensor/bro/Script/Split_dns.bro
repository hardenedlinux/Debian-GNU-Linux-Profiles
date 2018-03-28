function dns_fuc(id: Log::ID. path: string, recL DNS::Info) : string
{
if ( rec?$qtype_name && rec$qtype_name == "NB") {
    return  "dns-netbios"
 }
 return "dns-minimal";
}      
event bro_init()
{
    log::remove_default_filter(DNS::LOG);
    log:add_filter(DNS::LOG, [$name="new-default",
    $include=set("ts","id.orig_h","query"),
    $bro_fuc]);
}