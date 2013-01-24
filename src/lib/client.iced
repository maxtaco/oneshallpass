
{config} = require './config'
derive   = require './derive'

states =
  NONE : 0
  LOGGED_IN : 1
  VERIFIED : 2
  WAITING_FOR_INPUT : 3
  
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

  login : () ->
    await @get_login_input defer inp
    await inp.derive_key defer pwh if inp?
    if pwh?
      args =
        email : inp.get 'email'
        pwh   : pwh
      console.log args
