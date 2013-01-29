
purepack = require 'purepack'

##=======================================================================

# Fulfill the CryptoJS template
Binary =
  stringify : (wa) ->
    [v,n] = [wa.words, wa.sigBytes]
    e = String.fromCharCode
    (e((v[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff) for i in [0...n]).join ''
    
# Fulfill the CryptoJS template -- we're abusing the 'stringify' interface,
# but it's OK for now...
exports.Ui8a = Ui8a =

  stringify : (wa) ->
    [v,n] = [wa.words, wa.sigBytes]
    out = new Uint8Array n
    (out[i] = ((v[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff) for i in [0...n])
    return out
    
  to_word_array : (uia) ->
    n = uia.length
    nw = (n >>> 2)  + (if (n & 0x3) then 1 else 0)
    out = new Int32Array nw
    out[i] = 0 for i in [0...nw]
    for b, i in uia
      out[i >>> 2] |= (b << (24 - (i % 4)*8))
    out

##=======================================================================

exports.Cryptor = class Cryptor

  ##-----------------------------------------

  constructor : (@_aes_key, @_mac_key) ->
    @_errors = []
    @_mac_errors =  0
    @_decode_errors = 0
    @_aes_errors = 0
    @_successes = 0

  ##-----------------------------------------

  finish : () ->
    out = null
    if @_errors.length?
      out = @_errors
      @_errors = []
    out

  ##-----------------------------------------

  hit_error : (error, value, type) ->
    @_errors.push { error, value, type }

  ##-----------------------------------------

  verify_mac : (obj, received) ->
    packed = purepack.pack obj, ENCODING
    macer = C.algo.HMAC.create C.algo.SHA256, @_mac_key
    computed = macer.update(packed).finalize().toString Binary
    return (computed is received)

  ##-----------------------------------------

  # how to encrypt:
  #   pick random iv with prng...
  #   C.AES.encrypt msg, key, { iv }
  #   i think msg and key should both be WordArrays... 
  decrypt_aes : (iv, ctxt) ->
    # Create a cryptoJS object
    #  - iv is an array of signed int32s, that we get from msgpack.
    #    It should be 4 words long, as per AES-256-CBC mode
    #  - ciphertext is an array of 32-bit words
    iv = C.lib.WordArray.create iv
    ctxt = C.lib.WordArray.create ctxt
    cfg = { iv }
    cp = C.lib.CipherParams.create { ciphertext : ctxt }
    C.AES.decrypt cp, @_aes_key, cfg

  ##-----------------------------------------

  decrypt : (v, name) ->
    ret = null
    try
      unpacked = purepack.unpack v, ENCODING
    catch e
      err = e
    if err?
      @hit_error err, v, name
      @_decode_errors++
    else if not (Array.isArray unpacked)
      @hit_error "needed an array", unpacked.toString(), name
      @_decode_errors++
    else if unpacked[0] isnt 1
      @hit_error "only can decode version 1", unpacked[0], name
      @_decode_errors++
    else if unpacked.length isnt 4
      @hit_error "needed 4 fields in array", unpacked.length, name
      @_decode_errors++
    else if not @verify_mac unpacked[2..3], unpacked[1]
      @hit_error "MAC mismatch", unpacked.toString(), name
      @_mac_errors++
    else if not (pt = @decrypt_aes unpacked[2], unpacked[3], name)?
      @hit_error "Decrypt failure", unpacked.toString(), name
      @_aes_errors++
    else if not (ui8a = pt.stringify Ui8a)? or
            not ([err, unpacked] = purepack.unpack ui8a, 'ui8a')? or err?
      @hit_error "Failed to decode plaintext", pt, name
      @_decode_errors++
    else
      ret = unpacked
    ret

##=======================================================================
