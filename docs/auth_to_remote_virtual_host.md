## Ways to authenticate yourself to a remote virtual machine host.
##### Copyright (c) TYA
##### Homepage: http://tya.company/

##### Via SSH

`virt-manager`(1) supports logging into a remote virtual machine host via SSH, with all authentication methods `openssh` supports, even including passphrase, but virt-manager will create connections encapsuled in SSH on demand, so if you ask virt-manager to login a remote host via SSH without using any agent (authenticating yourself via passphrase or key file with a pin without agent), windows popped continuously and occasionally by `ssh-askpass`(1) are really annoying, and inputting passphrase/pin via those windows is easy to blunder.

Because of those, I insist on using SSH for authentication with an agent.

###### Authenticate via key files with gnome-keyring as the agent

You have to generate your keypair with `ssh-keygen`(1) if you do not have one.

`$ ssh-keygen [-q] [-b bits] [-t dsa | ecdsa | ed25519 | rsa | rsa1] [-N new_passphrase] [-C comment] [-f output_keyfile]`


The Stribika Guide[3] immediately dismisses the DSA cipher, due to DSA only have 1024 bit. And DSA and ECDSA use randomness for each signature, if random numbers are not the best quality, then it is possible to recover the secret key. And ECDSA us NIST elliptic curves, so we departure DSA and ECDSA. RSA1 is using by SSHv1. So the options left for us is ed25519 and RSA.  Using large RSA and ed25519 key would be perfectly OK.

    $ ssh-keygen -t ed25519 -o -a 100   
    $ ssh-keygen -t rsa -b 4096 -o -a 100   

`-o` Causes ssh-keygen to save private keys using the new OpenSSH format rather than the more compatible PEM format.  The new format has increased resistance to brute-force password cracking but is not supported by versions of OpenSSH prior to 6.5.

`-a rounds` When saving a new-format private key (i.e. an ed25519 key or any SSH protocol 2 key when the -o flag is set), this option specifies the number of KDF (key derivation function) rounds used.  Higher numbers result in slower passphrase verification and increased resistance to brute-force password cracking (should the keys be stolen).

By default, the generated key files are located under your `$HOME/.ssh`, with names `id_$ALG` for private key and `id_$ALG.pub` for public key. A passphrase/pin had better be set to the private key.

Next step, you have to add the content of your public key file (only one line) to your `$HOME/.ssh/authorized_keys` with your personal workspace on the remote host, one line per key, by either asking the administrator of the remote host to add, or adding it yourself if you have been able to login to that host, by using `ssh-copy-id`(1) or by editing `authorized_keys` file manually.

If `gnome-keyring` is available in your desktop environment with default configurations, you can now try logging into the remote host using `ssh`(1), by invoking it directly from a terminal emulator, or any GUI tool able to invoke `ssh`(1), including `virt-manager`(1). a special window will pop up asking the passphrase/pin for your private key, and `gnome-keyring` will hold it within a period of time once you have performed unlocking correctly, so that further on-demand SSH login will not ask you for passphrase/pin again, until the old storage gets timed out.

###### Authenticate via key files and/or PKCS#11 module with ssh-agent as the agent

Originally you can invoke `$ ssh-add -s $pkcs11_shared_lib` (e.g. `$ ssh-add -s opensc-pkcs11.so`) to acknowledge the agent process with the PKCS#11 module to use. But unfortunately, since the recent version of `gnome-keyring` still lacks the ability to load PKCS#11 module, you will get an error like `Could not add card "$pkcs11_shared_lib": agent refused operation`, and you are unable to use a PKCS#11 module with `gnome-keyring` for authentication.

Fortunately, the traditional `ssh-agent`(1) works well with PKCS#11 modules. In order to use that, you must disable `gnome-keyring` from acting as an SSH agent first, for yourself.

Copy `/etc/xdg/autostart/gnome-keyring-ssh.desktop` to your `$HOME/.config/autostart/`, so that your own configuration will overload the global one, and append a line `Hidden=true` to the end of your own `$HOME/.config/autostart/gnome-keyring-ssh.desktop`. The SSH agent you use after your next login will change from `gnome-keyring` to `ssh-agent`(1).

The traditional `ssh-agent`(1) is not such automatic like `gnome-keyring`. It cannot ask you for the passphrase/pin on demand, so you must acknowledge `ssh-agent`(1) with your authentication key to use manually.

Invoke `$ ssh-add [-t lifetime] [keyfile ...]` for key file or `$ ssh-add [-t lifetime] -s $pkcs11_shared_lib` for PKCS#11 module.

Public keys that the module provides can be read by invoking `$ ssh-keygen -eD $pkcs11_shared_lib` in the same format as ssh public key file, and you can choose a appropriate one, adding into the remote `authorized_keys`.

Adding a lifetime to your authentication key for `ssh-agent`(1) to remember is recommended. `ssh-add`(1) will ask you for the passphrase/pin to unlock the key file or module, so that the pin is not asked again for further SSH login until timed out.

If the PKCS#11 module you use is backed by a removable hardware (e.g. a smartcard), the remembrance of the keys provided by the module becomes invalid once the backing hardware goes offline. You must ask `ssh-agent`(1) to forget the module by invoking `$ ssh-add -e opensc-pkcs11.so` before or after you remove the backing hardware, and then add the module again when needed.

`$ ssh-add -d file ...` can be used to forget key files.

With all authentication key remembered by `ssh-agent`(1), you can write and use scripts like _[virsh-list-cluster.sh](../scripts/vm-managements/virsh-list-cluster.sh)_ to query every host inside a cluster, with no need to get authenticated for every single hosts separately.

##### Via TLS

TBD

######Reference: 
######[1] man pages for ssh(1), ssh-keygen(1), ssh-add(1), ssh-agent(1), ssh-copy-id(1)
######[2] https://wiki.archlinux.org/index.php/GNOME/Keyring
######[3] https://stribika.github.io/2015/01/04/secure-secure-shell.html
