
purepack = require 'purepack'
{prng} = require './prng'
C = CryptoJS

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

exports.unpack_from_word_array = unpack_from_word_array = (wa) ->
  ui8a = wa.toString Ui8a
  purepack.unpack ui8a, 'ui8a'

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

  compute_mac : (mac_obj) ->
    wa = pack_to_word_array mac_obj
    C.HmacSHA256 wa, @_mac_key
    
  ##-----------------------------------------

  verify_mac : (obj, received) ->
    {words} = @compute_mac obj
    if received.length isnt words.length then return false
    for w,i in received
      return false unless w is words[i]
    return true

  ##-----------------------------------------

  encrypt : (obj) ->
    words = pack_to_word_array obj
    iv = prng.to_cryptojs_word_array C.algo.AES.blockSize

    # The encyrpt algorithm returns a whole bunch of stuff that
    # we don't need.  Just the ciphertext, please!
    {ciphertext} = C.AES.encrypt words, @_aes_key, { iv }

    # This depends on the fact that all words are fully populated,
    # which they are..
    mac_obj = [ ciphertext.words,  iv.words ]

    # Take as input the above array, and output another word array
    # in CryptoJS style....
    mac = @compute_mac mac_obj

    # This is the final layout...
    vers = 1
    out_obj = [ vers, mac.words ].concat mac_obj

    # And finish up by encoding to base64
    purepack.pack out_obj, 'base64'
  
  ##-----------------------------------------

  # how to encrypt:
  #   pick random iv with prng...
  #   C.AES.encrypt msg, key, { iv }
  #   i think msg and key should both be WordArrays... 
  decrypt_aes : (ctxt, iv) ->
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
    [ err, unpacked ] = purepack.unpack v, 'base64'
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
    else if not ([err, ret] = unpack_from_word_array pt)? or err?
      @hit_error "Failed to decode plaintext", err, name
      @_decode_errors++
    ret

##=======================================================================

testit = () ->
  ak = C.lib.WordArray.create [0...8]
  mk = C.lib.WordArray.create [100...108]
  cryptor = new Cryptor ak, mk
  
  obj = { a : 1, b : 2, c : [0,1,2,3], d : "holy smokes", e : false }
  console.log "Obj ->"
  console.log obj
  
  e = cryptor.encrypt obj
  console.log "Enc ->"
  console.log e

  d = cryptor.decrypt e, "stuff"
  console.log "Dec ->"
  console.log d
  console.log cryptor.finish()

##=======================================================================
