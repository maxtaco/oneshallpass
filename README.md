One Shall Pass
===========

When it comes to choosing passwords for Websites, most people fall into one of four
different camps:

1. They reuse the same password for multiple sites.
2. They choose different passwords for each site, and need to write them down
   in some sort of document.
3. They choose and try to remember different passwords for each site, following
   some sort of ad-hoc encoding system.
4. They use a commercial product, like 1password.

If you're in the first camp, the constant security debacles at major
Websites like Zappos and LinkedIn mean that your accounts on other sites
are in danger of being compromised.   If you're in the second camp,
you might run into issues if you're away from your cheatsheet, maybe
because you're on a mobile device or using a friend's computer.  If you're in
the third camp, you're doing what cryptography should be doing for you
automatically.  And if you're in the fourth, you're out several
beans a month and can't audit the code that your security depends upon.

This app — “One Shall Pass” — gives you the best of all worlds.  The ideas is
that you remember one passphrase (which should be a <a href="https://oneshallpass.com/pp.html">quality password!</a>), and One
Shall Pass (1SP) will generate for you as many site-specific passwords as you
need.  It runs on any browser, like that of your laptop, your smartphone, or an
Internet kiosk.  It's self-contained, so it will run when you are disconnected,
and you can check for yourself that no sensitive information is being shipped
over the Internet.  It's free to use, and open-source, so you can modify it and
audit it to your heart's content, and you need not fear being locked into
another expensively monthly service.  And it's based on strong cryptographic
primitives, so you'll be secure. 

Still not convinced?  Read on to our FAQ-style introduction.

General FAQ
===========

### What is the `generation` field for?

Some sites make you change your password periodically. Or, some sites might get
hacked. When they do, you can increment this field, and you'll get a different
password. My hope is that you can use `1` for almost all sites. Eventually I
hope to build server-side support for remembering users' generation numbers,
but this will obviously kill disconnected operation, and will make auditing my
work more challenging.

### I'm tired of typing my email address everytime, what can I do?
 
You can bookmark the URL https://oneshallpass.com/?email=you@email.com

### How do I make a passphrase that's legit?

Try <a href="https://oneshallpass.com/pp.html">this</a> handy tool,
also distributed as part of this project.

### How secure is this?

If you use the <a href="https://oneshallpass.com/pp.html">suggested passphrase
generation tool</a>, and the default security setting, your password will
require in expectation 2^(58+7-1) = 2^64 calls to HMAC-SHA512 to crack.
Recall each call to HMAC-SHA512 takes two calls to SHA-512, meaning
an expected 2^65 calls to SHA-512 are required to crack your password.

We can use Bitcoin economics to convert hash calls to dollars.  This is a
conservative estimate since SHA-512 is more expensive than SHA-1 to
compute. As of 25 July 2012, the Bitcoin difficulty rate is
1866391.3050032, meaning it takes 2^31*1866391.3 hashes on average to
to get a Bitcoin unit, which is 50 Bitcoins, each of which is worth
about $8.52 dollars.  So a conservative estimate is that a call to
SHA1 costs about 50*8.52/(2^31*1866391.3) dollars, or roughly 2^(-43) dollars.
So your password will require 2^(65-43) = 2^21 or roughly $4 million
to crack.

If you want better security, you can choose a 5-word passphrase,
which will conservatively take about $100 billion to crack.

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

In a nuthsell, HMAC-SHA512 \[[1](#citations),[2](#citations)\], with some slight tweaks.

The 1SP input form takes as input five key pieces of information:

* _p_, the passphrase
* _e_, the email address
* _h_, the host to generate a password for
* _g_, the generation number of this password
* _s_, the security parameter.

It then generates a sequence of passwords of the form

  HMAC-SHA512(_p_, [ "OneShallPass v1.0", _e_, _h_, _g_, _i_ ])

for a sequence of integers _i_ that vary from 1 to infinity. You
can think of this roughly as signing the message "User _e_ wants to
log into site _h_" with the private signing key _p_.
    
1SP will terminate on a given _i_ once the following three conditions are met:

1. The rightmost 2^_s_ bits of the output are 0s.
1. When the hash is base64-encoded, the leftmost 8 characters contain 
at least 1 uppercase, 1 lowercase, and 1 digit, and no more than 5 
uppercase, lowercase or digit characters.
1. The first 16 characters of the base64-encoding contain no symbols
(_e.g._, "/", "+" or "=")

This iterative process serves two goals.  First, it makes it more difficult for
an adversary to "crack" your password by a factor of at least 2^s.  That is, if
you assume your adversary got access to a site's password file, and that
password file was in plaintext, and the adversary knew the parameters _e_, _d_
and _g_, he might still try to guess _p_ by checking all passwords, and
checking to see if the output of the above function is what he stole from the
database.  But he'll have to run the above function on average 2^s times per
guess.  It won't make guessing your password impossible, just a nice constant
factor harder.  This is the same proof-of-work idea as in
HashCash \[[3](#citations)\], BitCoin \[[4](#citations)\], and many others.  The key
idea is that there is no know way to do the work better than
the obvious (intended) way.

The second goal of the iterative process is to generate a password
that sites will accept. Some sites won't accept the 3 symbolic characters
in Base64-encoding as password characters, so we throw away all passwords that
contain them without sacrificing entropy.  Moreover, since some sites
require passwords with uppercase, lowercase, and numerical characters,
we also require those to be present in the first 8 bytes of the password.
In practice, these practical conditions are usual met the first time through.

### Why not `bcrypt`?

`bcrypt` does not offer the security properties we need for 1SP.
`bcrypt` and their ilk are useful for hashing passwords on the server-side.
They make guesses expensive for adversaries trying to "crack" a compromised
password file, in which the adversary's goal is to recover as many
as passwords possible in the shortest amount of time.

We seek different properties.  In particular, we assume that an attacker has
acceess to some of your passwords stored on servers that he broke into (and
whose programmers failed to secure with any sort of hashing mechanism). And
he's smart enough to know that you're using 1SP.  Thus, for each site he's
broken into, he has a pair (t,m), where t is the input text to the 1SP function
above, and m is the output.  His goal is now to log-in as you to a different
site, that he hasn't compromised.  In other words, he seeks a new pair (t',m'),
that he hasn't seen before, where m' is the output of the 1SP function for some
new text t', referring to a new site.

This is exactly the property HMAC provides \[[5](#citations),[6](#citations)\].
It resists "existential forgery" under "known plaintext attacks".

### What about salt?

If you're asking about "salting" 1SP's passwords, you envision a
better world in which many millions of people are using 1SP to manage
their passwords! We're not they're yet, but that "American Dream" is
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


Author
======
Maxwell Krohn 

Citations
=========

\[1\]:  HMAC: Keyed-Hashing for Message Authentication. http://www.ietf.org/rfc/rfc2104.txt 



\[2\]:  Secure Hash Standard, March 2012. http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf 



\[3\]:  http://www.hashcash.org 



\[4\]:  http://www.bitcoin.org 



\[5\]:  M. Bellare, R. Canetti, and H. Krawczyk. Keying hash functions for message authentication. CRYPTO 1996. http://cseweb.ucsd.edu/~mihir/papers/kmd5.pdf 



\[6\]:  M. Bellare. New Proofs for NMAC and HMAC: Security without Collision-Resistance. CRYPTO 2006. http://www.iacr.org/cryptodb/archive/2006/CRYPTO/1887/1887.pdf 



\[7\]:  Jeff Mott, `crypto-js`.  http://code.google.com/p/crypto-js 


