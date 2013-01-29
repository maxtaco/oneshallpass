
##=======================================================================

exports.Prng = class Prng

  constructor : () ->

  to_cryptojs_word_array : (n) ->
    b = new Int32Array n
    window.crypto.getRandomValues b
    # Convert to a conventional JavaScript array....
    v = (i for i in b)
    CryptoJS.lib.WordArray.create v


##=======================================================================

exports.prng = new Prng()
