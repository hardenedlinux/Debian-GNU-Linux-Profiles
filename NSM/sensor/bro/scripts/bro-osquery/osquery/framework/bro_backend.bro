@load base/frameworks/broker
@load base/frameworks/logging

module osquery::bros;

export
{
    ## The osquery logging stream identifier.
    redef enum Log::ID += { LOG_SEND };

    ## Share subscription to an event with other bro nodes.
    ##
    ## q: The query to subscribe to.
    ## host_list: Specific hosts to address per query (optional).
    ## group_list: Specific groups to address per query (optional).
    global share_subscription: function(q: osquery::Query, host_list: vector of string &default=vector(""), group_list: vector of string &default=vector(""));

    ## Revoke sharing of subscription to an events.
    ##
    ## q: The query to revoke.
    ## host_list: Specific hosts to address per query (optional).
    ## group_list: Specific groups to address per query (optional).
    global unshare_subscription: function(q: osquery::Query, host_list: vector of string &default=vector(""), group_list: vector of string &default=vector(""));

    ## Share a one-time query to all currently connected clients.
    ##
    ##
    ## q: The query to execute.
    ## host_list: Specific hosts to address per query (optional).
    ## group_list: Specific groups to address per query (optional).
    global share_execution: function(q: osquery::Query, host_list: vector of string &default=vector(""), group_list: vector of string &default=vector(""));

    ## Share a grouping for organizing hosts in groups.
    ##
    ## range_list: the subnets that are addressed.
    ## group: the group hosts should join.
    global share_grouping: function(range_list: vector of subnet, group: string);

    ## Revoke sharing a grouping for organizing hosts in groups.
    ##
    ## range_list: the subnets that are addressed.
    ## group: the group hosts should leave.
    global unshare_grouping: function(range_list: vector of subnet, group: string);
}

global bro_new: event(peer_name: string, bro_id: string, init: bool);

# Sent to share subscribing to an event.
global bro_subscribe: event(group_flood: bool, via_peer_id: string, q: osquery::Query, host_list: vector of string, group_list: vector of string);

# Sent to revoke subscribing to an event.
global bro_unsubscribe: event(group_flood: bool, via_peer_id: string, q: osquery::Query, host_list: vector of string, group_list: vector of string);

# Sent to share one-time query execution.
global bro_execute: event(group_flood: bool, via_peer_id: string, q: osquery::Query, host_list: vector of string, group_list: vector of string);

# Sent to share groupings hosts for join a group.
global bro_join: event(group_flood: bool, via_peer_id: string, range_list: vector of subnet, group: string);

# Sent by us to hosts for leaving a group.
global bro_leave: event(group_flood: bool, via_peer_id: string, range_list: vector of subnet, group: string);

# Internal table for tracking incoming subscriptions from remote
global bro_subscriptions: table[string] of vector of osquery::hosts::Subscription;

# Internal table for tracking incoming assignments from remote
global bro_groupings: table[string] of vector of osquery::hosts::Grouping;

# Internal mapping of broker id (peer_name) to osqueryid (host_id)
global peer_to_bro: table[string] of string;

function delete_bro_subscription(query: osquery::Query)
{
  local peer_name: string = fmt("%s", Broker::node_id());
  local found: int = -1;
  # Find idx to delete
  for (idx in bro_subscriptions[peer_name])
  {
    if (osquery::same_event(bro_subscriptions[peer_name][idx]$query, query))
    {
      found = idx;
      break;
    }
  }
  if (idx == -1)
  {
    # TODO Log
    return;
  }

  # New vector of new size
  local new_subscriptions: vector of osquery::hosts::Subscription;
  for (idx in bro_subscriptions[peer_name])
  {
    if (idx == found) next;
    
    new_subscriptions[|new_subscriptions|] = bro_subscriptions[peer_name][idx];
  }
  bro_subscriptions[peer_name] = new_subscriptions;
}

function delete_bro_grouping(group: string)
{
  local peer_name: string = fmt("%s", Broker::node_id());
  local found: int = -1;
  # Find idx to delete
  for (idx in bro_groupings[peer_name])
  {
    if (bro_groupings[peer_name][idx]$group == group)
    {
      found = idx;
      break;
    }
  }
  if (idx == -1)
  {
    # TODO Log
    return;
  }

  # New vector of new size
  local new_groupings: vector of osquery::hosts::Grouping;
  for (idx in bro_groupings[peer_name])
  {
    if (idx == found) next;
    
    new_groupings[|new_groupings|] = bro_groupings[peer_name][idx];
  }
  bro_groupings[peer_name] = new_groupings;
}

function send_subscription(topic: string, ev: any, group_flood: bool, q: osquery::Query, host_list: vector of string &default=vector(""), group_list: vector of string &default=vector(""))
{
  local ev_name = split_string(fmt("%s", ev), /\n/)[0];
  osquery::log_osquery("debug", topic, fmt("%s event %s() for query '%s'", "Forwarding", ev_name, q$query), LOG_SEND);
  
  local ev_args = Broker::make_event(ev, group_flood, fmt("%s",Broker::node_id()), q, host_list, group_list);
  Broker::publish(topic, ev_args);
}

function send_grouping(topic: string, ev: any, group_flood: bool, range_list: vector of subnet, group: string)
{
  local ev_name = split_string(fmt("%s", ev), /\n/)[0];
  osquery::log_osquery("debug", topic, fmt("%s event %s() for group '%s'", "Forwarding", ev_name, group), LOG_SEND);
  
  local ev_args = Broker::make_event(ev, group_flood, fmt("%s",Broker::node_id()), range_list, group);
  Broker::publish(topic, ev_args);
}

function share_subscription(q: osquery::Query, host_list: vector of string &default=vector(""), group_list: vector of string &default=vector(""))
{
  local peer_name: string = fmt("%s", Broker::node_id());
  if (peer_name !in bro_subscriptions) bro_subscriptions[peer_name] = vector();
  bro_subscriptions[peer_name][|bro_subscriptions[peer_name]|] = [$query=q, $hosts=host_list, $groups=group_list];
  send_subscription(osquery::BroBroadcastTopic, bro_subscribe, T, q, host_list, group_list);
}

function unshare_subscription(q: osquery::Query, host_list: vector of string &default=vector(""), group_list: vector of string &default=vector(""))
{
  delete_bro_subscription(q);
  send_subscription(osquery::BroBroadcastTopic, bro_unsubscribe, T, q, host_list, group_list);
}

function share_execution(q: osquery::Query, host_list: vector of string &default=vector(""), group_list: vector of string &default=vector(""))
{
  send_subscription(osquery::BroBroadcastTopic, bro_execute, T, q, host_list, group_list);
}

function share_grouping(range_list: vector of subnet, group: string)
{
  local peer_name: string = fmt("%s", Broker::node_id());
  if (peer_name !in bro_groupings) bro_groupings[peer_name] = vector();
  bro_groupings[peer_name][|bro_groupings[peer_name]|] = [$group=group, $ranges=range_list];
  send_grouping(osquery::BroBroadcastTopic, bro_join, T, range_list, group);
}

function unshare_grouping(range_list: vector of subnet, group: string)
{
  delete_bro_grouping(group);
  send_grouping(osquery::BroBroadcastTopic, bro_leave, T, range_list, group);
}

event bro_subscribe(group_flood: bool, via_peer_id: string, q: osquery::Query, host_list: vector of string, group_list: vector of string)
{
  # Keep state about the direction the subscription came from
  local topic: string;
  if (via_peer_id !in bro_subscriptions)
  {
    topic = fmt("%s/%s", osquery::BroIndividualTopic, via_peer_id);
    osquery::log_bro("warning", topic, fmt("Unexpected event %s from unkown Bro for query %s", "bro_subscribe", q$query));
    return;
  }
  osquery::hosts::insert_subscription(q, host_list, group_list);
  bro_subscriptions[via_peer_id][|bro_subscriptions[via_peer_id]|] = [$query=q, $hosts=host_list, $groups=group_list];

  # Group Flooding will be done automatically in Broker
  if (group_flood == T) return;

  # Forward subscription manually to all other neighbors
  local peer_name: string;
  for (peer_name in peer_to_bro)
  {
    if (peer_name == via_peer_id) next;
    
    topic = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
    send_subscription(topic, bro_subscribe, F, q, host_list, group_list);
  }
}

event bro_unsubscribe(group_flood: bool, via_peer_id: string, q: osquery::Query, host_list: vector of string, group_list: vector of string)
{
  # Remove state about the direction the subscription came from
  local topic: string;
  if (via_peer_id !in bro_subscriptions)
  {
    topic = fmt("%s/%s", osquery::BroIndividualTopic, via_peer_id);
    osquery::log_bro("warning", topic, fmt("Unexpected event %s from unkown Bro for query %s", "bro_unsubscribe", q$query));
    return;
  }
  osquery::hosts::remove_subscription(q, host_list, group_list);
  delete_bro_subscription(q);

  # Group Flooding will be done automatically in Broker
  if (group_flood == T) return;

  # Forward unsubscription manually to all other neighbors
  local peer_name: string;
  for (peer_name in peer_to_bro)
  {
    if (peer_name == via_peer_id) next;
    
    topic = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
    send_subscription(topic, bro_unsubscribe, F, q, host_list, group_list);
  }
}

event bro_execute(group_flood: bool, via_peer_id: string, q: osquery::Query, host_list: vector of string, group_list: vector of string)
{
  # Apply execution locally
  osquery::hosts::insert_execution(q, host_list, group_list);

  # Group Flooding will be done automatically in Broker
  if (group_flood == T) return;

  # Forward subscription manually to all other neighbors
  local peer_name: string;
  for (peer_name in peer_to_bro)
  {
    if (peer_name == via_peer_id) next;
    
    local topic: string = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
    send_subscription(topic, bro_subscribe, F, q, host_list, group_list);
  }
}

event bro_join(group_flood: bool, via_peer_id: string, range_list: vector of subnet, group: string)
{
  # Keep state about the direction the subscription came from
  local topic: string;
  if (via_peer_id !in bro_groupings)
  {
    topic = fmt("%s/%s", osquery::BroIndividualTopic, via_peer_id);
    osquery::log_bro("warning", topic, fmt("Unexpected event %s from unkown Bro for group %s", "bro_join", group));
    return;
  }
  osquery::hosts::insert_grouping(range_list, group);
  bro_groupings[via_peer_id][|bro_groupings[via_peer_id]|] = [$group=group, $ranges=range_list];

  # Group Flooding will be done automatically in Broker
  if (group_flood == T) return;

  # Forward grouping manually to all other neighbors
  local peer_name: string;
  for (peer_name in peer_to_bro)
  {
    if (peer_name == via_peer_id) next;
    
    topic = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
    send_grouping(topic, bro_join, F, range_list, group);
  }
}

event bro_leave(group_flood: bool, via_peer_id: string, range_list: vector of subnet, group: string)
{
  # Remove state about the direction the subscription came from
  local topic: string;
  if (via_peer_id !in bro_groupings)
  {
    topic = fmt("%s/%s", osquery::BroIndividualTopic, via_peer_id);
    osquery::log_bro("warning", topic, fmt("Unexpected event %s from unkown Bro for group %s", "bro_leave", group));
    return;
  }
  osquery::hosts::remove_grouping(range_list, group);
  delete_bro_grouping(group);

  # Group Flooding will be done automatically in Broker
  if (group_flood == T) return;

  # Forward grouping manually to all other neighbors
  local peer_name: string;
  for (peer_name in peer_to_bro)
  {
    if (peer_name == via_peer_id) next;
    
    topic = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
    send_grouping(topic, bro_leave, F, range_list, group);
  }
}

event bro_new(peer_name: string, bro_id: string, init: bool)
{
  osquery::log_osquery("info", bro_id, fmt("Osquery host connected (announced as %s)", peer_name));
  local topic = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
  local p_name: string;

  # Bro already known?
  if (peer_name in peer_to_bro)
  {
    local topic_from = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
    osquery::log_bro("warning", topic_from, fmt("Peer %s with ID %s already known as Bro", peer_name, bro_id));
  }

  # Internal client tracking
  peer_to_bro[peer_name] = bro_id;
  bro_subscriptions[peer_name] = vector();
  bro_groupings[peer_name] = vector();

  # Also announce back to retrieve their state
  if (init == T) {
    local ev_args = Broker::make_event(bro_new, fmt("%s",Broker::node_id()), osquery::BroID_Topic, F);
    Broker::publish(topic, ev_args);
  }
  
  # Send own subscriptions
  local s: osquery::hosts::Subscription;
  for (p_name in bro_subscriptions)
  {
    if (p_name == peer_name) next;

    for (i in bro_subscriptions[p_name])
    {
      s = bro_subscriptions[p_name][i];
      send_subscription(topic, bro_subscribe, F, s$query, s$hosts, s$groups);
    }
  }

  # Send own groupings
  local g: osquery::hosts::Grouping;
  for (p_name in bro_groupings)
  {
    if (p_name == peer_name) next;

    for (i in bro_groupings[p_name])
    {
      g = bro_groupings[p_name][i];
      send_grouping(topic, bro_join, F, g$ranges, g$group);
    }
  }

  # raise event for new bro
  event osquery::bro_connected(bro_id);
}

function revoke_subscriptions(peer_name: string, disconnected: bool &default=T)
{
  local s: osquery::hosts::Subscription;
  for (i in bro_subscriptions[peer_name])
  {
    s = bro_subscriptions[peer_name][i];

    # Remove locally
    osquery::hosts::remove_subscription(s$query, s$hosts, s$groups);
    
    # Generate unsubscribe caused by disconnect
    if (disconnected)
    {
      # Safe to flood the unsubscribe
      local topic: string = osquery::BroBroadcastTopic;
      send_subscription(topic, bro_unsubscribe, T, s$query, s$hosts, s$groups);
    } else
    {
      # TODO: Remove manually by individual messages to other neighbors
    }
  }

  # Remove State
  local s_list: vector of osquery::hosts::Subscription;
  bro_subscriptions[peer_name] = s_list;
}

function revoke_groupings(peer_name: string, disconnected: bool &default=T)
{
  local g: osquery::hosts::Grouping;
  for (i in bro_groupings[peer_name])
  {
    g = bro_groupings[peer_name][i];

    # Remove locally
    osquery::hosts::remove_grouping(g$ranges, g$group);
    
    # Generate unsubscribe caused by disconnect
    if (disconnected)
    {
      # Safe to flood the unsubscribe
      local topic: string = osquery::BroBroadcastTopic;
      send_grouping(topic, bro_leave, T, g$ranges, g$group);
    } else
    {
      # TODO: Remove manually by individual messages to other neighbors
    }
  }

  # Remove State
  local g_list: vector of osquery::hosts::Grouping;
  bro_groupings[peer_name] = g_list;
}

event Broker::peer_added(endpoint: Broker::EndpointInfo, msg: string)
{
  # Only for outgoing connections
  if (msg != "received handshake from remote core") return;

  local peer_name: string = {endpoint$id};
  local topic: string = fmt("%s/%s", osquery::BroIndividualTopic, peer_name);
  
  # Send announce message to the remote peer
  local ev_args = Broker::make_event(bro_new, fmt("%s",Broker::node_id()), osquery::BroID_Topic, T);
  Broker::publish(topic, ev_args);
}

event Broker::peer_removed(endpoint: Broker::EndpointInfo, msg: string)
{
  local peer_name: string = {endpoint$id};
  if (peer_name !in bro_subscriptions) return;

  local bro_id: string = peer_to_bro[peer_name];
  osquery::log_osquery("info", bro_id, "Bro disconnected");

  # Revoke all subscriptions that came in via this peer
  revoke_subscriptions(peer_name);
  revoke_groupings(peer_name);
  delete bro_subscriptions[peer_name];
  delete bro_groupings[peer_name];
  delete peer_to_bro[peer_name];
  
  # raise event for disconnected bro
  event osquery::bro_disconnected(bro_id);
}

event Broker::peer_lost(endpoint: Broker::EndpointInfo, msg: string)
{
  local peer_name: string = {endpoint$id};
  if (peer_name !in bro_subscriptions) return;

  local bro_id: string = peer_to_bro[peer_name];
  osquery::log_osquery("info", bro_id, "Bro disconnected");

  # Revoke all subscriptions that came in via this peer
  revoke_subscriptions(peer_name);
  revoke_groupings(peer_name);
  delete bro_subscriptions[peer_name];
  delete bro_groupings[peer_name];
  delete peer_to_bro[peer_name];
  
  # raise event for disconnected bro
  event osquery::bro_disconnected(bro_id);
}

event bro_init()
{
  Log::create_stream(LOG_SEND, [$columns=osquery::Info, $path="osquery_bros"]);
  
  # Listen on Bro announce topic
  local topic: string = osquery::BroAnnounceTopic;
  osquery::log_local("info", fmt("Subscribing to bro announce topic %s", topic));
  Broker::subscribe(topic);

  # Listen on Bro individual topic
  topic = fmt("%s/%s", osquery::BroIndividualTopic, Broker::node_id());
  osquery::log_local("info", fmt("Subscribing to bro individual topic %s", topic));
  Broker::subscribe(topic);

  # Connect to remote Bro
  if (|osquery::remote_ip| != 0 && osquery::remote_ip != "0.0.0.0") {
    Broker::peer(osquery::remote_ip, osquery::remote_port, 10sec);
  }
}
