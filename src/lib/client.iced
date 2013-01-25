
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

  #-----------------------------------------

  toggle : (b) ->
    @_active = b
    if b then @login()
    else      @poke()

  #-----------------------------------------
  
  poke : () ->
    if (c = @_poke_cb)?
      @_poke_cb = null
      c()
    else @login()

  #-----------------------------------------

  get_login_input : (cb) ->
    inp = @_eng.fork_input derive.keymodes.LOGIN_PW, config.server
    while not inp.is_ready() and @_active
      await @_poke_cb = defer()
    inp = null unless @_active
    cb inp
   
  #-----------------------------------------

  do_fetch : () ->

  #-----------------------------------------

  package_args : (cb) ->
    await @get_login_input defer inp
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

  login : (bgloop, cb) ->
    try_again = false
    await @package_args defer args
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
        { @session } = res.data
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
      
