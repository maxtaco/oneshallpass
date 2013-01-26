
##=======================================================================

exports.Prng = class Prng

  constructor : () ->

  to_cryptojs_word_array : (n) ->
    b = new Uint32Array n
    window.crypto.getRandomValues b
    CryptoJS.lib.WordArray.create b


##=======================================================================

exports.prng = new Prng()
