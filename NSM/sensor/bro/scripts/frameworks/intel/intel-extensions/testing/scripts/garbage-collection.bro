# @TEST-EXEC: btest-bg-run broproc bro %INPUT
# @TEST-EXEC: btest-bg-wait -k 10
# @TEST-EXEC: cat broproc/intel.log > output
# @TEST-EXEC: cat broproc/.stdout >> output
# @TEST-EXEC: TEST_DIFF_CANONIFIER="$SCRIPTS/diff-remove-timestamps" btest-diff output

# @TEST-START-FILE intel_expire.dat
#fields	indicator	indicator_type	meta.source	meta.desc	meta.expire
1.0.0.0	Intel::ADDR	source1	this host is bad	4
# @TEST-END-FILE

@load frameworks/communication/listen
@load item_expire

redef Intel::read_files += { "../intel_expire.dat" };
redef enum Intel::Where += { SOMEWHERE };
redef Intel::item_expiration = 2sec;
redef Intel::default_per_item_expiration = 4sec;
redef table_expire_interval = 1sec;

global runs = 0;

event do_it()
	{
	print fmt("Run %s (%s):", runs, network_time());
	switch (runs)
		{
		case 1:
			# Cause match and hit
			print "Trigger: 1.0.0.0";
			Intel::seen([$host=1.0.0.0,
			             $where=SOMEWHERE]);
			break;
		# Indicator should expire after 4secs
		# and definitely vanish after 6secs
		case 7:
			# Doesn't cause match nor hit
			print "Trigger: 1.0.0.0";
			Intel::seen([$host=1.0.0.0,
			             $where=SOMEWHERE]);
			break;
		}

	++runs;
	if ( runs < 8 )
		schedule 1sec { do_it() };
	}

event Intel::match(s: Intel::Seen, items: set[Intel::Item])
	{
	local t: time;
	for ( i in items )
		t = i$meta$last_match;
	print fmt("Match: %s Last hit: %s", s$indicator, t);
	# Note: The match event does not necessarily indicate a hit
	# in this case, as the per item timeout might be expired.
	}

hook Intel::single_item_expired(item: Intel::Item)
	{
	print fmt("Item expired: %s", item);
	# Trigger item deletion
	break;
	}

event bro_init() &priority=-10
	{
	schedule 1sec { do_it() };
	}
