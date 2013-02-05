
purepack = require 'purepack'
C = if CryptoJS? then CryptoJS else null

##=======================================================================

# Fulfill the CryptoJS template
exports.Binary = Binary =
  stringify : (wa) ->
    [v,n] = [wa.words, wa.sigBytes]
    e = String.fromCharCode
    (e((v[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff) for i in [0...n]).join ''
    
##=======================================================================

# Fulfill the CryptoJS template -- we're abusing the 'stringify' interface,
# but it's OK for now...
exports.Ui8a = Ui8a =

  stringify : (wa) ->
    [v,n] = [wa.words, wa.sigBytes]
    out = new Uint8Array n
    (out[i] = ((v[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff) for i in [0...n])
    return out
    
  to_i32a : (uia) ->
    n = uia.length
    nw = (n >>> 2) + (if (n & 0x3) then 1 else 0)
    out = new Int32Array nw
    out[i] = 0 for i in [0...nw]
    for b, i in uia
      out[i >>> 2] |= (b << ((3 - (i & 0x3)) << 3))
    out

##=======================================================================

exports.pack_to_word_array = pack_to_word_array = (obj) ->
  ui8a = purepack.pack(obj, 'ui8a')
  i32a = Ui8a.to_i32a ui8a
  v = (w for w in i32a)
  C.lib.WordArray.create v, ui8a.length

##=======================================================================

exports.unpack_from_word_array = unpack_from_word_array = (wa) ->
  ui8a = wa.toString Ui8a
  purepack.unpack ui8a, 'ui8a'

##=======================================================================

