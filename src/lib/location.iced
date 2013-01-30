

##=======================================================================

exports.Location = class Location
  constructor : (@_o) ->
    @_u = @decode_url_params()

  decode_url_params : () ->
    ret = {}
    pl = /\+/g  # Regex for replacing addition symbol with a space
    search = /([^&=]+)=?([^&]*)/g # search an NV/pair
    decode = (s) -> decodeURIComponent s.replace(pl, " ")
    q = @_o.hash.substring 1
    ret[decode m[1]] = decode m[2] while (m = search.exec q)
    ret

  get : (k) -> @_u[k]
    

##=======================================================================

