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

In a nuthsell, HMAC-SHA512 [[1](#Citations),[2](#Citations)], with some slight tweaks.

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

Author
======
Maxwell Krohn 

Citations
=========

\[1\]: HMAC: Keyed-Hashing for Message Authentication. http://www.ietf.org/rfc/rfc2104.txt

\[2\]: Secure Hash Standard, March 2012. http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf
