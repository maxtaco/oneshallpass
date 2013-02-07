
class Frontend
  constructor : ->
    @attach_ux_events()


  attach_ux_events : ->

$ ->
  new Frontend()

config = 
  defaults : 
    entropy : 58
    vary : 5

now = () -> (new Date).getTime()

rand_word = () ->
  a = new Uint32Array(1)
  window.crypto.getRandomValues(a)
  a[0]

class Engine 
  constructor : (defaults) ->
    for k in [ 'entropy']
      v = defauts[k] or config.defaults[k]
      @["_#{k}"] = v
    @_seed = []
    @_last_n = []
    @_rand_shorts = []
    @_seed = [ now() ]
    @_first_gen = null

  current_entropy : () -> @_seed.length
  needed_entropy : () -> config.defaults.entropy
  enough_entropy : () -> @current_entropy() >= @needed_entropy()

  got_input : (kc) ->
    if not (kc in @_last_n)
      @_last_n.shift() if @_last_n.length is config.defaults.vary
      @_last_n.push kc
      @_seed.push ((now() & 0xffff) | (kc << 16))
      @_seed.push rand_word()
      true
    else false

  generate : () ->
    wa = CryptoJS.lib.WordArray.create @_seed
    digest = CryptoJS.SHA512 wa
    (digest.words[i] ^= @_seed[i % @_seed.length] for w,i in digest.words)
    out = CryptoJS.SHA512 digest
    @_seed = out.words[0...].concat @_seed

