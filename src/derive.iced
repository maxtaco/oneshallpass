
{config} = require './config'
C = CryptoJS

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

    for c in pw[0...config.pw.min_size]
      if @is_digit c then digits++
      else if @is_upper c then caps++
      else if @is_lower c then lowers++
      else return false

    bad = (x) -> (x is 0 or x > 5)
    return false if bad(digits) or bad(lowers) or bad(caps)
    
    for c in pw[config.pw.min_size...] 
      return false unless @is_valid(c)
      
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

    for c in pw[0...config.pw.min_size]
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
    for c,i in pw[0...config.pw.min_size]
      if fn.call @, c
        indices.push i
        n--
        break if n is 0
    @add_syms_at_indices input, indicies

  #-----------------------------------------

  add_syms_at_indices : (input, indices) ->
    _map = "`~!@#$%^&*()-_+={}[]|;:,<>.?/";
    @translate_at_indices input, indices, _map
      
  #-----------------------------------------

  translate_at_indices : (input, indices, _map) ->
    last = 0
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

  run : (compute_hook, cb) ->
    ret = null
    v = "_v#{@version()}"
    
    if not (slot = @_input[v])? and
        not (dk = slot._derived_key)? and not slot._running
        
      slot = input[v] = {} unless slot?
      slot._running = true
      
      await setTimeout defer(), config.derive.initial_delay
      
      if compute_hook 0
        await @run_key_derivation compute_hook, defer dk
      
      slot._derived_key = dk if dk?
      slot._running = false
        
    await @finalize dk, defer ret if dk
    cb ret
    
  ##-----------------------------------------

  delay : (i, cb) -> 
    if (i+1) % config.derive.iters_per_slot is 0
        await setTimeout defer(), config.derive.internal_delay
    cb()

  ##-----------------------------------------
  
  secbits : -> parseInt(@_input.get('secbits'), 10)
  email : -> @_input.get 'email'
  passphrase : -> @_input.get 'passphrase'
  host : -> @_input.get 'host'
  generation : -> @_input.get 'generation'
  

##=======================================================================

exports.V1 = class V1 extends Base

  constructor : (i) -> super i
  version : () -> 1
 
  ##-----------------------------------------

  run_key_derivation : (compute_hook, cb) ->
    ret = null
    d = 1 << @secbits()
    i = 0
    
    until ret
      await @delay i, defer()
      if compute_hook i
        a = [ "OneShallPass v1.0", @email(), @host(), @generation(), i ]
        txt = a.join '; '
        hash = C.HmacSHA512 txt, @passphrase()
        b16 = hash.toString()
        b64 = hash.toString(C.end.Base64)
        tail = parseInt b16[b16.length-8...], 16
        if tail % d is 0 and @is_ok_pw b64 then ret = b64
        else i++
      else
        break

    cb ret
    
  ##-----------------------------------------
 
  finalize : (dk, cb) -> cb dk

##=======================================================================

exports.V2 = class V2 extends Base
  
  ##-----------------------------------------
  
  constructor : (i) -> super i
  version : () -> 2

  ##-----------------------------------------
  
  run_key_derivation : (compute_hook, cb) ->
    
    ret = null

    # The initial setup as per PBKDF2, with email as the salt
    hmac = C.algo.HMAC.create C.algo.SHA512, @passphrase()
    block_index = C.lib.WordArray.create [ 0x1 ]
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
        intermediate = hmac.finalize intermediata
        hmac.reset()
        block[j] ^= w for w,j in intermediate
        i++
      else
        break

    ret = block.toString C.enc.Base64 if i is limit
    cb ret
          
  ##-----------------------------------------

  finalize : (dk, cb) ->
    i = 0
    ret = null
    
    until ret
      a = [ "OneShallPass v2.0", @email(), @host(), @generation(), i ]
      txt = a.join '; '
      hash = C.HmacSHA512 text, dk
      b64 = hash.toString C.enc.Base64
      ret = b64 if @is_ok_pw b64
      i++

    cb ret
    
  ##-----------------------------------------
  
