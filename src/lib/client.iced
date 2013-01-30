
{config} = require './config'
derive   = require './derive'
util     = require './util'
purepack = require 'purepack'
crypt    = require './crypt'

states =
  NONE : 0
  LOGGED_IN : 1
  VERIFIED : 2
  WAITING_FOR_INPUT : 3

ENCODING = "base64"
C = CryptoJS
 
##=======================================================================

exports.Record = class Record
  constructor : (@key, @value, @encrypted = false) ->
    
  encrypt : (cryptor) ->
    k = cryptor.encrypt @key, false
    v = cryptor.encrypt @value, true
    return new Record k, v, true

  decrypt : (cryptor) ->
    [k,v] = (cryptor.decrypt f for f in [ @key, @value] )
    return new Record k,v,false if k? and v?

  to_ajax : () -> { rkey : @key, rvalue : @value }

##=======================================================================

exports.Client = class Client

  #-----------------------------------------

  constructor : (@_eng) ->
    @_active = false
    @_state = states.NONE
    @_session = null
    @_records = {}

  #-----------------------------------------

  toggle : (b) ->
    @_active = b
    if b then @login()
    else
      @_session = null
      @doc().set_logged_in false

  #-----------------------------------------

  do_fetch : () ->
    await @prepare_keys defer ok
    await @fetch_records defer recs if ok
    ok = @decrypt_records recs if recs? and ok
    @doc().set_records @_records if ok

  #-----------------------------------------

  decrypt : (v, name) ->
    @_cryptor.decrypt v, name
  
  #-----------------------------------------

  store_record : (r) -> @_records[r.key] = r.value
  
  #-----------------------------------------

  decrypt_records : (records) ->
    for er in records
      @store_record dr if (dr = er.decrypt @_cryptor)?
    ok = true
    if (eo = @_cryptor.finish())?
      ok = false
      @doc().set_sync_status false, "Decryption errors, see log for more info"
    return ok
   
  #-----------------------------------------

  check_res : (res) -> 
    if res.status isnt 200 or not (code = res?.data?.status?.code)?
      @doc().set_sync_status false, "The server is down (status=#{res.status})"
    return code
   
  #-----------------------------------------

  fetch_records : (cb) ->
    out = null
    await @ajax "/records", {}, "GET", defer res
    if (code = @check_res res)? and code is 0
      out = (new Record row.rkey, row.rvalue, true for row in res.data?.data)
    cb out
   
  #-----------------------------------------

  prepare_keys : (cb) ->
    ok = false
    await @prepare_key derive.keymodes.RECORD_HMAC, defer @_hmac
    await @prepare_key derive.keymodes.RECORD_AES, defer @_aes if @_hmac
    if (@_aes and @_hmac)?
      @_cryptor = new crypt.Cryptor @_aes, @_hmac
      ok = true
    cb ok

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

  login : (cb) ->
    rc = null
    await @package_args defer args, inp
    if not args? then rc = src.BAD_ARGS
    else
      await @ajax "/user/login", args, "POST", defer res
      rc = if not (code = @check_res res)? then sc.SERVER_DOWN
      else if code isnt 0                  then sc.BAD_LOGIN
      else
        @_session = res.data.session
        await @do_fetch defer rc
    cb rc
        
  #-----------------------------------------
    
  signup : () ->
    await @package_args defer args
    if args?
      em = args.email
      @doc().set_sync_status true, "Signing up email #{em}"
      await @ajax "/user/signup", args, "POST", defer res
      err = null
      if (code = @check_res res)?
        @doc().set_sync_status true, "Check #{em} for verification"
        @login_loop()
      
  ##-----------------------------------------
  
  ajax : (url, data, method, cb) ->
    error = (x, status, error_thrown) ->
      cb { ok : false, status : x.status, data : null }
    success = (data, status, x) ->
      cb { ok: true, status : x.status, data }
    data.session = @_session if @_session
    $.ajax { dataType : "json", url, data, success, error, type : method }

  ##-----------------------------------------

  get_record : (k) -> @_records[k]
   
  ##-----------------------------------------

  has_login_info : () -> @_eng.fork_input(mode, config.server).is_ready()
 
  ##-----------------------------------------

  push_record : () ->
    inp = @_eng.get_input()
    rec = inp.to_record()
    @store_record rec
    erec = rec.encrypt @_cryptor
    await @ajax "/records", erec.to_ajax(), "POST", defer res
    if (code = @check_res res)?
      @doc().set_sync_status true, "Push worked for #{inp.get 'host'}"
  
##=======================================================================

