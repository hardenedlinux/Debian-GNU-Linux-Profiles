global auth_failures = 0;

event ssh_auth_successful(c: connection, auth_method_none: bool)
  {
  print fmt("sucessful SSH session -%s", c$uid);
  }

event ssh_auth_failed(c:connection)
  {
  ++auth_failures;
  }

event connection_state_remove(c: connection) &priority=-5
  {
  if( ! c?$ssh){
    return;
    }
  if( !c$ssh$logged && c$ssh?$client && c$ssh?$server){
    print fmt("SSH: clinet =%s,server = %s", c$ssh$client, c$ssh$server);
    }
  }

event bro_done()
  {
  print fmt("SSH auth failures = %d", auth_failures);
  }