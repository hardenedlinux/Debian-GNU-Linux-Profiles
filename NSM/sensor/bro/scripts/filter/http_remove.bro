function filter_pred(rec: HTTP::Info): bool
{
if( ! rec?$referrer )
  return T;
  return F;
  }

event bro_init() &priority=-10
{
local filt = Log::get_filter(HTTP::LOG,"default");
filt$include = set("ts","uid","uri","user_agent","id.orig_h");
Log::add_filter(HTTP::LOG,filt);
}
