
exports.unix_time = () ->
  Math.floor (new Date).getTime()/1000

exports.is_email = (e) ->
  x = /[^\s@]+@[^\s@.]+\.[^\s.@][^\s@]*/
  return e.match x
