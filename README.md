One Shall Pass
===========

When it comes to choosing passwords for websites, most people fall into one of four
different camps:

1. They reuse the same password for multiple sites.
2. They choose different passwords for each site, and need to write them down
   somewhere (either offline or online).
3. They try to remember different passwords for each site, following an
   ad-hoc manually-computable encoding system.
4. They use a commercial product, like 1password.

If you're in the first camp, the constant security debacles at major
websites like Zappos and LinkedIn mean that your accounts on other
sites are in danger of being compromised.  If you're in the second
camp, you are out of luck if you're without your cheatsheet, maybe
because you're on a mobile device or using a friend's computer.  If
you're in the third camp, you're doing what cryptography should be
doing for you automatically.  And if you're in the fourth, you are
paying a substantial monthly fee and worse, cannot audit the code that
your security depends upon.

This app — “One Shall Pass” — gives you the best of all worlds.  The
idea is that you remember one passphrase (which should be a [quality
passphrase][pp]), and
One Shall Pass (1SP) will generate for you as many site-specific
passwords as you need.  It runs on any browser, like the one on your
laptop, your smartphone, or your friend's machine.  It's
self-contained, so it will run when you are disconnected, and you can
check for yourself that no sensitive information is being shipped over
the Internet.  It's free to use, and open-source, so you can modify it
and audit it as you please, and you need not fear being locked into
another expensive monthly service.  And it's based on strong
cryptographic primitives, so you'll be secure.

Still not convinced?  Read on to our FAQ-style introduction.

General FAQ
===========

### How do I prefill my e-mail for a bookmark?

You can bookmark the URL https://oneshallpass.com/#email=you@email.com

### How do I make a good passphrase?

Try [this handy tool][pp], also distributed as part of this project.

### Why shouldn't I dial up the security parameter to 10 or 16?

You might want to use 1SP on your phone, and it's way slower at
computing passwords than your desktop is.

### "One Shall Pass", is that a reference to Lord of the Rings?

No. Gandalf says "you cannot pass" to the Balrog on the Bridge of
Khazad-dûm.  "One Shall Pass" is a reference to
<a href="http://www.youtube.com/watch?v=dhRUe-gz690">this scene</a>
from Monty Python's Holy Grail.

Technical FAQ
=============

### What is the crypto behind One Shall Pass?

In a nutshell, HMAC-SHA512 \[[1](#citations),[2](#citations)\],
and PBKDF-2 \[[3](#citations)\] with some slight tweaks.

The 1SP input form takes as input six key pieces of information:

* _p_, the passphrase
* _e_, the email address
* _s_, the security parameter.
* _h_, the host to generate a password for
* _g_, the generation number of this password
* _b_, the block ID

The first three fields are fed as input to PBKDF-2, which
makes your passphrase harder to crack.
For every guess an adversary makes, he will have
to run multiple calls to HMAC-SHA512 to check if his guess
is correct.  1SP runs the PBKDF-2 algorithm as follows:

* _PRF_, the pseudo-reandom password, is HMAC-SHA512;
* _P_, the password, is the passphrase _p_ taken from your input;
* _S_, the salt, is _e_, the user's email address;
* _c_, the iteration count, is 2^s; and
* _dkLen_, the derived key length, is 512 bits, the output of the
chosen _PRF_.  Therefore, only one block is needed from PBKDF-2.
* _b_, the block ID, is 1, since there's only one block of input and output.

This algorithm outputs _DK_, a 512-bit derived key.  This needs
to be done only once per session, and the output can be cached
for use across multiple sites.  Then, each site's password is
computed as:

    HMAC-SHA512(_DK_, [ "OneShallPass v2.0", _e_, _h_, _g_, _i_ ])

for an iterator _i_ that starts at 0.  You can think of this
roughly as signing the message "User _e_ wants to log into site _h_"
with the private signing key derived from _p_.

1SP version 2 will find the first _i_ for which the following
conditions are met:

1. When the hash is base64-encoded, the leftmost 8 characters contain
at least 1 uppercase, 1 lowercase, and 1 digit, and no more than 5
uppercase, lowercase or digit characters.
1. The first 16 characters of the base64-encoding contain no symbols
(_e.g._, "/", "+" or "=")

The nice part about this version of 1SP (rather than the previous
version), is that the expensive computation (the iterated hashing
of the input passphrase) needs to happen only once per session,
and not once per site.  The adversary still has to do the same amount
of work in either case.

### How secure is this?

If you use the [suggested passphrase
generation tool][pp], and the default security setting, your password will
require in expectation 2^(58+8-1) = 2^65 calls to HMAC-SHA512 to crack. That
is, the passphrase generator gives 58 bits of entropy, 1SP's use of PBKDF-2
consumes 2^8 calls to HMAC-SHA512 to turn a passphrase into a derived key,
but on average, a cracker only needs to exhaust half of the search space to
find your passphase (hence the 2^(-1) factor).  The obvious way to compute
HMAC-SHA512 requires two invocations of SHA2, but I have not seen a proof that
two are required.  So conservatively, assume that one invocation of HMAC-
SHA512 is equivalent to one call to SHA2.

The Bitcoin system \[[4](#citations)\] can help us put a monetary value on
the cost of computing a hash.  After all, an adversary can either
spend cycles mining bitcoins or cracking your passphrase.  So cracking
your passphrase has a quantifiable opportunity cost.

As of 7 Feb 2013, the Bitcoin difficulty rate is
3,275,465, meaning it takes 2^32*3275465 hashes on average to
get a Bitcoin unit, which is 50 Bitcoins, each of which is worth
about $21.75 dollars.  So a conservative estimate is that a call to
SHA2 costs about 50*21.75/(2^32*3275465) dollars, or roughly 2^(-43.6) dollars.
So your password will require 2^(65-43.6) or roughly $2.7 million
to crack.

If you want better security, you can choose a 5-word passphrase,
which conservatively costs about $34 billion to crack.

### Why not `bcrypt` or `scrypt`?

1SP uses PBKDF2 for key-streching.  Future versions might
move to `scrypt`.

### Why HMAC?

We assume that an attacker has access to some of your passwords stored on
servers that he broke into (and whose programmers failed to secure with any
sort of hashing mechanism). And he's smart enough to know that you're using
1SP.  Thus, for each site he's broken into, he has a pair (t,m), where t is the
input text to the 1SP function above, and m is the output.  His goal is now to
log-in as you to a different site, that he hasn't compromised.  In other words,
he seeks a new pair (t',m'), that he hasn't seen before, where m' is the output
of the 1SP function for some new text t', referring to a new site.

This is exactly the property HMAC provides \[[5](#citations),[6](#citations)\]
It resists "existential forgery" under "known plaintext attacks".

### What about salt?

If you're asking about "salting" 1SP's passwords, you envision a
better world in which many millions of people are using 1SP to manage
their passwords! We're not there yet, but that "American Dream" is
handled by the current 1SP mechanism.

Imagine an attacker who breaks into a site, steals its password file, and
concludes that many of its users manage their passwords with 1SP.
He now wants to crack all of their passwords in parallel.  The
"salt" that prevents such a rainbow table attack is that your email
address is an input to 1SP.  So you and your friend who both use the
password "dog" will have to be cracked independently.

### What implementation of SHA2 and HMAC is 1SP using?

Jeff Mott's `crypto-js` library \[[7](#citations)\].  I tested
it with test-vectors from RFC-4231 and RFC-4868.  To make sure it
works for yourself, try `make test`; you'll need the `node`
binary in your path.

### How can I build 1SP?

I've checked in a self-contained `index.html` that should have
everything you need to run 1SP, including the necessary
crypto libraries, the CSS, and the JS for the UI.  You can build
it yourself using `make` in the top-level directory. By default, you'll
need `node` installed with the `uglifyjs` package, but you can skip
this dependency by replacing the `JSFILT` variable in `Makefile`
with `cat`.  This same technique also works well for debugging.
Building 1SP also requires the `stitch` and `iced-coffee-script`
modules from NPM.

### How does logging into the server work?

Your username is your e-mail address, and your password is the output
of the OneShallPass algorithm on the host `oneshallpass.com`.

### What is stored on the server, and how?

If you log into OneShallPass and save data to the server, you will be storing
an encrypted key-value pair on our servers (sent over TLS).  The "key" is the
current "host", and the "value" is a dictionary of the following fields from
the input: security bits, password length, generation, symbols needed, legacy
mode, and notes.  Note that your plaintext passphrase is never sent to the
server.

When encrypting and decrypting server-stored data, your OneShallPass web
client will derive two new keys from your master passphrase using PBKDF-2 as
above, but with differing initial block IDs.  A 256-bit key is derived
as an AES encryption key (using an initial block ID of 3), and a 256-bit
key is derived as an HMAC key to authenticate all encryption (using an initial
block ID of 4).

To encrypt a key, the 1SP client uses the current "host" field of the web
form (_e.g._, `chase.com`) as the plaintext. It picks a deterministic
initialization vector (IV) of all 0s, then encrypts with AES-256 in CBC mode,
using the derived key from above.  It then MACs the ciphertext and the IV with
HMAC-SHA256. The encrypted key is then the Base64-encoding of the msgpack
\[[8](#citations)\] of the JSON array  [ _ciphertext_, _IV_, _hmac_ ]. We're using
a deterministic IV for the key so that different browsers will always come up
with the same encryption of the same hostname, and that overwrites will work
as expected. The value half of the key-value pair is encrypted like the key,
but with a randomly-generated IV (as generated by
`window.crypto.getRandomValues`).

This encrypted key-value pair is then "put" to the server when the user
presses save. On login, all encrypted key-value pairs are fetched from the
server, and used to populate the dropdown.


Authors
======
* Maxwell Krohn
* Chris Coyne


Citations
=========

\[1\]:  HMAC: Keyed-Hashing for Message Authentication. http://www.ietf.org/rfc/rfc2104.txt 



\[2\]:  Secure Hash Standard, March 2012. http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf 



\[3\]:  B. Kaliski, RSA Labs. RFC-2898. http://www.ietf.org/rfc/rfc2898.txt  



\[4\]:  http://www.bitcoin.org 



\[5\]:  M. Bellare, R. Canetti, and H. Krawczyk. Keying hash functions for message authentication. CRYPTO 1996. http://cseweb.ucsd.edu/~mihir/papers/kmd5.pdf 



\[6\]:  M. Bellare. New Proofs for NMAC and HMAC: Security without Collision-Resistance. CRYPTO 2006. http://www.iacr.org/cryptodb/archive/2006/CRYPTO/1887/1887.pdf 



\[7\]:  Jeff Mott, `crypto-js`.  http://code.google.com/p/crypto-js 



\[8\]:  http://msgpack.org 



[pp]: https://oneshallpass.com/pp.html
