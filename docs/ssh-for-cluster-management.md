## Recommended way to use ssh(1) for cluster management.
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Prerequests

It is assumed that you have read _[Ways to authenticate yourself to a remote virtual machine host](./auth_to_remote_virtual_host.md)_ to know how to set an ssh agent to register your identity keys for ssh, and _[Powerful ssh(1) options you don't know](./powerful-ssh-options-you-dont-know.md)_ to know how to forward the socket from your local agent to the remote host.

In this article, ssh(1) options will be express with the format mentioned within _[Powerful ssh(1) options you don't know](./powerful-ssh-options-you-dont-know.md)_.

##### Basic philosophy for cluster management.

As mentioned in _[The recommended configs of host computers and management console running Debian GNU/Linux within clusters](./recommended_cluster_config.md)_, it is assumed that a cluster consists of a shared storage infrastructure, several worker hosts, within which virtual guests are running, and a special "host" used as a management console (abbreviated as MC, below). All those hosts is connected within the same subnet and able to communicate with each other, as well as guests, possibly. 

Additionally, only the MC is assumed to be able to accept incoming login requests for administration from the outside of the subnet, which may be accomplished by network configuration, or firewalls.

Because of that, you, the administrator of the cluster, have to log into the MC with ssh(1) first, and then you are able to log into other worker hosts and guests further, from MC.

##### The contradiction between local identities storage and authentication needs from remote hosts.

Personally, I use smart cards compatible with [OpenSC](https://github.com/OpenSC/OpenSC) to perform authentication for SSH, by using the PKCS#11 module provided by OpenSC while getting one of my card connected to the local machine I am operating directly. 

This time, however, identities should be available on MC. On MC, I say it again, not your local machine. It is usually impossible for you to physically connect your cards to MC, and using file-based identity stored on MC ought to be a bad practice, if only you already have usable smart cards at hand.

##### Usage of ForwardAgent(A,~a).

The `ForwardAgent(A,~a)` option provided by `OpenSSH` could just solve this contradiction. 

By applying this option to the command line for ssh(1), scp(1) and sftp(1) (possibly with its config form), the unix domain socket from your local ssh agent is forwarded to the remote host once you have passed the authentication and then logged into it, as if the forwarded domain socket recorded in the `SSH_AUTH_SOCK` environment variable on the remote host were provided by an agent running on the remote host, which, in this scene, may be the MC, and all identity keys registered locally are all available on the remote. 

You can then log into any machine accessible from MC, provided that the identity keys needed for authentication for the machine have been registered to the local agent:

	$ ssh-add -t 300 mc.key
	$ ssh-add -t 300 a.host.key
	$ ssh -A virtmgr@mc.host.xxx.com
	virtmgr@mc.host.xxx.com:~$ ssh virtmgr@a.host.xxx.com

##### Usage of ProxyJump(J).

Sometimes, you may need only to log into one of the (physical or virtual) machine within the cluster, other than MC, for administration, and you may feel it annoying to log into MC first and then log into the target host.

This time you could use `ProxyJump(J)`. You have known that the ssh(1) has the ability to multiplex many streams inside one session of its own. By using this option with MC as the proxy host, the SSH client you are using will first connect to the proxy host, authencate and create a session, and then create a second connection, tunneled inside the first one, to the target host, with the very same process, and finally create the session to your target host. The proxy hosts could even be stacked more, for which commas could be used to multiple proxies.

In order to use this option, you should have authentication material for both the proxy host and the target host at hand, which the easist way to achieve is to register both authentication identities to your local adent. Using `ForwardAgent(A,~a)` is not necessary here, as only the local client is participating in needed sessions:

	$ ssh-add -t 300 mc.key
	$ ssh-add -t 300 a.host.key
	$ ssh -J virtmgr@mc.host.xxx.com virtmgr@a.host.xxx.com

Besides the host expression (ip address, hostname, etc) for the target host should be in the sight of the proxy host (mc.host.xxx.com for above example), NOT the local host, as the direct network connection to the target host is made from the proxy host.

######Reference: 
######[1] man page ssh(1) and ssh_config(5)
######[2] [The recommended configs of host computers and management console running Debian GNU/Linux within clusters](./recommended_cluster_config.md)
######[3] [Ways to authenticate yourself to a remote virtual machine host](./auth_to_remote_virtual_host.md)
######[4] [Powerful ssh(1) options you don't know](./powerful-ssh-options-you-dont-know.md)
