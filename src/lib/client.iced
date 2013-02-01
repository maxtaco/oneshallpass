
{config} = require './config'
derive   = require './derive'
util     = require './util'
purepack = require 'purepack'
crypt    = require './crypt'
sc       = require('./status').codes

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

  to_dict : () ->
    d = {}
    (d[k] = v for k,v of @value)
    d.host = @key
    return d

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

  do_fetch : (cb) ->
    rc = sc.OK
    await @prepare_keys defer rc
    await @fetch_records defer rc, recs if rc is sc.OK
    rc = @decrypt_records recs if rc is sc.OK
    cb rc

  #-----------------------------------------

  decrypt : (v, name) ->
    @_cryptor.decrypt v, name
  
  #-----------------------------------------

  store_record : (r) -> @_records[r.key] = r
  
  #-----------------------------------------

  decrypt_records : (records) ->
    for er in records
      @store_record dr if (dr = er.decrypt @_cryptor)?
    rc = sc.OK
    if (eo = @_cryptor.finish())?
      rc = sc.BAD_DECODE
      console.log "Decoding errors: #{JSON.stringify eo}"
    return rc
   
  #-----------------------------------------

  check_res : (res) ->
    if res.status is 200 then res?.data?.status?.code
    else null
   
  #-----------------------------------------

  fetch_records : (cb) ->
    records = null
    rc = sc.OK
    await @ajax "/records", {}, "GET", defer res
    if (code = @check_res res)? and code is 0
      records = (new Record row.rkey, row.rvalue, true for row in res.data?.data)
    else
      rc = sc.BAD_FETCH
    cb rc, records
   
  #-----------------------------------------

  prepare_keys : (cb) ->
    await @prepare_key derive.keymodes.RECORD_HMAC, defer @_hmac
    await @prepare_key derive.keymodes.RECORD_AES, defer @_aes if @_hmac
    rc = if (@_aes and @_hmac)?
      @_cryptor = new crypt.Cryptor @_aes, @_hmac
      sc.OK
    else
      sc.BAD_DERIVE
    cb rc

  #-----------------------------------------

  prepare_key : (mode, cb) ->
    inp = @package_input mode
    await inp.derive_key defer key if inp?
    cb key, inp
    
  #-----------------------------------------

  package_input : (mode) ->
    inp = @_eng.fork_input mode, config.server
    if not inp.is_ready()
      inp = null
    res = null
    if inp? and not util.is_email inp.get 'email'
      inp = null
    return inp
    
  #-----------------------------------------

  package_args : (cb) ->
    if not (inp = @package_input derive.keymodes.LOGIN_PW)?
      rc = sc.BAD_ARGS
    else
      await inp.derive_key defer pwh
      if pwh?
        res = { pwh, email : inp.get 'email' }
        rc = sc.OK
      else
        rc = sc.BAD_DERIVE
    cb rc, res, inp
    
  #-----------------------------------------
  
  doc : -> @_eng._doc
  
  #-----------------------------------------

  login_loop : () ->
    try_again = true
    while try_again 
      await setTimeout defer(), 5*1000
      await @login true, defer try_again
 
  #-----------------------------------------
 
  is_logged_in : () -> @_session
  
  #-----------------------------------------

  logout : (cb) ->
    rc = sc.OK
    if @is_logged_in() then @_session = null
    else rc = sc.BAD_LOGIN
    cb rc if cb?
    
  #-----------------------------------------

  login : (cb) ->
    rc = if @is_logged_in() then sc.LOGGED_IN else sc.OK
    await @package_args defer rc, args, inp
    code = null
    if rc is sc.OK
      await @ajax "/user/login", args, "POST", defer res
      if not (code = @check_res res)?      then rc = sc.SERVER_DOWN
      else if code isnt 0                  then rc = sc.BAD_LOGIN
      else
        @_session = res.data.session
        await @do_fetch defer rc
    cb rc
        
  #-----------------------------------------
    
  signup : (cb) ->
    await @package_args defer rc, args
    if rc is sc.OK
      await @ajax "/user/signup", args, "POST", defer res
      if not (@check_res res)? then rc = sc.SERVER_DOWN
    cb rc
      
  ##-----------------------------------------
  
  ajax : (url, data, method, cb) ->
    error = (x, status, error_thrown) ->
      cb { ok : false, status : x.status, data : null }
    success = (data, status, x) ->
      cb { ok: true, status : x.status, data }
    data.session = @_session if @_session
    $.ajax { dataType : "json", url, data, success, error, type : method }

  ##-----------------------------------------

  get_stored_records : -> (v.to_dict() for k,v of @_records)
   
  ##-----------------------------------------

  push_record : (cb) ->
    rc = sc.OK
    inp = @_eng.get_input()
    rec = inp.to_record()
    if rec
      @store_record rec
      erec = rec.encrypt @_cryptor
      await @ajax "/records", erec.to_ajax(), "POST", defer res
      if not (@check_res res)? then rc = sc.SERVER_DOWN
    else
      rc = sc.BAD_ARGS
    
    cb rc
  
  ##-----------------------------------------

  timeout : () -> config.timeouts.client
  clear : () ->
    @logout()
    @_records = {}
   

##=======================================================================

