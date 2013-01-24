
{config} = require './config'
derive = require './derive'

##=======================================================================

exports.Dummy = class Dummy
  constructor : (@_o) ->
  getElementById : (x) -> @[x]
  q : (x) ->  @getElementById x

##=======================================================================

exports.Browser = class Browser

  constructor : (@_o) ->

  timeout : () -> config.timeouts.document
  clear : () -> @q('passphrase').value = ""

  getElementById : (x) -> @_o.getElementById x
  q : (x) ->  @getElementById x
  
  set_generated_pw : (dk) ->
    @toggle_result 'done'
    @q("result-done").value = dk

  toggle_result : (s) ->
    for f in [ 'waiting', 'done', 'computing' ]
      @q("result-td-#{f}").style.display = if s is f then 'inline' else 'none'

  show_computing : (s, mode) ->
    txt ="Computing....#{s}"

    # These cases are handled slightly differently because the result
    # field for Web PWs is an input field, and the others are dummy
    # HTML...
    if mode is derive.keymodes.WEB_PW
      @toggle_result 'computing'
      @q("result-computing").value = txt
    else
      field = switch mode
        when derive.keymodes.LOGIN_PW    then "login-pw-status"
        when derive.keymodes.RECORD_AES  then "encryption-key-status"
        when derive.keymodes.RECORD_HMAC then "mac-key-status"
        else null
      @q(field).innerHTML = txt if field?

  get_obj : (o) -> if typeof o is 'string' then @q o else o

  autofill : (k, v) ->
    obj = @q k
    obj.value = v
    ungrey obj

  ungrey : (o) ->
    black_style = "input-black"
    if o.className.match black_style then false
    else
      o.className += " " + black_style
      true
      
    
##=======================================================================
