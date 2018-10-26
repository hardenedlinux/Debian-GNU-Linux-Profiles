#! Logs user connection activity.

module osquery::user_connection_events;

export {
    redef enum Log::ID += { LOG };

    type Info: record {
        t: time &log;
        host: string &log;
        action: string &log;
        local_address: addr &log;
        local_port: int &log;
        remote_address: addr &log;
        remote_port: int &log;
        pid: int &log;
        path: string &log;
        cmdline: string &log;
        uid: int &log;
        username: string &log;
    };

    const cache_size: int = 1000 &redef;
}

# Add user fields to the connection log record.
redef record Conn::Info += {
    # Process info on the originating system
    orig_pid: int &optional &log;
    orig_path: string &optional &log;
    orig_user: string &optional &log;
    # Process info on the responsive system
    resp_pid: int &optional &log;
    resp_path: string &optional &log;
    resp_user: string &optional &log;
};

# Info about process and user
type ProcessInfo: record {
    c: count &optional;
    # Process ID
    pid: int &optional; 
    # Binary Path
    path: string &optional;
    # Command
    cmdline: string &optional;
    # User ID
    uid: int &optional;
    # Username
    username: string &optional;
};

# Info about the connection of a socket
type SocketInfo: record {
    action: string &optional;
    pid: int &optional;
    # IPs
    srcIP: string &optional;
    dstIP: string &optional;
    # Ports
    srcPort: int &optional;
    dstPort: int &optional;
    path: string &optional;
};

# 
global user_cache: table[string] of table[int] of string;
global process_cache: table[string] of table[int] of ProcessInfo;
global socket_cache: table[string] of table[int] of vector of SocketInfo;

# Maps connection to user
global bind_cache: table[string] of table[addr, count] of ProcessInfo;
global connect_cache: table[string] of table[addr, count] of ProcessInfo;

function same_process_info(pi1: ProcessInfo, pi2: ProcessInfo): bool
{
   if ((pi1?$pid != pi2?$pid) || (pi1?$pid && pi1$pid != pi2$pid) )
     return F;
   if ((pi1?$path != pi2?$path) || (pi1?$path && pi1$path != pi2$path) )
     return F;
   if ((pi1?$cmdline != pi2?$cmdline) || (pi1?$cmdline && pi1$cmdline != pi2$cmdline) )
     return F;
   if ((pi1?$uid != pi2?$uid) || (pi1?$uid && pi1$uid != pi2$uid) )
     return F;
   if ((pi1?$username != pi2?$username) || (pi1?$username && pi1$username != pi2$username) )
     return F;

   return T;
}

function add_process_socket_info(orig: bool, host_id: string, local_address: string, local_port: int, remote_address: string, remote_port: int, pid: int, path: string, username: string): bool
{
    # TODO: Add a maximum cache size. How to chose 'old' entries that should be replaced?
    local pi: ProcessInfo = [$c = 1, $pid = pid, $path = path, $username = username];
    local pi_exist = F;
    local existing_pi: ProcessInfo;

    # Binding events
    if (orig == F) {
        #print(fmt("Adding '%s' for bind on host %s (%s:%d -> %s:%d)", username, host_id, local_address, local_port, remote_address, remote_port));

        # Check for duplicate infos
        if (host_id in bind_cache && [to_addr(local_address), int_to_count(local_port)] in bind_cache[host_id]) {
            pi_exist = T;
            existing_pi = bind_cache[host_id][to_addr(local_address), int_to_count(local_port)];
        }

        if (pi_exist && same_process_info(pi, existing_pi)) {
            existing_pi$c = existing_pi$c + 1;
        }
        else if (host_id !in bind_cache) {
            local t: table[addr, count] of ProcessInfo = {[to_addr(local_address), int_to_count(local_port)] = pi};
            bind_cache[host_id] = t;
        }
        else {
            bind_cache[host_id][to_addr(local_address), int_to_count(local_port)] = pi;
        }

    # Connect events
    } else {
        #print(fmt("Adding '%s' for connect on host %s (%s:%d -> %s:%d)", username, host_id, local_address, local_port, remote_address, remote_port));

        # Check for duplicate infos
        if (host_id in connect_cache && [to_addr(remote_address), int_to_count(remote_port)] in connect_cache[host_id]) {
            pi_exist = T;
            existing_pi = connect_cache[host_id][to_addr(remote_address), int_to_count(remote_port)];
        }

        if (pi_exist && same_process_info(pi, existing_pi)) {
            existing_pi$c = existing_pi$c + 1;
        }
        else if (host_id !in connect_cache) { 
            local t2: table[addr, count] of ProcessInfo = {[to_addr(remote_address), int_to_count(remote_port)] = pi};
            connect_cache[host_id] = t2;
        }
        else {
            connect_cache[host_id][to_addr(remote_address), int_to_count(remote_port)] = pi;
        }
    }
    return T;
}

function extend_connection_info(c: connection): bool
{
    # Check the origin of the connection
    # - Get list of hosts with this source IP
    local srcHost_infos = osquery::hosts::getHostInfosByAddress(c$conn$id$orig_h);
    # - Get list of hosts with this target IP
    local dstHost_infos = osquery::hosts::getHostInfosByAddress(c$conn$id$resp_h);

    if (|srcHost_infos| + |dstHost_infos| == 0)
    {
        #print(fmt("No osquery host found for connection (%s:%s -> %s:%s) ", c$conn$id$orig_h, c$conn$id$orig_p, c$conn$id$resp_h, c$conn$id$resp_p));
        return F;
    }

    # - Lookup if any of the source candidates connected to the target
    for (host_info_idx in srcHost_infos) {
        local host_id = srcHost_infos[host_info_idx]$host;
        
        if (host_id !in connect_cache) { next; }
        if ([c$conn$id$resp_h, port_to_count(c$conn$id$resp_p)] !in connect_cache[host_id]) { next; }
        
        local process_info = connect_cache[host_id][c$conn$id$resp_h, port_to_count(c$conn$id$resp_p)];
        if (process_info?$pid)
            c$conn$orig_pid = process_info$pid;
        if (process_info?$path)
            c$conn$orig_path = process_info$path;
        if (process_info?$username)
            c$conn$orig_user = process_info$username;

        process_info$c = process_info$c -1;
        if (process_info$c == 0) {
          delete connect_cache[host_id][c$conn$id$resp_h, port_to_count(c$conn$id$resp_p)];
        }
    }

    # Check the response of the connection

    # - Lookup if any of target candidates bound on the target port
    for (host_info_idx in dstHost_infos) {
        host_id = dstHost_infos[host_info_idx]$host;
        
        if (host_id !in bind_cache) { print("host_id not in bind_cache"); next; }

        # Binds to specific IPs
        if ([c$conn$id$resp_h, port_to_count(c$conn$id$resp_p)] in bind_cache[host_id]) {
            process_info = bind_cache[host_id][c$conn$id$resp_h, port_to_count(c$conn$id$resp_p)];

            if (process_info?$pid)
                c$conn$resp_pid = process_info$pid;
            if (process_info?$path)
                c$conn$resp_path = process_info$path;
            if (process_info?$username)
                c$conn$resp_user = process_info$username;

            next;
        }
        
        # Binds to all IPs
        if ([to_addr("0.0.0.0"), port_to_count(c$conn$id$resp_p)] in bind_cache[host_id]) {
            process_info = bind_cache[host_id][to_addr("0.0.0.0"), port_to_count(c$conn$id$resp_p)];

            if (process_info?$pid)
                c$conn$resp_pid = process_info$pid;
            if (process_info?$path)
                c$conn$resp_path = process_info$path;
            if (process_info?$username)
                c$conn$resp_user = process_info$username;
        }
    }

    return T;
}

function new_process_socket_info(host_id: string,
            action: string, local_address: string, local_port: int, remote_address: string, remote_port: int,
            pid: int, path: string, cmdline: string, uid: int, username:string)
{
    local info: Info = [
        $t=network_time(),
        $host=host_id,
        $action=action,
        $local_address=to_addr(local_address),
        $local_port=local_port,
        $remote_address=to_addr(remote_address),
        $remote_port=remote_port,
        $pid=pid,
        $path=path,
        $cmdline=cmdline,
        $uid=uid,
        $username=username
    ];

    Log::write(LOG, info);

    if (action == "snapshot") {
      add_process_socket_info(T, host_id, local_address, local_port, remote_address, remote_port, pid, path, username);
      add_process_socket_info(F, host_id, local_address, local_port, remote_address, remote_port, pid, path, username);
      return;
    }

    local orig: bool;
    if (action == "connect")
      orig = T;
    else if (action == "bind")
      orig = F;

    add_process_socket_info(orig, host_id, local_address, local_port, remote_address, remote_port, pid, path, username);
}


event connection_state_remove(c: connection)
{
    extend_connection_info(c);

    if (!c$conn?$orig_user && !c$conn?$resp_user) {
        #print(fmt("No User found for connection with id %s (%s:%d -> %s:%d)", c$conn$uid, c$conn$id$orig_h,c$conn$id$orig_p,c$conn$id$resp_h,c$conn$id$resp_p));
    return;
    }

    if (c$conn?$orig_user) {
        #print(fmt("Source user '%s' found for connection with id %s (%s:%d -> %s:%d)", c$conn$orig_user, c$conn$uid, c$conn$id$orig_h,c$conn$id$orig_p,c$conn$id$resp_h,c$conn$id$resp_p));
    
    } 
    if (c$conn?$resp_user) {
        #print(fmt("Target user '%s' found for connection with id %s (%s:%d -> %s:%d)", c$conn$resp_user, c$conn$uid, c$conn$id$orig_h,c$conn$id$orig_p,c$conn$id$resp_h,c$conn$id$resp_p));
    
    }
}

event host_user_username(resultInfo: osquery::ResultInfo,
            uid: int, gid: int, username: string)
{
    if ( resultInfo$utype == osquery::ADD || resultInfo$utype == osquery::SNAPSHOT) {
      if (resultInfo$host in user_cache) {
        user_cache[resultInfo$host][uid] = username;
      } else {
        local uid_user: table[int] of string = {[uid] = username};
        user_cache[resultInfo$host] = uid_user;
      }
      #print(fmt("Set uid '%s' on host '%s' to '%s'", uid, resultInfo$host, username));
    
    } else if (resultInfo$utype == osquery::REMOVE) {
      delete user_cache[resultInfo$host][uid];
    }
}

#TODO peer disconnect event to delete host from user_cache

event host_user_process_event(resultInfo: osquery::ResultInfo,
            pid: int, path: string, cmdline: string, uid: int)
{
    if ( resultInfo$utype != osquery::ADD && resultInfo$utype != osquery::SNAPSHOT)
        return;

    # Get name of the user
    local username = "";
    if (resultInfo$host in user_cache && uid in user_cache[resultInfo$host]) {
      username = user_cache[resultInfo$host][uid];
    }
    
    # Insert process info into cache
    #print(fmt("Inserting process with pid %s into cache", pid));
    local process_info: ProcessInfo = [$pid = pid, $path = path, $cmdline = cmdline, $uid = uid, $username = username];

    if (resultInfo$host in process_cache) {
      process_cache[resultInfo$host][pid] = process_info;
    } else {
      local pid_process_info: table[int] of ProcessInfo = {[pid] = process_info};
      process_cache[resultInfo$host] = pid_process_info;
    }

    # Match with cached socket events
    if (resultInfo$host !in socket_cache) {
      return;
    }

    if (pid !in socket_cache[resultInfo$host] || |socket_cache[resultInfo$host][pid]| == 0) {
      return;
    }

    local socket_infos = socket_cache[resultInfo$host][pid];
    local socket_info: SocketInfo;
    local idx: count;
    local action: string;
    local orig: bool;
    local local_address: string;
    local remote_address: string;
    local local_port: int;
    local remote_port: int;

    #print(fmt("Found %s cached socket_infos for pid %s", |socket_infos|, pid));

    for (idx in socket_infos) {
      socket_info = socket_infos[idx];
      action = socket_info$action;

      local_address = socket_info$srcIP;
      remote_address = socket_info$dstIP;
      local_port = socket_info$srcPort;
      remote_port = socket_info$dstPort;

      #print(fmt(" %s - %s:%s -> %s:%s", idx, local_address, local_port, remote_address, remote_port));
      
      new_process_socket_info(resultInfo$host, action, local_address, local_port, remote_address, remote_port, pid, path, cmdline, uid, username);
      return;
    }
}

event host_user_socket_event(resultInfo: osquery::ResultInfo,
            action: string, local_address: string, local_port: int, remote_address: string, remote_port: int,
            pid: int, path: string)
{
    if ( resultInfo$utype != osquery::ADD && resultInfo$utype != osquery::SNAPSHOT)
        return;

    # For outgoing connections
    if (action == "connect") {
      local_address = "0.0.0.0";
      local_port = 0;
    } else 
    # For incoming connections
    if (action == "bind") {
      remote_address = "0.0.0.0";
      remote_port = 0;
    }

    # Process already cached?
    if (resultInfo$host in process_cache && pid in process_cache[resultInfo$host]) {
      local process_info = process_cache[resultInfo$host][pid];
      local cmdline = process_info$cmdline;
      local username = process_info$username;
      local uid = process_info$uid;

      # Need to fix username
      #if (username == "") {
      #  if (resultInfo$host in user_cache && uid in user_cache[resultInfo$host]) {
      #    username = user_cache[resultInfo$host][uid];
      #  }
      #}
      #print(fmt("Process with pid %s already exists for %s:%s -> %s:%s", pid, local_address, local_port, remote_address, remote_port));
    
      new_process_socket_info(resultInfo$host, action, local_address, local_port, remote_address, remote_port, pid, path, cmdline, uid, username);
      return;
    }

    # Cache socket info until process information is ready
    local socket_info: SocketInfo;
    
    socket_info = [$pid = pid, $srcIP = local_address, $dstIP = remote_address, $srcPort = local_port, $dstPort = remote_port, $path = path, $action = action];
    #print(fmt("Adding socket %s:%s -> %s:%s to cache for pid %s", local_address, local_port, remote_address, remote_port, pid));
    
    # Add socket info to cache
    if (resultInfo$host in socket_cache && pid in socket_cache[resultInfo$host]) {
      socket_cache[resultInfo$host][pid][|socket_cache[resultInfo$host][pid]|] = socket_info;
    }
    else {
      local pid_socket_info: vector of SocketInfo = {socket_info};
      if (resultInfo$host in socket_cache) {
        socket_cache[resultInfo$host][pid] = pid_socket_info;
      }
      else {
        local host_pid_socket_info: table[int] of vector of SocketInfo = {[pid] = pid_socket_info};
        socket_cache[resultInfo$host] = host_pid_socket_info;
      }
    }
}

event osquery::host_connected(host_id: string) {
    local ev_users = [$ev=host_user_username, $query="SELECT uid, gid, username FROM users WHERE 1=1"];
    osquery::execute(ev_users, host_id);

    local ev_processes = [$ev=host_user_process_event, $query="SELECT pid, path, cmdline, IFNULL(uid, -1) AS uid FROM processes WHERE 1=1"];
    osquery::execute(ev_processes, host_id);
    
    local ev_sockets = [$ev=host_user_socket_event, $query="SELECT 'snapshot' AS action, s.local_address, s.local_port, s.remote_address, s.remote_port, s.pid, p.path from process_open_sockets s LEFT JOIN processes p ON s.pid = p.pid WHERE family=2 AND 1=1"];
    osquery::execute(ev_sockets, host_id);
}

event bro_init()
{
    Log::create_stream(LOG, [$columns=Info, $path="osq-user_connections"]);

    local ev_users = [$ev=host_user_username, $query="SELECT uid, gid, username FROM users"];
    osquery::subscribe(ev_users);

    local ev_process_events = [$ev=host_user_process_event, $query="SELECT pid, path, cmdline, IFNULL(uid, -1) AS uid FROM process_events", $inter=2];
    osquery::subscribe(ev_process_events);
    
    local ev_socket_events = [$ev=host_user_socket_event, $query="SELECT action, local_address, local_port, remote_address, remote_port, pid, path FROM socket_events", $inter=2];
    osquery::subscribe(ev_socket_events);
}


