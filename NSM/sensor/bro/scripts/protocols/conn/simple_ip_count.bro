global local_subnets: set[subnet] = {


172,16.0.0/20


};
global inside_networks: set[addr];
global outside_networks: set[addr];

event new_connection(c: connection)
  {

  ++my_count;
  if ( my_count <= 10) {
    print fmt("The connection %s from %s on port %s to %s on port %s started at %s.",c$uid, c$id$orig_h, c$id$orig_p, c$id$resp_h, c$id$resp_p, strftime("%D %H %M", c$start_time));
    }

  if ( c$id$orig_h in local_subnets ) {
    add inside_networks[c$id$orig_h];
    }

  if( c$id$resp_h !in local_subnets ) {
    add outside_networks[c$id$resp_h];
    }
  }


event connection_state_remove(c: connection)
  {

  }


event bro_done()
  {
  for ( ip in inside_networks)  {
    print ip;
    }

  print fmt ("Total connection %d", my_count);
  }