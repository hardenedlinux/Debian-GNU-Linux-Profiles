#! Provides current interface information about hosts.

module osquery::host_info;

export {
    redef enum Log::ID += { LOG };

    type Info: record {
        ts: time &log;
        host: string &log;
        utype: osquery::UpdateType &log;
        interface: string &log;
        ip: addr &log;
        mac: string &log;
    };
}

event host_info_net(resultInfo: osquery::ResultInfo, interface: string, ip: string, mac: string)
{
    # Remove interface name from IP
    if ("%" in ip)
    {
        # Find position of delimiter
        local i = 0;
        while (i < |ip|)
        {
            if (ip[i] == "%") break;
            i += 1;
        }

        ip = ip[:i];
    }

    # Update the interface
    local host_id = resultInfo$host;
    osquery::hosts::updateInterface(resultInfo$utype, host_id, interface, to_addr(ip), mac);

    # Log the change
    Log::write(LOG, [$ts = network_time(),
                                         $host = host_id,
                                         $utype = resultInfo$utype,
                                         $interface = interface,
                                         $ip = to_addr(ip),
                                         $mac = mac]
    );
    
    #print(fmt("Received changes for InterfaceInfo on host %s and interface %s", host_id, interface));
}

event osquery::host_disconnected(host_id: string)
{
    osquery::hosts::removeHost(host_id);
}

event bro_init()
{
    Log::create_stream(LOG, [$columns=Info, $path="osq-host_info"]);

    local ev = [$ev=host_info_net,$query="SELECT a.interface, a.address, d.mac from interface_addresses as a INNER JOIN interface_details as d ON a.interface=d.interface;", $utype=osquery::BOTH];
    osquery::subscribe(ev);
}
