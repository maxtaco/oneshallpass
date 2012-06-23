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

In a nutshuell, HMAC-SHA512 [[1][1]].

Author
======
Maxwell Krohn 

Citations
=========

[1]: http://www.ietf.org/rfc/rfc2104.txt
