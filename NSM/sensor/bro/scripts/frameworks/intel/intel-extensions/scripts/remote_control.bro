##! This script allows to remove intelligence items using broker.

module Intel;

export {
	## Broker port.
	const broker_port = 5012/tcp &redef;
	## Broker bind address.
	const broker_addr = 127.0.0.1 &redef;

	## Event to raise for intel item query.
	global remote_query: event(indicator: string, indicator_type: string);
	## Event to raise for intel item removal.
	global remote_remove: event(indicator: string, indicator_type: string);
	## Event to raise for intel item insertion.
	global remote_insert: event(indicator: string, indicator_type: string);
}

global remote_query_reply: event(success: bool, indicator: string);
global remote_remove_reply: event(success: bool, indicator: string);
global remote_insert_reply: event(success: bool, indicator: string);

redef enum Where += {
	# Location used for lookups from remote
	Intel::REMOTE,
};

global type_tbl: table[string] of Type = {
		["ADDR"] = ADDR,
		["SUBNET"] = SUBNET,
		["URL"] = URL,
		["SOFTWARE"] = SOFTWARE,
		["EMAIL"] = EMAIL,
		["DOMAIN"] = DOMAIN,
		["USER_NAME"] = USER_NAME,
		["CERT_HASH"] = CERT_HASH,
		["PUBKEY_HASH"] = PUBKEY_HASH,
};

function compose_seen(indicator: string, indicator_type: Type): Seen
	{
	local res: Seen = [
		$indicator      = indicator,
		$indicator_type = indicator_type,
		$where          = Intel::REMOTE
	];
	
	if ( indicator_type == ADDR )
		{
		res$host = to_addr(indicator);
		}
	
	return res;
	}

function compose_item(indicator: string, indicator_type: Type): Item
	{
	local res: Item = [
		$indicator      = indicator,
		$indicator_type = indicator_type,
		$meta = record(
			$source	= "intel-remote"
		)
	];

	return res;
	}

event bro_init()
	{
	Broker::enable();
	Broker::subscribe_to_events("bro/intel/");
	Broker::listen(broker_port, fmt("%s", broker_addr));
	}

event Intel::remote_query(indicator: string, indicator_type: string)
	{
	local s = compose_seen(indicator, type_tbl[indicator_type]);
	# Lookup indicator and return result
	local evt = Broker::event_args(remote_query_reply, find(s), indicator);
	Broker::send_event("bro/intel/query", evt);
	}

event Intel::remote_remove(indicator: string, indicator_type: string)
	{
	local item = compose_item(indicator, type_tbl[indicator_type]);
	remove(item, T);
	# Always indicate success
	local evt = Broker::event_args(remote_remove_reply, T, indicator);
	Broker::send_event("bro/intel/remove", evt);
	}

event Intel::remote_insert(indicator: string, indicator_type: string)
	{
	local item = compose_item(indicator, type_tbl[indicator_type]);
	insert(item);
	# Always indicate success
	local evt = Broker::event_args(remote_insert_reply, T, indicator);
	Broker::send_event("bro/intel/insert", evt);
	}
