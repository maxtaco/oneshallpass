##=======================================================================

config = 
  defaults : 
    entropy : 58
    vary : 5
    initial_keep : 2

##=======================================================================

class Frontend
  constructor : ->
    @eng = new Engine
    @attach_ux_events()
    @_first_output = null

  got_input : (kc) ->
    pp = @eng.got_input kc
    @got_passphrase pp

  in_initial_keep_window : () ->
    @_first_output? and (now() - @_first_output < config.defaults.initial_keep*1000)

  got_passphrase : (pp) ->
    msg = if @in_initial_keep_window() then null
    else if pp
      @_first_output = now() unless @_first_output?
      pp
    else if not @eng.enough_entropy()
      "Collected #{@eng.current_entropy()} of #{@eng.needed_entropy()}; need MORE"
    else null

    $('#output-passphrase').val msg if msg?

  set_entropy : (i) ->
    @eng.set_entropy i
    @got_passphrase @eng.generate_passphrase()

  attach_ux_events : ->

    self = @

    # Clear default text and ungray upon modification
    $('#input-seed').focus ->
      if not $(@).hasClass 'modified'
        $(@).val ''
        $(@).addClass 'modified'

    # Attempt to generate a new passphrase upon each keypress
    $('#input-seed').keyup (event) =>
      self.got_input event.keyCode

    $('#input-entropy').change () ->
      self.set_entropy parseInt $(@).val()


##=======================================================================

$ ->
  new Frontend()

##=======================================================================

now = () -> (new Date).getTime()

rand_word = () ->
  a = new Uint32Array(1)
  window.crypto.getRandomValues(a)
  a[0]

sha = (a) -> CryptoJS.SHA512 CryptoJS.lib.WordArray.create a

log2 = (x) -> (Math.log x)/(Math.log 2)

##=======================================================================

class KeyCodeBuffer
  constructor : (@len) ->
    @_b = []

  push : (kc) ->
    if not (kc in @_b)
      @_b.shift() if @_b.length is @len
      @_b.push kc
      true
    else false

##=======================================================================

class Engine 

  #-----------------------------------------

  constructor : (defaults) ->
    @_seed = []
    @_kcb = new KeyCodeBuffer config.defaults.vary
    @_needed_entropy = config.defaults.entropy
    @_rand_shorts = []
    @_seed = [ now() ]
    @_first_gen = null
    @_last_hash = null

  #-----------------------------------------

  current_entropy : () -> @_seed.length
  needed_entropy : () -> @_needed_entropy
  set_entropy : (n) -> @_needed_entropy = n
  enough_entropy : () -> @current_entropy() >= @needed_entropy()

  #-----------------------------------------

  got_input : (kc) ->
    if (@_kcb.push kc) or @enough_entropy()
      @_push_input kc
      @generate_passphrase()
    else null

  #-----------------------------------------

  generate_passphrase : ->
    if @enough_entropy()
      d = dict.words
      n = Math.ceil(@needed_entropy() / log2(d.length))
      (d[@_gen_mod_n d.length] for i in [0...n]).join " "
    else 
      null

  #-----------------------------------------
  
  _push_input : (kc) ->
    @_seed.push ((now() & 0xffff) | (kc << 16))
    @_seed.push rand_word()

  _gen_short : ->
    @_recharge() if @_rand_shorts.length is 0
    @_rand_shorts.pop()

  _gen_mod_n : (n) ->
    nbits = Math.ceil log2 n
    res = -1
    mask = ~(0x7fffffff << nbits)
    while res < 0 or res >= n
      res = (@_gen_short() & mask)
    res

  _recharge : () ->
    @_last_hash = sha @_seed if not @_last_hash
    @_last_hash = tmp = sha @_seed.concat @_last_hash
    for w in tmp.words
      @_rand_shorts.push (w & 0xffff) 
      @_rand_shorts.push (w >>> 16)

##=======================================================================
