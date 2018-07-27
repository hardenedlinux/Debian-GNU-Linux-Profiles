
export {
  const config_tag_map: table[string] of Analyzer::Tag = {    
["AYIYA"]       = Analyzer::ANALYZER_AYIYA,    
["BITTORRENT"]  = Analyzer::ANALYZER_BITTORRENT,    
["DHCP"]         = Analyzer::ANALYZER_DHCP,    
["DNP3_TCP"]    = Analyzer::ANALYZER_DNP3_TCP,    
["DNS"]         = Analyzer::ANALYZER_DNS,    
["DTLS"]        = Analyzer::ANALYZER_DTLS,    
["FTP"]         = Analyzer::ANALYZER_FTP,    
["FTP_DATA"]    = Analyzer::ANALYZER_FTP,    
["GTPV1"]       = Analyzer::ANALYZER_GTPV1,    
["HTTP"]        = Analyzer::ANALYZER_HTTP,    
["IRC"]         = Analyzer::ANALYZER_IRC,    
["IRC_DATA"]    = Analyzer::ANALYZER_IRC_DATA,    
["KRB"]         = Analyzer::ANALYZER_KRB,    
["KRB_TCP"]     = Analyzer::ANALYZER_KRB_TCP,    
["MODBUS"]      = Analyzer::ANALYZER_MODBUS,    
["MYSQL"]       = Analyzer::ANALYZER_MYSQL,    
["NTP"]         = Analyzer::ANALYZER_NTP,    
["POP3"]        = Analyzer::ANALYZER_POP3,    
["RADIUS"]      = Analyzer::ANALYZER_RADIUS,    
["RDP"]         = Analyzer::ANALYZER_RDP,    
["SIP"]         = Analyzer::ANALYZER_SIP,    
["SMB"]         = Analyzer::ANALYZER_SMB,    
["SMTP"]        = Analyzer::ANALYZER_SMTP,    
["SNMP"]        = Analyzer::ANALYZER_SNMP,    
["SOCKS"]       = Analyzer::ANALYZER_SOCKS,    
["SSH"]         = Analyzer::ANALYZER_SSH,    
["SSL"]         = Analyzer::ANALYZER_SSL,    
["SYSLOG"]      = Analyzer::ANALYZER_SYSLOG,    
["TEREDO"]      = Analyzer::ANALYZER_TEREDO,  
};
const disablelist_filename = "./disableanalyzers.file" &redef;

type Val: record {
  protocol:string;
  };
}

event disable_analyzer_ev(description: Input::EventDescription, t: Input::Event, data: Val) {
  if (data$protocol !in config_tag_map){
    return;
    }
  Analyzer::disable_analyzer(config_tag_map[data$protocol]); 
}
event bro_init() {
  Input::add_event([$source=disablelist_filename, 
$name="disable_anaylyzer",
  $mode=Input::REREAD,
  $fields=Val, 
$ev=disable_analyzer_ev]);
}
