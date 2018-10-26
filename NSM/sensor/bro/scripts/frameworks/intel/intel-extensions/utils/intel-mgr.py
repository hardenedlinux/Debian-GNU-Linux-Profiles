#!/usr/bin/env python

from pybroker import *
from select import select
from argparse import ArgumentParser
from time import sleep

operations = (
	'query',
	'remove',
	'insert')

intel_types = (
	'ADDR',
	'SUBNET',
	'URL',
	'SOFTWARE',
	'EMAIL',
	'DOMAIN',
	'USER_NAME',
	'CERT_HASH',
	'PUBKEY_HASH')


def get_arguments():
	parser = ArgumentParser(description='This script allows to manage'
		' intelligence indicators of a Bro instance using broker.')
	parser.add_argument('operation', metavar='OPERATION', type=str.lower,
		choices=operations, help='Operation to execute')
	parser.add_argument('indicator', metavar='INDICATOR', type=str,
		help='Intel indicator')
	parser.add_argument('indicator_type', metavar='TYPE', type=str.upper,
		choices=intel_types, help='Intel indicator\'s type')
	parser.add_argument('-p', metavar='PORT', type=int, default=5012,
		dest='port', help='Broker port (default: 5012)')
	parser.add_argument('-a', metavar='IP', type=str, default='127.0.0.1',
		dest='host', help='Broker host (default: 127.0.0.1)')
	return parser.parse_args()


def main():
	args = get_arguments()
	op = args.operation

	ep_bro = endpoint("intel-client")
	ep_bro.peer(args.host, args.port)
	epq_bro = ep_bro.outgoing_connection_status()
	mq_bro = message_queue("bro/intel/{}".format(op), ep_bro)

	# Establish connection
	select([epq_bro.fd()],[],[])
	msgs = epq_bro.want_pop()
	for m in msgs:
		if m.status != outgoing_connection_status.tag_established:
			print("Failed to establish connection!")
			return

	# Send operation
	m = message([
		data("Intel::remote_{}".format(op)),
		data(args.indicator),
		data(args.indicator_type)])
	ep_bro.send("bro/intel/{}".format(op), m)
	print("Sent %s command for \"%s\" (%s)."
		% (op, args.indicator, args.indicator_type))

	# Await reply
	while True:
		select([mq_bro.fd()], [], [], 2)
		msgs = mq_bro.want_pop()

		if not msgs:
			print("Request timed out.");
			return;

		for m in msgs:
			print("debug: {}".format(m[0].as_string()))

			if m[0].as_string() == "Intel::remote_{}_reply".format(op):
				res = "Failed to {}".format(op)
				if m[1].as_bool():
					res = "Successfully executed {}".format(op);				
				indicator = m[2].as_string()
				print("{} \"{}\"".format(res, indicator))
				return;
			else:
				continue

if __name__ == '__main__':
	main()