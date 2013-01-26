
{config} = require './config'
derive   = require './derive'
util     = require './util'

states =
  NONE : 0
  LOGGED_IN : 1
  VERIFIED : 2
  WAITING_FOR_INPUT : 3

ENCODING = "base64"
C = CryptoJS

##=======================================================================

ajax = (url, data, method, cb) ->
  error = (x, status, error_thrown) ->
    cb { ok : false, status : x.status, data : null }
  success = (data, status, x) ->
    cb { ok: true, status : x.status, data }
  $.ajax { dataType : "json", url, data, success, error, type : method }

##=======================================================================

# Fulfill the CryptoJS template
Binary =
  stringify : (wa) ->
    v = wordArray.words
    n = wordArray.sigBytes
    (((v[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff) for i in [0...n]).join ''
  to_wordArray: (b) ->
    

##=======================================================================

exports.Decryptor = class Decryptor

  constructor : (@_aes_key, @_mac_key) ->
    @_errors = []
    @_mac_errors =  0
    @_decode_errors = 0
    @_aes_errors = 0
    @_successes = 0

  hit_error : (error, value, type) ->
    @_errors.push { error, value, type }

  verify_mac : (obj, receive) ->
    packed = purepack.pack obj, ENCODING
    macer = C.algo.HMAC.create C.algo.SHA256, @_mac_key
    computed = macer.update(packed).finalize().toString Binary
    return (computed is receive)

  decrypt_aes : (iv, ciphertext) ->

    # Create a cryptoJS object
    iv = C.lib.WordArray.create(iv)

  decrypt : (v, name) ->
    ret = null
    [err, unpacked] = purepack.unpack v, ENCODING
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
    else if not (pt = @decrypt_aes unpacked[2], unpacked[3])?
      @hit_error "Decrypt failure", unpacked.toString(), name
      @_aes_errors++
    else if not ([err, unpacked] = purepack.unpack pt, ENCODING)? or err?
      @hit_error "Failed to decode plaintext", pt, name
      @_decode_errors++
    else
      ret = unpacked
    ret

##=======================================================================

exports.Client = class Client

  #-----------------------------------------

  constructor : (@_eng) ->
    @_active = false
    @_state = states.NONE
    @_doc = @_eng.doc
    @_session = null
    @_inp = null
    @_records = {}
    @_decrypt_errors = []

  #-----------------------------------------

  toggle : (b) ->
    @_active = b
    if b then @login()
    else @_session = null

  #-----------------------------------------

  do_fetch : () ->
    await @prepare_keys defer ok
    await @fetch_records defer recs if ok
    ok = @decrypt_recs if recs? and ok

  #-----------------------------------------

  decrypt_error : (e) ->
    @_decrypt_errors.push e
   
  #-----------------------------------------

  decrypt_record : (k,v) ->
    k = @decrypt k, "key"
    v = @decrypt v, "value"
    @_records[k] = v if k? and v?
    
  #-----------------------------------------

  decrypt_records : (encoded_recs) ->
    @_decrypt_errors = []
    for k, v of encoded_recs
      @decrypt_record k, v
    return ok
   
  #-----------------------------------------

  check_res : (res) -> 
    if res.status isnt 200 or not (code = res?.data?.status?.code)?
      @doc().set_sync_status false, "The server is down (status=#{status})"
    return code
   
  #-----------------------------------------

  fetch_records : (cb) ->
    out = null
    ajax "/records", {}, "GET", defer res
    if (code = @check_res res)? and code is 0
      out = res.data
    cb out
   
  #-----------------------------------------

  prepare_keys : (cb) ->
    await @prepare_key derive.keymodes.RECORD_HMAC, defer @_hmac
    await @prepare_key derive.keymodes.RECORD_AES, defer @_aes if @_hmac
    cb (@_aes and @_hmac)

  #-----------------------------------------

  prepare_key : (mode, cb) ->
    inp = @package_input mode
    await inp.derive_key defer key if inp?
    @doc().finish_key mode if inp?
    cb key, inp
    
  #-----------------------------------------

  package_input : (mode) ->
    inp = @_eng.fork_input mode, config.server
    if not inp.is_ready()
      @doc().set_sync_status false, "need email and passphrase"
      inp = null
    res = null
    if inp? and not util.is_email inp.get 'email'
      @doc().set_sync_status false, "Invalid email address"
      inp = null
    return inp
    
  #-----------------------------------------

  package_args : (cb) ->
    if (inp = @package_input derive.keymodes.LOGIN_PW)?
      await inp.derive_key defer pwh
    if pwh?
      @doc().finish_key inp.keymode
      res = { pwh, email : inp.get 'email' }
    cb res, inp
    
  #-----------------------------------------
  
  doc : -> @_eng._doc
  
  #-----------------------------------------

  login_loop : () ->
    try_again = true
    while try_again 
      await setTimeout defer(), 5*1000
      await @login true, defer try_again
 
  #-----------------------------------------

  login : (bgloop, cb) ->
    try_again = false
    await @package_args defer args, inp
    if args?
      @doc().set_sync_status true, "Logging in...." unless bgloop
      await ajax "/user/login", args, "POST", defer res
      if not (code = @check_res res)? then null
      else if code isnt 0
        try_again = true
        @doc().show_signup() unless bgloop
      else
        @doc().set_sync_status true, "Sign-in successful"
        @_login_inp = inp
        @_session = res.data.session
        @do_fetch()
    cb try_again if cb?
        
  #-----------------------------------------
    
  signup : () ->
    await @package_args defer args
    if args?
      em = args.email
      @doc().set_sync_status true, "Signing up email #{em}"
      await ajax "/user/signup", args, "POST", defer res
      err = null
      if (code = @check_res res)?
        @doc().set_sync_status true, "Check #{em} for verification"
        @login_loop()
      
##=======================================================================

