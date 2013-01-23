
{config} = require './config'
C = CryptoJS

##=======================================================================

exports.keymodes = keymodes =
  WEB_PW : 0x1
  LOGIN_PW : 0x2
  RECORD_AES : 0x3
  RECORD_HMAC : 0x4

##=======================================================================

class Base
  
  constructor : (@_input) ->

  #-----------------------------------------

  is_upper : (c) -> "A".charCodeAt(0) <= c and c <= "Z".charCodeAt(0)
  is_lower : (c) -> "a".charCodeAt(0) <= c and c <= "z".charCodeAt(0)
  is_digit : (c) -> "0".charCodeAt(0) <= c and c <= "9".charCodeAt(0)
  is_valid : (c) -> @is_upper(c) or @is_lower(c) or @is_digit (c)
   
  #-----------------------------------------
  
  # Rules for 'OK' passwords:
  #    - Within the first 8 characters:
  #       - At least one: uppercase, lowercase, and digit
  #       - No more than 5 of any one character class
  #       - No symbols
  #    - From characters 7 to 16:
  #       - No symbols
  is_ok_pw : (pw) ->
    caps = 0
    lowers = 0
    digits = 0

    for i in [0...config.pw.min_size]
      c = pw.charCodeAt i
      if @is_digit c then digits++
      else if @is_upper c then caps++
      else if @is_lower c then lowers++
      else return false

    bad = (x) -> (x is 0 or x > 5)
    return false if bad(digits) or bad(lowers) or bad(caps)
    
    for i in [config.pw.min_size...config.pw.max_size] 
      return false unless @is_valid pw.charCodeAt i

    true
    
  #-----------------------------------------

  #
  # Given a PW, find which class to substitute for symbols.
  # The rules are:
  #    - Pick the class that has the most instances in the first
  #      8 characters.
  #    - Tie goes to lowercase first, and to digits second
  # Return a function that will say yes to the chosen type of character.
  # 
  find_class_to_sub: (pw) ->
    caps = 0
    lowers = 0
    digits = 0

    for i in [0...config.pw.min_size]
      c = pw.charCodeAt i
      if @is_digit c then digits++
      else if @is_upper c then caps++
      else if @is_lower c then lowers++

    if lowers >= caps and lowers >= digits then @is_lower
    else if digits > lowers and digits >= caps then @is_digit
    else @is_upper
    
  #-----------------------------------------

  add_syms : (input, n) ->
    return input if n <= 0
    fn = @find_class_to_sub input
    indices = []
    for i in [0...config.pw.min_size]
      c = input.charCodeAt i
      if fn.call @, c
        indices.push i
        n--
        break if n is 0
    @add_syms_at_indices input, indices

  #-----------------------------------------

  add_syms_at_indices : (input, indices) ->
    _map = "`~!@#$%^&*()-_+={}[]|;:,<>.?/";
    @translate_at_indices input, indices, _map
      
  #-----------------------------------------

  translate_at_indices : (input, indices, _map) ->
    last = 0
    arr = []
    for index in indices
      arr.push input[last...index]
      c = input.charAt index
      i = C.enc.Base64._map.indexOf c
      c = _map.charAt(i % _map.length)
      arr.push c
      last = index + 1
    arr.push input[last...]
    arr.join ""

  ##-----------------------------------------

  format : (x) ->
    @add_syms x, @nsym()
    
  ##-----------------------------------------

  run : (cache_obj, compute_hook, cb) ->
    ret = null

    if not (dk = cache_obj._derived_key)? and not cache_obj._running
        
      cache_obj._running = true

      # show right away that we're going to be computing...
      compute_hook 0
      await setTimeout defer(), config.derive.initial_delay
      
      if compute_hook 0
        await @run_key_derivation compute_hook, defer dk
      
      cache_obj._derived_key = dk if dk?
      cache_obj._running = false
        
    ret = @finalize dk if dk
    ret = @format ret if ret
    cb ret
    
  ##-----------------------------------------

  delay : (i, cb) -> 
    if (i+1) % config.derive.iters_per_slot is 0
        await setTimeout defer(), config.derive.internal_delay
    cb()

  ##-----------------------------------------
  
  secbits : -> @_input.get 'secbits'
  email : -> @_input.get 'email'
  passphrase : -> @_input.get 'passphrase'
  host : -> @_input.get 'host'
  generation : -> @_input.get 'generation'
  nsym : -> @_input.get 'nsym'
  keymode : -> @_input.keymode()

##=======================================================================

exports.V1 = class V1 extends Base

  constructor : (i) -> super i
 
  ##-----------------------------------------

  run_key_derivation : (compute_hook, cb) ->
    ret = null
    d = 1 << @secbits()
    i = 0

    # Do these calls once, and out of the critical path
    [em, host, passphrase, gen]  = [@email(), @host(), @passphrase(), @generation()]
    
    until ret
      await @delay i, defer()
      if compute_hook i
        a = [ "OneShallPass v1.0", em, host, gen, i ]
        txt = a.join '; '
        hash = C.HmacSHA512 txt, passphrase
        b16 = hash.toString()
        b64 = hash.toString(C.enc.Base64)
        tail = parseInt b16[b16.length-8...], 16
        if tail % d is 0 and @is_ok_pw b64 then ret = b64
        else i++
      else
        break
    cb ret
    
  ##-----------------------------------------
 
  finalize : (dk) -> dk

##=======================================================================

exports.V2 = class V2 extends Base

  ##-----------------------------------------
  
  constructor : (input) ->
    super input
    
  ##-----------------------------------------
  
  run_key_derivation : (compute_hook, cb) ->

    ret = null
    # The initial setup as per PBKDF2, with email as the salt
    hmac = C.algo.HMAC.create C.algo.SHA512, @passphrase()
    block_index = C.lib.WordArray.create [ @keymode() ]
    block = hmac.update(@email()).finalize block_index
    hmac.reset()

    # Make a copy of the original block....
    intermediate = block.clone()

  	# Add 2 because v2 is easier than v1..
    exp = @secbits() + 2

    # subtract 1 because 1 iteration done by default
    limit = (1 << exp) - 1

    i = 0
    while i < limit
      await @delay i, defer()
      if compute_hook i 
        intermediate = hmac.finalize intermediate
        hmac.reset()
        block[j] ^= w for w,j in intermediate
        i++
      else
        break

    ret = block.toString C.enc.Base64 if i is limit
    cb ret
          
  ##-----------------------------------------

  finalize : (dk) ->
    i = 0
    ret = null
    
    until ret
      a = [ "OneShallPass v2.0", @email(), @host(), @generation(), i ]
      txt = a.join '; '
      hash = C.HmacSHA512 txt, dk
      b64 = hash.toString C.enc.Base64
      ret = b64 if @is_ok_pw b64
      i++

    ret
    
  ##-----------------------------------------
  
