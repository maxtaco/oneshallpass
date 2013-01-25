
{config} = require './config'
derive   = require './derive'
util     = require './util'

states =
  NONE : 0
  LOGGED_IN : 1
  VERIFIED : 2
  WAITING_FOR_INPUT : 3

##=======================================================================

ajax = (url, data, method, cb) ->
  error = (x, status, error_thrown) ->
    cb { ok : false, status : x.status, data : null }
  success = (data, status, x) ->
    cb { ok: true, status : x.status, data }
  $.ajax { dataType : "json", url, data, success, error, type : method }

##=======================================================================

exports.Client = class Client

  #-----------------------------------------

  constructor : (@_eng) ->
    @_active = false
    @_state = states.NONE
    @_doc = @_eng.doc
    @_session = null
    @_inp = null

  #-----------------------------------------

  toggle : (b) ->
    @_active = b
    if b then @login()

  #-----------------------------------------

  do_fetch : () ->

  #-----------------------------------------

  package_args : (cb) ->
    inp = @_eng.fork_input derive.keymodes.LOGIN_PW, config.server
    if not inp.is_ready()
      @doc().set_sync_status false, "need email and passphrase"
      inp = null
    res = null
    if inp? and not util.is_email(email = inp.get 'email')
      @doc().set_sync_status false, "Invalid email address"
      inp = null
    if inp?
      await inp.derive_key defer pwh if inp?
    if pwh?
      @doc().finish_key inp.keymode
      res = { pwh, email }
    cb res
    
  #-----------------------------------------
  
  doc : -> @_eng._doc
  
  #-----------------------------------------

  login_loop : () ->
    try_again = true
    while try_again 
      await setTimeout defer(), 5*1000
      await @login true, defer try_again
 
  #-----------------------------------------

  same_args : (args) ->
    for k,v of args
      return false unless @_login_args[k] is v
    return true
   
  #-----------------------------------------

  login : (bgloop, cb) ->
    try_again = false
    await @package_args defer args

    # don'e bother logging in again if we're already there
    if @_session? and @_login_args? and @same_args args
      @doc().set_sync_status true, "Signed in"
      args = null
    
    if args?
      @doc().set_sync_status true, "Logging in...." unless bgloop
      await ajax "/user/login", args, "POST", defer res
      if res.status isnt 200 or not (code = res?.data?.status?.code)?
        @doc().set_sync_status false, "The server is down (status=#{status})"
      else if code isnt 0
        try_again = true
        @doc().show_signup() unless bgloop
      else
        @doc().set_sync_status true, "Sign-in successful"
        @_login_args = args
        @_session = res.data.session
        console.log 
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
      if res.status isnt 200 or not (code = res.data?.status?.code)?
        @doc().set_sync_status false, "The server is down (status=#{status})"
      else
        @doc().set_sync_status true, "Check #{em} for verification"
        @login_loop()
      
