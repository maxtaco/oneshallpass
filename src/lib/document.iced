
{config} = require './config'

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

  show_computing : (s) ->
    @toggle_result 'computing'
    @q("result-computing").value = "Computing....#{s}"

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
