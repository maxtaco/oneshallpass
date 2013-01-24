
{config} = require './config'

##=======================================================================

class Client

  constructor : (@_eng) ->

  derive_key : (mode, cb) ->
    inp = @_eng.new_input mode, config.server
    
    # We're going to force use of this version object, regardless of what
    # the input says.  In practice, we're going to be using V2 for MAC and AES,
    # even though V1 might still be used for WEB_PWs....
    inp.derive_key cb
      
  login : () ->
    await @derive_key derive.keymodes.LOGIN_PW, defer pwh
    args =
      email : @_eng._inp.get 'email'
      pwh : pwh
