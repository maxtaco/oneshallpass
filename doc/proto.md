
# Proposed Protocol

## Put

     put(email, H(pk, 'email 1sp.com'), key, value);

Will do one of two things:
1.  If the email has been registered successfully before, then check
the hash against the stored password, and if it is the right one,
then update the user's object with the given key-value. 
1. If the email hasn't been register, then write the quad to a temporary
table, with a self-authenticating email token, and send out an email.
1. If the email has been registered but this is the wrong PW, then
report a failure.
