
##! Add the peer to the connection logs.

module DNS;

export {
    redef record DNS::Info += {
        ans_query: vector of string &optional &log;
    };
}

event dns_query_reply(c: connection, msg: dns_msg, query: string, qtype: count, qclass: count)
{
    if(!c?$dns)
        return;

    if(!c$dns?$ans_query)
        c$dns$ans_query = vector();

    c$dns$ans_query[|c$dns$ans_query|] = query;
}