
##=======================================================================

exports.Dummy = class Dummy
  constructor : (@_o) ->
  getElementById : (x) -> @[x]
  q : (x) ->  @getElementById x

##=======================================================================

exports.Browser = class Browser

  constructor : (@_o) ->

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
    
##=======================================================================
