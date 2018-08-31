##! This script disables SYSLOG logging for flows destined to a SYSLOG server

module FilterSyslog;

export {

	const ignored_syslog_servers: set[addr] = { 10.1.1.1 } &redef; 

}

## This function returns False if the destination IP is in the list of
## ignored SYSLOG servers 

function filter_pred (rec: Syslog::Info) : bool
  {
  return rec$id$resp_h ! in ignored_syslog_servers;
  }

event bro_init()
  {
  Log::remove_default_filter(Syslog::LOG);
  local filter: Log::Filter = [$name="syslog-filter", $path="syslog", $pred=filter_pred];
  Log::add_filter(Syslog::LOG, filter);
  }