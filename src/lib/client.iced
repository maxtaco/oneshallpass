
{config} = require './config'
derive   = require './derive'

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
    console.log "GLI!"
    inp = @_eng.fork_input derive.keymodes.LOGIN_PW, config.server
    while not inp.is_ready() and @_active
      console.log "waiting...."
      await @_poke_cb = defer()
    console.log "ready...."
    inp = null unless @_active
    cb inp
   
  #-----------------------------------------

  do_fetch : () ->

  #-----------------------------------------

  login : () ->
    await @get_login_input defer inp
    await inp.derive_key defer pwh if inp?
    if pwh?
      args = { pwh , email: inp.get 'email' }
      await ajax "/user/login", args, "POST", defer res
      doc = @_eng._doc
      console.log "BAACK"
      console.log res
      if res.status isnt 200 or not (code = res.data?.status?.code)?
        doc.set_login_status false, "The server is down (status=#{status})"
      else if code isnt 0
        doc.show_signup()
      else
        doc.set_login_status true, "Sign-in successful"
        { @session } = data
        @do_fetch()
        
