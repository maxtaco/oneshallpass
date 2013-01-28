@._stitchings = {}

metastitch_module = (mod) ->
  @._stitchings[mod] = @.require
  @.require = null

metastitch_finish = () ->
  active_require = @.require
  @.require = (name) ->
    console.log "new require #{name}"
    p = name.split '/'
    console.log "part1 = #{p[0]}"
    console.log "stored = #{_stitchings[p[0]]}"
    if p.length and p[0]? and (rqfn = _stitchings[p[0]])?
      rest = p[1...].join '/'
      rqfn rest
    else
      active_require name

      
