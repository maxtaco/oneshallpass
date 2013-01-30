
what engine exposes
=================== 
constructor:
  passphrase:       (optional)
  email:            (optional)
  algo_version:     (optional)
  length:           (optional)
  security_bits:    (optional)
  no_timeout:       (optional; default = false)
  on_compute_step:  (keymode, step_num, total_steps)
  on_compute_done:  (keymode)


member functions
----------------
set  (key, val)
get  (key)
poke ()
is_logged_in()
logout()
login()            # calls back with error/success 
signup()           # calls back with error/success
get_stored_records() # returns array of items
push()             # calls back with error/success


keys
-----------------
 passphrase
 email
 length
 security_bits
 notes
 num_symbols
 algo_version
 generation
 host
 no_timeout



