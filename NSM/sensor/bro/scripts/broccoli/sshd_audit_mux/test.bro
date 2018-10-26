# This script just has event handlers to echo the received events to stdout.

@load frameworks/communication/listen

redef Communication::nodes += {
    ["sshd_audit_server"] = [$host = 127.0.0.1, $events = /.*/, $connect=F, $ssl=F]
};

event auth_info_3(ts: time, version: string, sid: string, cid: count, authmsg: string, uid: string, meth: string, s_addr: addr, s_port: port, r_addr: addr, r_port: port)
	{
	print "auth_info_3", ts, version, sid, cid, authmsg, uid, meth, s_addr, s_port, r_addr, r_port;
	}

event auth_invalid_user_3(ts: time, version: string, sid: string, cid: count, uid: string)
	{
	print "auth_invalid_user_3", ts, version, sid, cid, uid;
	}

event auth_key_fingerprint_3(ts: time, version: string, sid: string, cid: count, fingerprint: string, key_type: string)
	{
	print "auth_key_fingerprint_3", ts, version, sid, cid, fingerprint, key_type;
	}

event auth_pass_attempt_3(ts: time, version: string, sid: string, cid: count, uid: string, password: string)
	{
	print "auth_pass_attempt_3", ts, version, sid, cid, uid, password;
	}

event channel_data_client_3(ts: time, version: string, sid: string, cid: count, channel:count, data:string)
	{
	print "channel_data_client_3", ts, version, sid, cid, channel, data;
	}

event channel_data_server_3(ts: time, version: string, sid: string, cid: count, channel:count, data:string)
	{
	print "channel_data_server_3", ts, version, sid, cid, channel, data;
	}

event channel_data_server_sum_3(ts: time, version: string, sid: string, cid: count, channel: count, bytes_skip: count)
	{
	print "channel_data_server_sum_3", ts, version, sid, cid, channel, bytes_skip;
	}

event channel_free_3(ts: time, version: string, sid: string, cid: count,channel: count, name: string)
	{
	print "channel_free_3", ts, version, sid, cid, channel, name;
	}

event channel_new_3(ts: time, version: string, sid: string, cid: count, found: count, ctype: count, name: string)
	{
	print "channel_new_3", ts, version, sid, cid, found, ctype, name;
	}

event channel_notty_analysis_disable_3(ts: time, version: string, sid: string, cid: count, channel: count, byte_skip: int, byte_sent: int)
	{
	print "channel_notty_analysis_disable_3", ts, version, sid, cid, channel, byte_skip, byte_sent;
	}

event channel_notty_client_data_3(ts: time, version: string, sid: string, cid: count, channel: count, data: string)
	{
	print "channel_notty_client_data_3", ts, version, sid, cid, channel, data;
	}

event channel_notty_server_data_3(ts: time, version: string, sid: string, cid: count, channel: count, data: string)
	{
	print "channel_notty_server_data_3", ts, version, sid, cid, channel, data;
	}

event channel_pass_skip_3(ts: time, version: string, sid: string, cid: count, channel: count)
	{
	print "channel_pass_skip_3", ts, version, sid, cid, channel;
	}

event channel_port_open_3(ts: time, version: string, sid: string, cid: count, channel: count, rtype: string, l_port: port, path: string, h_port: port, rem_host: string, rem_port: port)
	{
	print "channel_port_open_3", ts, version, sid, cid, channel, rtype, l_port, path, h_port, rem_host, rem_port;
	}

event channel_portfwd_req_3(ts: time, version: string, sid: string, cid: count, channel:count, host: string, fwd_port: count)
	{
	print "channel_portfwd_req_3", ts, version, sid, cid, channel, host, fwd_port;
	}

event channel_post_fwd_listener_3(ts: time, version: string, sid: string, cid: count, channel: count, l_port: port, path: string, h_port: port, rtype: string)
	{
	print "channel_post_fwd_listener_3", ts, version, sid, cid, channel, l_port, path, h_port, rtype;
	}

event channel_set_fwd_listener_3(ts: time, version: string, sid: string, cid: count, channel: count, c_type: count, wildcard: count, forward_host: string, l_port: port, h_port: port)
	{
	print "channel_set_fwd_listener_3", ts, version, sid, cid, channel, c_type, wildcard, forward_host, l_port, h_port;
	}

event channel_socks4_3(ts: time, version: string, sid: string, cid: count, channel: count, path: string, h_port: port, command: count, username: string)
	{
	print "channel_socks4_3", ts, version, sid, cid, channel, path, h_port, command, username;
	}

event channel_socks5_3(ts: time, version: string, sid: string, cid: count, channel: count, path: string, h_port: port, command: count)
	{
	print "channel_socks5_3", ts, version, sid, cid, channel, path, h_port, command;
	}

event session_channel_request_3(ts: time, version: string, sid: string, cid: count, pid: int, channel: count, rtype: string)
	{
	print "session_channel_request_3", ts, version, sid, cid, pid, channel, rtype;
	}

event session_do_auth_3(ts: time, version: string, sid: string, cid: count, atype: count, type_ret: count)
	{
	print "session_do_auth_3", ts, version, sid, cid, atype, type_ret;
	}

event session_exit_3(ts: time, version: string, sid: string, cid: count, channel: count, pid: count, ststus: count)
	{
	print "session_exit_3", ts, version, sid, cid, channel, pid, ststus;
	}

event session_input_channel_open_3(ts: time, version: string, sid: string, cid: count, tpe: count, ctype: string, rchan: int, rwindow: int, rmaxpack: int)
	{
	print "session_input_channel_open_3", ts, version, sid, cid, tpe, ctype, rchan, rwindow, rmaxpack;
	}

event session_new_3(ts: time, version: string, sid: string, cid: count, pid: int, ver: string)
	{
	print "session_new_3", ts, version, sid, cid, pid, ver;
	}

event session_remote_do_exec_3(ts: time, version: string, sid: string, cid: count, channel: count, ppid: count, command: string)
	{
	print "session_remote_do_exec_3", ts, version, sid, cid, channel, ppid, command;
	}

event session_remote_exec_no_pty_3(ts: time, version: string, sid: string, cid: count, channel: count, ppid: count, command: string)
	{
	print "session_remote_exec_no_pty_3", ts, version, sid, cid, channel, ppid, command;
	}

event session_remote_exec_pty_3(ts: time, version: string, sid: string, cid: count, channel: count, ppid: count, command: string)
	{
	print "session_remote_exec_pty_3", ts, version, sid, cid, channel, ppid, command;
	}

event session_request_direct_tcpip_3(ts: time, version: string, sid: string, cid: count, channel: count, originator: string, orig_port: port, target: string, target_port: port, i: count)
	{
	print "session_request_direct_tcpip_3", ts, version, sid, cid, channel, originator, orig_port, target, target_port, i;
	}

event session_tun_init_3(ts: time, version: string, sid: string, cid: count, channel: count, mode: count)
	{
	print "session_tun_init_3", ts, version, sid, cid, channel, mode;
	}

event session_x11fwd_3(ts: time, version: string, sid: string, cid: count, channel: count, display: string)
	{
	print "session_x11fwd_3", ts, version, sid, cid, channel, display;
	}

event sshd_connection_end_3(ts: time, version: string, sid: string, cid: count, r_addr: addr, r_port: port, l_addr: addr, l_port: port)
	{
	print "sshd_connection_end_3", ts, version, sid, cid, r_addr, r_port, l_addr, l_port;
	}

event sshd_connection_start_3(ts: time, version: string, sid: string, cid: count, int_list: string, r_addr: addr, r_port: port, l_addr: addr, l_port: port, i: count)
	{
	print "sshd_connection_start_3", ts, version, sid, cid, int_list, r_addr, r_port, l_addr, l_port, i;
	}

event sshd_exit_3(ts: time, version: string, sid: string, h: addr, p: port)
	{
	print "sshd_exit_3", ts, version, sid, h, p;
	}

event sshd_restart_3(ts: time, version: string, sid: string, h: addr, p: port)
	{
	print "sshd_restart_3", ts, version, sid, h, p;
	}

event sshd_server_heartbeat_3(ts: time, version: string, sid: string,  dt: count)
	{
	print "sshd_server_heartbeat_3", ts, version, sid, dt;
	}

event sshd_start_3(ts: time, version: string, sid: string, h: addr, p: port)
	{
	print "sshd_start_3", ts, version, sid, h, p;
	}

