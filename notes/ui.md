# Main Engine 

As found in the stiched `lib.js`, accessed via:

```coffeescript
{Engine} = require './engine'
```

### constructor:

```coffeescript
  default_values : {
    passphrase:       (optional)
    email:            (optional)
    algo_version:     (optional)
    length:           (optional)
    security_bits:    (optional)
    no_timeout:       (optional; default = false)
  },
  hooks : {
    on_compute_step:  (keymode, step_num, total_steps)
    on_compute_done:  (keymode, key)
    on_timeout     :  ()
  }
```

### member functions

* set  (key, val)
* get  (key)
* poke ()
* is_logged_in()
* logout()		   # calls back with error/success
* login()            # calls back with error/success 
* signup()           # calls back with error/success
* get_stored_records() # returns array of items
* push()             # calls back with error/success


### keys

* passphrase
* email
* length
* security_bits
* notes
* num_symbols
* algo_version
* generation
* host
* no_timeout


# Passphrase Generator Engine

As found in the stitched `pp.js`, accessed via

```coffeescript
{Engine} = require './engine'
```

### constructor:

```coffeescript
  default_values : {
    entropy : 58
  } 
  hooks : {
    on_generate : (passphrase)
  }
```

### member functions

* got_input_key() - got a key input -- can be a space or a real key
* set_entropy()   - set the entropy to the number of bits given
* get_entropy()   - the active amount of entropy 