PassThePeas
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

This app — “PassThePeas” — is an attempt to get you the best of all
worlds.  The ideas is that you remember one passphrase (which should be a
quality password!), and PassThePeas will generate for you as many site-specific
passwords as you need.  It runs on any browser, like that of your laptop, your
smartphone, or an Internet kiosk.  It's self-contained, so it will run when
you are disconnected, and you can check for yourself that no sensitive information
is being shipped over the Internet.  It's free to use, and open-source,
so you can modify it and audit it to your heart's content, and you need not
fear being locked into another expensively monthly service.  And it's based
on strong cryptographic primitives, so you'll be secure. 

Still not convinced?  Read on to our FAQ-style introduction.


FAQ
=======

### What is the crypto behind PassThePeas?

In a nuthsell, HMAC-SHA512 [[1](#citations),[2](#citations)], with some slight tweaks.

The PassThePeas input form takes as input five key pieces of information:

* _p_, the passphrase
* _e_, the email address
* _d_, the site or domain to generate a password for
* _g_, the generation number of this password
* _s_, the security parameter.

It then generates a sequence of passwords of the form

  HMAC-SHA512(_p_, [ "PassThePeas v1.0", _e_, _d_, _g_, _i_ ])

for a sequence of integers _i_ that vary from 1 to infinity.  PassThePeas
will terminate on a given _i_ once the following three conditions are met:

1. The rightmight 2^_s_ bits of the output are 0s.
1. When the hash is base64-encoded, the leftmost 8 characters contain 
at least 1 uppercase, 1 lowercase, and 1 digit, and no more than 5 
uppercase, lowercase or digit characters.
1. The first 16 characters of the base64-encoding contain no symbols
(_e.g._, "/", "+" or "-")

This iterative process serves two goals.  First, it makes it more difficult for
an adversary to "crack" your password by a factor of at least 2^s.  That is, if
you assume your adversary got access to a site's password file, and that
password file was in plaintext, and the adversary knew the parameters _e_, _d_
and _g_, he might still try to guess _p_ by checking all passwords, and
checking to see if the output of the above function is what he stole from the
database.  But he'll have to run the above function on average 2^s times per
guess.  It won't make guessing your password impossible, just a nice constant
factor harder.  This is the same proof-of-work idea as in
HashCash [[3](#citations)], BitCoin [[4](#citations)], and many others.  The key
idea is that there is no know way to do the work better than
the obvious (intended) way.

The second goal of the iterative process is to generate a password
that sites will accept. Some sites won't accept the 3 symbolic characters
in Base64-encoding as password characters, so we throw away all passwords that
contain them without sacrificing entropy.  Moreover, since some sites
require passwords with uppercase, lowercase, and numerical characters,
we also require those to be present in the first 8 bytes of the password.
In practice, these practical conditions are usual met the first time through.

### What implementation of SHA2 and HMAC is the PassThePeas using?

Jeff Mott's `crypto-js` library [[5](#citations)].  I tested
it with test-vectors from RFC-4231 and RFC-4868.  To make sure it 
works for yourself, try `make test`; you'll need the `node`
binary in your path.

### How can I build PassThePeas?

I've checked in a self-contained `index.html` that should have
everything you need to run PassThePeas, including the necessary
crypto libraries, the CSS, and the JS for the UI.  You can build
it yourself using `make` in the top-level directory. By default, you'll
need `node` installed with the `uglifyjs` package, but you can skip
this dependency by replacing the `JSFILT` variable in `Makefile`
with `cat`.  This same technique also works well for debugging.

### What is the `generation` field for?

Some sites make you change your password periodically. Or, some sites might get
hacked. When they do, you can increment this field, and you'll get a different
password. My hope is that you can use `1` for almost all sites. Eventually I
hope to build server-side support for remembering users' generation numbers,
but this will obviously kill disconnected operation, and will make auditing my
work more challenging.

Author
======
Maxwell Krohn 

Citations
=========

\[1\]: HMAC: Keyed-Hashing for Message Authentication. http://www.ietf.org/rfc/rfc2104.txt

\[2\]: Secure Hash Standard, March 2012. http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf

\[3\]: http://www.hashcash.org

\[4\]: http://www.bitcoin.org

\[5\]: Jeff Mott, `crypto-js`.  http://code.google.com/p/crypto-js.
