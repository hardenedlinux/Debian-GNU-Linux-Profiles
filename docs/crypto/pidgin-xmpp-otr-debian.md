# Standardized deployment procedure of using OTR to protect privacy For Debian/Ubuntu users, based on XMPP IM protocol

## Principle of OTR protocol
### Diffie–Hellman (DH) key exchange
Diffie–Hellman key exchange is performed between integers and a finite cyclic group.
Started here, integers are represented with lowercase letters, while elements of the 
cyclic group are represented with uppercase letters, and "==" is used to represent mathematical identity.

#### Character of finite cyclic groups
The number of the elements of a finite cyclic group is finite (as its name), and is called the order of the group.

The basic group operation P is commutative and associative: P(A,B)==P(B,A), P(P(A,B),C)==P(A,P(B,C)).

There is an identity element E in the group, with an arbitrary element A, satisfying 
P(A,E)=A, and there for each element A exists only one inverse element (-A) making P(A,-A)=E. The inverse element of identity element E is itself.

Applying m times operation P to the same element A is defined as a new operation M(m,A), with additional definition M(-m,A)=-M(m,A), thus according to these definitions, P(M(x,A),M(y,A))==M(x+y,A), and M(0,A)=E.

There are generators G (usually more than one) different with the identity element, making M(n,G)=E, and it can be proved that M(0,G)=E, M(1,G), M(2,G)……M(n-1,G) make up all the elements of the group.

For an arbitrary element, and arbitrary integers x, y, it can be proved that M(y,M(x,A))==M(x,M(y,A))==M(xy,A), which is the basis of DH.

The finite cyclic groups practical for cryptography need to satisfy that it is easy to compute M(m,A) from given m and A, but hard to compute an m satisfying M(m,A)=B from given A and B (usually called the discrete logarithm problem of such finite cyclic group).

Groups commonly used for cryptography include **multiplicative group of integers modulo prime p**(in which P is the modular multiplication, M is the modular exponentiation) and **additive group of points on an elliptic curve over finite fields**(in which P is the modular addition of points, M is the modular multiplication between of a point and an integer).

#### Key Exchanging procedure
Started here, A=M(a,G) is called the (mapped) image within the cyclic group about its generator G of integer a, and a is the source of A.
1. Alice and Bob agree to use a finite cyclic groups practical for cryptography and one of its generator G.
2. Alice and Bob respectively choose their secret integer a and b randomly, compute corresponding image A=M(a,G) and B=M(b,G), then send the image to the other part.
3. Alice and Bob respectively compute the shared secret from their own source and the image sent from the other part: S=M(a,B)=M(a,M(b,G))==M(ab,G)==M(b,M(a,G))=M(b,A).

Now they get the same shared secret, and they can derive the session key for symmetric encryption via the same algorithm.

Note that only the information about the group itself, and images A and B, appear on the communication channel, but it is very hard to get a source from its image within a finite cyclic groups practical for cryptography, thus the security is kept.


### Cryptographic hash algorithm
This kind of algorithms accept an input with arbitrary length, to generate an output with fixed-length, by scrambling, mixing, and recombining the input, and it is very hard to speculate the input from its output. They are usually designed so that a tiny change of the input causes a vast change of the output, but they are definite, via which outputs generated from identical inputs are surely identical.

### Assymmetric signature algorithm
DH key-exchanging itself is not resistant man-in-the-middle attack, that is to say, you cannot be sure that the image you receive is indeed sent from the part with which you intend to communicate. The regular method to resolve such problem is usually to use assymmetric signature algorithms.

Assymmetric signature algorithms make use of public-private key pairs, and it is very hard to speculate private keys from public keys. The private key is strictly kept secret, with only its holder knowing, while the public key could be sent to anyone who wants to communicate with you.

A hash algorithm is applied upon a piece of data, and the result is processed with the private key. The final result is the digital signature of the original data, generated with the private key. Anyone with the data and signature at hand could ensure via hash algorithm and public key that:
1. The data are not changed.
2. The signature are undeniably generated with the corresponding private key.


### symmetric encryption algorithm
A secret key is applied to a piece of plain text to generate cipher text (with the same length with the plain text, usually), and plain text could be easily and perfectly restored with an identical secret key, but be very hard for parts with the secret key unknown. A good symmetric encryption algorithm is usually designed so that a tiny change of the input causes a vast change of the output, too.

### Message authentication code/algorithm (MAC)
Message authentication algorithms are someway similar to digital signature algorithms, but they work symmetrically: Applying the authentication key to an arbitrary piece of data results the corresponding message authentication code with fixed-length, but it is very hard either to speculate the original data and authentication key from MAC, or to speculate the authentication key from MAC and original data. Thus, only those parts with the authentication key at hand are capable to check the integrity of the data, but in contrast with digital signature, every part holding the authentication key is capable to generate the identical MAC, thus MAC cannot be used for authentication.

Message authentication algorithms are commonly designed upon symmetric encryption and/or cryptographic hash algorithms, and those derived from hash algorithms are called HMAC.

## Brief introduction of OTR
Off-the-Record Messaging (abbreviated to OTR) is a security protocol capable to work on the basis of arbitrary protocol which can reliably transfer texts bidirectionally.
It provides these peatures below:
1. Perfect forward secrecy: Adversaries are unable to restore the conversation even they have monitored the whole conversation and/or fetched the long-term keys stored on endpoints.
2. Unity of integrity and deniability: You can confidentially ensure whether a message is sent by the other end; while adversaries in between cannot testify who have certainly said what.

To implement DH, OTR makes use of a certain **modular multiplicative group** [whose modulo is the 1536-bits prime defined in RFC 3526, with its primitive root 2 selected as the generator, to ease calculation](https://tools.ietf.org/html/rfc3526#page-3).

Identity authentication is required because DH key exchanging itself is not resistant to man-in-the-middle attack. The latest version of OTR makes use of DSA algorithm to make digital signature for authentication.

However, authentication based on digital signature is undeniable, thus the traditional ways (e.g. current TLS) to plainly send public keys before sending signed mapped images leak identities (public keys) to the potential adversary in between.

In order to unite the integrity and deniability, OTR in **handshaking** phase utilizes a way to `"do an unauthenticated Diffie-Hellman (D-H) key exchange first, and then mutually authenticate identities, images and values derived from the shared secret inside the symmetrically encrypted channel derived from the shared secret"`. As the authentication process itself is encrypted, identities are not leaked to a passive sniffer; although public keys could be swindled out via man-in-the-middle attack, however, because mapped images and values derived from the shared secret are authenticated as well, and the man-in-the-middle is nearly impossible to get identical shared secrets with two endpoints via agreement, man-in-the-middle attack nearly always breaks authentication. Therefore a succeeded OTR handshaking guarantees that conversation participants can obtain public keys of the other part during handshaking, and only they can, thus unite the integrity and deniability -- handshaking is undeniable only to its participants.

OTR utilizes AES for symmetric encryption, and HMAC-SHA256 for message authentication.

After handshaking succeeded, the two parts have their own source and image sent from the other, from which identical shared secrets could be computed respectively.

The way for OTR to implement perfect forward secrecy is extremely paranoid.

* With their source and the other's image, the sender computes the shared secret, from which the encryption key is derived, from which the authentication key is derived. They encrypt the message with encryption key, randomly select a new DH source to replace the current and compute its image, then send the other part the combination of `images' serial number of the two, new image of theirselves' side, cipher text, etc`, with MAC generated with the authentication key for the above-mentioned stuffs attached, and finally update the image's serial number of theirselves' side.

* After receiving the message, with their source and the other's image, the receiver 
 computes the shared secret, derives encryption and authentication keys as well, verify the integrity of the message with the authentication key, decrypt the cipher text with the encryption key, and finally update the cached image from the other as well as both serial numbers. It can be seen that the DH parameters (the source and the corresponding image) of one side is updated during sending, and if one side only receives but does not send messages in a period of time, their DH parameters remain unchanged.
 
It is clear that OTR performs DH exchanging for the next message every time when sending a message, thus every message is encrypted with different encryption key, to approach the security level of `one-time pad`.

In order to unite the integrity and deniability here, every authentication key of received messages since last sending is collected and sent **plainly** attaching to the new message. Its designated target is not the other part, but any potential adversary. Anyone obtained the authentication key can make messages capable to pass authentication, and libotr -- the major implementation of OTR even provides specialized tools for that. Therefore, adversaries cannot testify a certain message is sent by a certain person and spied by them, but not forged by themselves, thus the deniability is achieved. However, before published via new message, only the sender and receiver can get the the authentication key by deriving from the shared secret, thus the receiver of the message can ensure the message is indeed sent by the other part, thus the integrity is achieved.

To learn OTR's further detail, [its official document](https://otr.cypherpunks.ca/Protocol-v3-4.1.1.html) can be referred to.

## Using OTR protocol
Until now, only XMPP protocol implements the integration of OTR in its mainstream clients, and in the next place, small amount of IRC clients integrate OTR. However as mentioned above, in theory atop any protocol capable to reliably transfer texts bidirectionally, OTR can work. That is why I suggest here to use [Pidgin](https://pidgin.im/), an instant messaging client supporting plenty of features of plenty of protocols via its plugin system -- via pidgin, you can even use OTR to protect yourselves atop proprietary protocols, e.g. MSN.

### Brief introduction of Pidgin
The core of Pidgin is a library abstracting an instant messaging client, called libpurple, which contains no concrete implementation of user interface and/or communication protocol, but leaves them to application programs and protocol plugins to complete. In architectural sense, Pidgin, written with GTK+, is the official user interface of libpurple; while the OTR plugin acts as the middleware between libotr, libpurple and Pidgin, unrelated to concrete communication protocol. Therefore, via pidgin, you can use OTR atop any protocol with implementation in the form of a protocol plugin of libpurple.


#### Software Installation
In the software repository of Debian and Ubuntu GNU/Linux, common xmpp supports are bundled with libpurple to distribute, and a lot of plugins related to user interface are bundled with Pidgin, while the middleware pidgin-otr is an solitory package.

Install pidgin and the otr plugin with the following commands, respectively.
```
# apt-get install pidgin
# apt-get install pidgin-otr
```
Apt package manager automatically resolves dependencies and installs other required packages。

#### Building a helper plugin: pidgin-xmpp-receipts
There is a problem in OTR: network instability may make the source held by one side inconsistent with the mapped image held by the other side, in which case a message sent will be unable to decrypt correctly, but OTR protocol usually cannot automatically recovery synchronization, and requires manually re-handshaking (usually represented as "refresh conversation" on user interfaces).

An extension of XMPP -- receipt functionality is helpful to detect the synchronization loss problem of OTR: This extension could deliver a "receipt" defined within the protocol to the sender of a message to notice that the message is received successfully, while cooperated with OTR, "successful receiving" will contain "successful decryption" -- only a successfully decrypted message generates its receipt. According to this, sender could detect synchronization losses, and perform re-handshaking in time.

Most dedicated XMPP client natively support the receipt functionality, but in Pidgin's system, its XMPP protocol plugin does not implement this functionality, therefore [a plugin](https://app.assembla.com/spaces/pidgin-xmpp-receipts/git/source) is written to implement it.

This plugin has not been included in debian as well as its downstream derivatives (though several distributions have included it), so it should be built and deployed manually before it is included by your distribution.

Install the development package of Pidgin:
```
# apt-get install pidgin-dev
```
Clone the source code of the plugin, build and deploy it:
```
$ git clone https://git.assembla.com/pidgin-xmpp-receipts.git
$ cd path/to/pidgin-xmpp-receipts
$ make && make install
```
The resulted plugin `xmpp-receipts.so` is copied to the plugin directory of the current user `${HOME}/.purple/plugins/`, and it can be found in the `Plugins` dialog under the `Tools` menu of Pidgin after restart, with `XMPP Receipts` as its name. After enabled with a check, a tick `✓` will be inserted after a message successfully received by the other end as a mark.

#### Authenticating the identity of the opposite side
You can obtain the public key of the opposite side during handshaking of OTR, to authenticate their identity. If the received public key has never been seen by your client used by the opposite side's account, the system will give a notification, and save its fingerprint locally, becoming a **recognized but unauthenticated** key.

It is clear that an entity holding a private key corresponding to a **recognized but unauthenticated** public key has once performed OTR handshaking with you, but you are unable, however, to know with it whether who holds the private key corresponding to the public key is identical to the true sender of the message you received, and the verification of this should be done outside the channel authenticated by the key to verify.

The most basi way is to perform **manual verification of fingerprint**: the program shows the fingerprint of public keys of yours and the opposite side. Ensuring that the **fingerprint of the opposite side** in your aspect is identical to the **fingerprint of yourself's** in the aspect of the opposite side, and the **fingerprint of yourself's** in your aspect is identical to the **fingerprint of the opposite side** in the aspect of the opposite side is to complete the authentication of the identity of the opposite side, and the public key of the opposite side could be marked as **verified**.

If your peer has more than one public keys, but only a part of them has been verified by you, or you detect a new public key was sent during handshaking from an entity you have verified, you can ask the opposite side to send you their fingerprint with (the instance in which resides) a public key you have verified. For example:

```
"It seems that I have not recognized the OTR fingerprint you just use today. Is it convenient to do a verification? Could you send me the fingerprint you are using with the computer/mobile phone you used the last time we met?"
```
The effect is identical to their giving the fingerprint to you in their presence, as long as your opposite side does never hand over the private key corresponding to the public key you verified to others. After that, you can open the public key fingerprint list in the config dialog of OTR plugin, and mark the verified public key.

If you have verified the OpenPGP public key of your opposite side, you can ask them to sign their OTR fingerprints with their OpenPGP private key and send the result to you, as long as you are confident that they will never hand over their OpenPGP private key.

It should be noted that you should never tell your opposite side the complete fingerprint you want to verify, but let your opposite side tell you the fingerprint, in order for you to confirm.

As the aspect to be authenticated, the two methods above could be combined into one: prepare a list of fingerprints of all the OTR public keys you use, clear-signed with OpenPGP, and send it to your trustful friends, in order for them to verify.

The template below could be referred to:

```
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

I hereby claim:

  * I am bob, who owns the following PGP key(s):

	6B25C1C7 7E739D1B 6C5E86B0 D3CED892 A6AEB68B

  * At the same time, I am the owner of the following OTR key(s):

	3340D56D 2C750734 F9869A1B 26CFAC08 04823F52
	1063A0B9 F9EE4D3B 06250142 2A720531 DD2D0DC4

  * The following OTR key(s) are used for mobile phone,
    they may get revoked at any time.

	49AF52C4 53FF6323 635728B6 9325628C 0FF2E547

  * And I declare revocation of the following OTR key(s), their
    private keys are destroyed, please don't trust them:

	8DF79391 B8082682 42D5483E 976503B8 E458AEA8

  * To prove the claims above, this message is signed by my PGP key
    mentioned above.

You could also collect all fingerprints linked to your frequently
used xmpp accounts into a list like this, clear-sign it with gnupg,
and send it to your trustful friends, in order for them to trust you.
-----BEGIN PGP SIGNATURE-----

(signature of your OpenPGP key)
-----END PGP SIGNATURE-----
```

A problem arises that some clients will compose messages (e.g. Pidgin composes messages with html), which often breaks the integrity of clear-sign. An effective way to resolve it is to encode the clear-signed text into radix-64 form to which composing is not harmful, via running `gpg --store -a`, and restoring via `gpg -d`. This command compresses its input transparently by default, thus easier than the "traditional" way to compress and then base64.

### About authencation via Q&A and/or shared secret
The OTR plugin of Pidgin by default supports authencation via Q&A and/or shared secret (they are essentially the same). Its core thought is to get a secret only you two know between you and your opposite side, and then ask them a question about the shared secret via the Q&A and/or shared secret functionality of the OTR plugin. If the answer is identical to the preset one, the public key of your opposite side is marked as trustful automatically. Your opposite side cannot obtain your preset answer, and you cannot obtain the answer from your opposite side. [A specific algorithm](https://en.wikipedia.org/wiki/Socialist_millionaires) is used to judge whether two value is equal without leaking the value itself to any other entity including the opposite side.

The shared secret itself is symmetric, thus if you have a communication network with N people, you should maintain N pieces of shared secret. It is the major disadvantage of such way, thus is suggested to be used along with assymmetric methods based on fingerprints. For example, if you only use OTR on one machine only (so that you have only one OTR instance), the shared secret could help your friends to authenticate you in case you accidentally lose your private key of the instance. It is obvious that other authenticated OTR instances of yours could play the same role.

Multi-channel is core of such authencation method. A lot of commonly seen way is described here:

* Exchanging the secret in café, bar, or clubs. Meeting physically is a relatively safe way, but adversaries should also be considered within your threat model (for shared secret is symmetric). It is usual to exchange shared secret for OTR when attending PGP signing parties.

* Exchanging the secret via mails signed with PGP, two key points should be noticed: 1) You should verify whether the key of your opposite side are trusted by other third-parties. 2) You should confirm their PGP fingerprint (usually completed via meeting physically, too) This method is based on the security of PGP itself.

* It could be completed via telephone, SMS, or other instant messaging tools if the security need is low. In scenes with higher security level, anonymous network like onion routing network and/or chatting service authenticated with SSL/TLS/SSH running on a private network could be used.

* Furthermore, channels based on these methods above could be further split, and the shared secret could be combined from information exchanged via multiple different channels. It should be noted that information exchanged via a channel should be noted as little as possible in other different channels.

The shared secret could be update on demand, e.g. during meeting or inside an authenticated OTR channel:
```
"Hey pal, shall we append '777' on our last shared secret?"
```
