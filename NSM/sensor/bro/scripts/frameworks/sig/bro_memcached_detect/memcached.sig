# sig to detect memcached DDOS 
#
# the retreval command is :
#   get <key>*\r\n
#   gets <key>*\r\n
#

signature tcp-mcd {
  ip-proto == tcp
  dst-port == 11211
  payload /^[gG][eE][tT].*|^/
  event "memcached_tcp_match"
}

signature udp-mcd {
  ip-proto == udp
  dst-port == 11211
  payload /^[gG][eE][tT].*|^/
  event "memcached_udp_match"
}

