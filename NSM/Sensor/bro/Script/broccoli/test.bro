@load frameworks/communication/listen
redef Communication::listen_port = 47758/tcp;

redef Communication::nodes += {
	["broping"] = [$host = 127.0.0.1, $events = /test1/, $connect=F, $ssl=F]
};

event test1(a: int, b: count)
  {
  a=1;
  b=2;

  }

### Testing record types.

type rec: record {
  a: int;
  b: addr;
  };