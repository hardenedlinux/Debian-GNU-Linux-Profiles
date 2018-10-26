module osquery::hosts;

export {
    type InterfaceInfo: record {
        ipv4: addr &optional;
        ipv6: addr &optional;
        mac: string;
    };

    type HostInfo: record {
        # The host ID
        host: string;
        # IP addresses and MAC address per interface name
        interface_info: table[string] of InterfaceInfo;
    };
    
    ## A hook interface to notify when the IP address on a host changes
    global host_addr_updated: hook(uytpe: osquery::UpdateType, host_id: string, ip: addr);

    ## Get the Host Info of a host by its id
    ##
    ## host_id: The identifier of the host
    global getHostInfoByHostID: function(host_id: string): HostInfo;

    ## Get the Host Info of a host by its address
    ##
    ## ip: the ip address of the host
    global getHostInfosByAddress: function(a: addr): vector of HostInfo;

    ## Get the IP addresses of a host by its id
    ##
    ## host_id: The identifier of the host
    global getIPsOfHost: function(host_id: string): vector of addr;

    ## Update the interface of a host when the IP assignment changes
    ##
    ## utype: If the IP address was added or removed
    ## host_id: The identifier of the host
    ## interface: The name of the interface on the host
    ## ip: The ip address that changed
    ## mac: The mac address that changed
    global updateInterface: function(utype: osquery::UpdateType, host_id: string, interface: string, ip: addr, mac: string);

    ## Remove a host together with its interfaces
    ##
    ## host_id: The identifier of the host
    global removeHost: function (host_id: string);
}

# Set of HostInfos
global host_infos: set[HostInfo];

# Table to access HostInfos by HostID
global host_info_hostid: table[string] of HostInfo;

function equalInterfaceInfo(ii1: InterfaceInfo, ii2: InterfaceInfo): bool
{
    if (ii1?$ipv4 != ii2?$ipv4 || (ii1?$ipv4 && ii2?$ipv4 && ii1$ipv4 != ii2$ipv4))
        return F;
    if (ii1?$ipv6 != ii2?$ipv6 || (ii1?$ipv6 && ii2?$ipv6 && ii1$ipv6 != ii2$ipv6))
        return F;
    if (ii1$mac != ii2$mac)
        return F;
    return T;
}

function equalHostInfo(hi1: HostInfo, hi2: HostInfo): bool
{
    if (hi1$host != hi2$host)
        return F;
    if (|hi1$interface_info| != |hi1$interface_info|)
        return F;
    for (interface in hi1$interface_info)
    {
        if (interface ! in hi2$interface_info)
            return F;
        if (! equalInterfaceInfo(hi1$interface_info[interface], hi2$interface_info[interface]))
            return F;
    }
    return T;
}


function getHostInfoByHostID(host_id: string): HostInfo
{
    if (host_id in host_info_hostid)
        return host_info_hostid[host_id];

    local new_interface_info: table[string] of InterfaceInfo;
    return [$host="", $interface_info=new_interface_info];
}

function getHostInfosByAddress(a: addr): vector of HostInfo
{
    local host_infos_new: vector of HostInfo;
    for (host_id in host_info_hostid) {
        local interface_info = host_info_hostid[host_id]$interface_info;
        for (iface_name in interface_info) {
            if (interface_info[iface_name]?$ipv4 && interface_info[iface_name]$ipv4 == a) {
                host_infos_new[|host_infos_new|] = host_info_hostid[host_id];
                break;
            }
            if (interface_info[iface_name]?$ipv6 && interface_info[iface_name]$ipv6 == a) {
                host_infos_new[|host_infos_new|] = host_info_hostid[host_id];
                break;
            }
        }
    }
    return host_infos_new;
}

# 
function getIPsOfHost(host_id: string): vector of addr
{
    local ips: vector of addr;
    local hostInfo = getHostInfoByHostID(host_id);
    for (j in hostInfo$interface_info)
    {
        local interfaceInfo = hostInfo$interface_info[j];
        if (interfaceInfo?$ipv4) ips[|ips|] = interfaceInfo$ipv4;
        if (interfaceInfo?$ipv6) ips[|ips|] = interfaceInfo$ipv6;
    }
    return ips;
}

function addHost(host_id: string)
{
    # Setup a HostInfo Object
    local interface_info_new: table[string] of InterfaceInfo;
    local host_info_new: HostInfo = [$host=host_id, $interface_info=interface_info_new];
    add host_infos[host_info_new];
    host_info_hostid[host_id] = host_info_new;
}

function removeHost(host_id: string)
{
    if (host_id ! in host_info_hostid)
    {
        return;
    }

    local host_info = host_info_hostid[host_id];

    # Remove HostInfo from lookup tables
    delete host_info_hostid[host_id];
    delete host_infos[host_info];
}

function remove_from_interface_info(host_id: string, interface: string, ip: addr, mac: string)
{
    # Retrieve the HostInfo Object for the respective host
        local host_info = host_info_hostid[host_id];
    #print(fmt("About to remove InterfaceInfo for host %s and interface %s", host_id, interface));

    # Check if InterfaceInfo exists for the interface
    if (interface ! in  host_info$interface_info)
    {
        print(fmt("No InterfaceInfo exists for host %s and interface %s", host_id, interface));
        return;
    }

    # Does the mac match?
    if (host_info$interface_info[interface]$mac != mac)
    {
        print(fmt("Overriding outdated mac in InterfaceInfo for host %s and interface %s", host_id, interface));
        host_info$interface_info[interface]$mac = mac;
    }

    local interface_info = host_info$interface_info[interface];
    # IPv4
    if (is_v4_addr(ip))
    {
        # Does an IPv4 exist?
        if (! interface_info?$ipv4 || interface_info$ipv4 != ip)
        {
            print(fmt("Removing outdated ipv4 in InterfaceInfo for host %s and interface %s", host_id, interface));
        }
        # Update InterfaceInfo
        host_info$interface_info[interface] = [$mac=mac];
        if (interface_info?$ipv6)
            host_info$interface_info[interface]$ipv6=interface_info$ipv6;
        interface_info = host_info$interface_info[interface];
    }

    # IPv6
    if (is_v6_addr(ip))
    {
        # Does an IPv6 exist?
        if (! interface_info?$ipv6 || interface_info$ipv6 != ip)
        {
            print(fmt("Removing outdated ipv6 in InterfaceInfo for host %s and interface %s", host_id, interface));
        }
        # Update InterfaceInfo
        host_info$interface_info[interface] = [$mac=mac];
        if (interface_info?$ipv4)
            host_info$interface_info[interface]$ipv4=interface_info$ipv4;
        interface_info = host_info$interface_info[interface];
    }

    # Remove interface if no active IP
    interface_info = host_info$interface_info[interface];
    if (! interface_info?$ipv4 && !interface_info?$ipv6)
    {
        delete host_info$interface_info[interface];
    }
}

function add_to_interface_info(host_id: string, interface: string, ip: addr, mac: string)
{
    # Retrieve the HostInfo Object for the respective host
    local host_info = host_info_hostid[host_id];
    #print(fmt("About to add InterfaceInfo for host %s and interface %s", host_id, interface));

    # Create new InterfaceInfo for the interface if needed
    if (interface ! in host_info$interface_info)
    {
        host_info$interface_info[interface] = [$mac=mac];
    }
    local interface_info = host_info$interface_info[interface];

    # Does the mac match?
    if (interface_info$mac != mac)
    {
        print(fmt("Overriding outdated mac in InterfaceInfo for host %s and interface %s", host_id, interface));
        interface_info$mac = mac;
    }

    # IPv4
    if (is_v4_addr(ip))
    {
        # Does an IPv4 already exist?
        if (interface_info?$ipv4)
        {
            print(fmt("Overriding existing ipv4 in InterfaceInfo for host %s and interface %s", host_id, interface));
        }
        interface_info$ipv4 = ip;
    }

    # IPv6
    if (is_v6_addr(ip))
    {
        # Does an IPv6 already exist?
        if (interface_info?$ipv6)
        {
            print(fmt("Overriding existing ipv6 in InterfaceInfo for host %s and interface %s", host_id, interface));
        }
        interface_info$ipv6 = ip;
    }
}

function updateInterface(utype: osquery::UpdateType, host_id: string, interface: string, ip: addr, mac: string)
{
    if (utype == osquery::ADD)
    {
        if (host_id ! in host_info_hostid)
        {
            addHost(host_id);
        }
        add_to_interface_info(host_id, interface, ip, mac);
    }
    else
    if (utype == osquery::REMOVE)
    {
        if (host_id in host_info_hostid)
        {
            remove_from_interface_info(host_id, interface, ip, mac);
        
        }
    }

    # Check for groups to join/leave (and subscriptions to add/remove)
    hook host_addr_updated(utype, host_id, ip);
}

