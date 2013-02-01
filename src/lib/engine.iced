
util = require './util'
{config} = require './config'
derive = require './derive'
{Client,Record} = require './client'

##=======================================================================

class Cache
  constructor : () ->
    @_c = {}

  timeout : () -> config.timeouts.cache
  clear : () -> @_c = {}

  lookup : (k) ->
    obj = @_c[k] = {} unless (obj = @_c[k])?
    return obj

##=======================================================================

input_trim = (x) ->
  if x and x?
    x = x.replace /\s+/g, " "
    rxx = /^(\s*)(.*?)(\s*)$/
    m = x.match rxx
    m[2]
  else ""
  
input_clean = (x) ->
  ret = input_trim(x).toLowerCase()
  ret = null if ret.length is 0
  ret

input_clean_preserve_case = (x) ->
  ret = input_trim(x)
  ret = null if ret.length is 0
  ret

##=======================================================================

class VersionObj
  constructor : (args)->
  
  @make : (v, args) ->
    switch v
      when 1 then new Version1Obj args
      when 2 then new Version2Obj args
      else null
      
##-----------------------------------------------------------------------

class Version1Obj extends VersionObj

  constructor : (@_args) ->
  
  clean_passphrase : (pp) ->
    # Replace any interior whitepsace with just a single
    # plain space, but otherwise, interior whitespaces count
    # as part of the passphrase
    ret = input_trim(pp).replace /\s+/g, " "
    ret = null unless ret.length
    ret

  key_fields : -> [ 'email', 'passphrase', 'host', 'generation', 'security_bits' ]
  key_deriver : (i) -> new derive.V1 i
  version : () -> 1
  
##-----------------------------------------------------------------------

class Version2Obj extends VersionObj

  constructor : (@_args) ->
    
  clean_passphrase : (pp) ->
    # strip out all spaces!
    ret = pp.replace /\s/g, ""
    ret = null unless ret.length
    ret
    
  key_fields : -> [ 'email', 'passphrase', 'security_bits' ]
  key_deriver : (i) -> new derive.V2 i 
  version : () -> 2
        
##=======================================================================

copy_dict = (input) ->
  ret = {}
  (ret[k] = v for k,v of input)
  ret

##=======================================================================

class Input
  
  constructor: ({ @engine, @keymode, @fixed, presets }) ->
    
    @keymode = derive.keymodes.WEB_PW unless @keymode?
    @fixed = {} unless @fixed?
    
    # Three fields: (1) if required to be non-empty; (2) if used in server push
    # and (3), a validator
    SELECT = [ true, true, null ]
    @_template =
      host : [ true, false , (x) -> input_clean x ]
      passphrase : [ true, false, (x) => @_clean_passphrase x ]
      email :  [ true, true, (x) -> input_clean x ]
      notes : [ false, true, (x) -> input_clean_preserve_case x ]
      algo_version : SELECT
      length : SELECT
      security_bits : SELECT
      num_symbols : SELECT
      generation : SELECT
      no_timeout : [ false, false, null ]
    @_defaults = config.input.defaults
    @_values = if presets? then copy_dict presets else {}
    
  #-----------------------------------------

  fork : (keymode, fixed) ->
    out = new Input { @engine, keymode, fixed, presets : @_values }
    out
  
  #-----------------------------------------
  
  get_version_obj : () -> VersionObj.make @get 'algo_version'
  timeout : () -> config.timeouts.input
  clear : -> 

  #-----------------------------------------
  
  # Serialize the input and assign it a unique ID
  unique_id : (version_obj) ->
    version_obj = @get_version_obj() unless version_obj
    parts = [ version_obj.version(), @keymode ]
    fields = (@get f for f in version_obj.key_fields())
    all = parts.concat fields
    all.join ";"

  #-----------------------------------------
  
  derive_key : (cb) ->
    # the compute hook is called once per iteration in the inner loop
    # of key derivation.  It can be used to stop the derivation (by returning
    # false) and also to report progress to the UI

    vo = @get_version_obj()
    uid = @unique_id vo
    
    compute_hook = (i, tot) =>
      if (ret = (uid is @unique_id(vo))) and i % 10 is 0
        @engine.on_compute_step @keymode, i, tot
      ret

    co = @engine._cache.lookup uid

    await (vo.key_deriver @).run co, compute_hook, defer res
    @engine.on_compute_done @keymode, res if res
    cb res

  #-----------------------------------------

  get : (k) ->
    if (f = @fixed[k])? then f
    else if (v = @_values[k])? then v
    else @_defaults[k]
      
  #-----------------------------------------
  
  set : (k, val) ->
    val = tem(val) if (tem = @_template[k]?[2])?
    @_values[k] = val
  
  #-----------------------------------------

  _clean_passphrase : (pp) -> @get_version_obj().clean_passphrase pp

  #-----------------------------------------

  is_ready : () ->
    for k,row of @_template when row[0]
      return false if not (v = @get k)?
    true
    
  #-----------------------------------------

  to_record : () ->
    d = {}
    for k, row of @_template when row[1] and (v = @get k)
      if row[0] and not v? then return null
      d[k] = v
      
    if (host = @get 'host') then new Record host, d
    else null
      
##=======================================================================

class Timer

  #-----------------------------------------
  
  constructor : (@_obj) ->
    @_last_set = null
    
  #-----------------------------------------

  force : () ->
    @_obj.clear()
    @clear()
   
  #-----------------------------------------
  
  set : () ->
    now = util.unix_time()

    hook = () =>
      @_obj.clear()
      @_id = null
      @_last_set = null

    # Only set the timer if we haven't set it recently....
    if not @_id? or not @_last_set? or (now - @_last_set) > 5
      @clear()
      @_id = setTimeout hook, @_obj.timeout()*1000
      @_last_set = now
    
  #-----------------------------------------
  
  clear : () ->
    if @_id?
      clearTimeout @_id
      @_last_set = null
      @_id = null

##=======================================================================

class Timers
  
  constructor : (@_eng) ->
    @_timers = (new Timer o for o in [ @_eng, @_eng._cache ] )
    @_active = false

  poke : () -> @start() if @_active
  
  start : () ->
    @_active = true
    (t.set() for t in @_timers)

  stop : () ->
    @_active = false
    (t.clear() for t in @_timers)

  toggle : (b) ->
    if b and not @_active then @start()
    else if not b and @_active then @stop()

  force : () ->
    (t.force() for t in @_timers)

##=======================================================================

exports.Engine = class Engine
  
  ##-----------------------------------------

  constructor : (opts) ->
    { presets } = opts
    { @on_compute_step, @on_compute_done, @on_timeout } = opts.hooks
    @_cache = new Cache
    @_inp = new Input { engine : @, presets }
    @_client = new Client @
    @_timers = new Timers @
    @_timers.start() unless @_inp.get 'no_timeout'

  ##-----------------------------------------

  client : () -> @_client
  clear : () ->
    @client().clear()
    @on_timeout()
  timeout : () -> config.timeouts.document
  
  ##-----------------------------------------

  poke : () -> @_timers.poke()

  ##-----------------------------------------
  
  set : (k,v) ->
    @_timers.toggle(not v) if k is 'no_timeout'
    @_inp.set k, v
    @poke()
    @maybe_run()
   
  ##-----------------------------------------

  get : (k) -> @_inp.get k
   
  ##-----------------------------------------

  run : () ->
    await @_inp.derive_key defer dk
    
  ##-----------------------------------------

  maybe_run : () -> @run() if @_inp.is_ready()
  
  ##-----------------------------------------

  fork_input : (mode, fixed) -> @_inp.fork mode, fixed
  get_input : () -> @_inp
    
  ##-----------------------------------------

  is_logged_in       : ()   -> @client().is_logged_in()
  login              : (cb) -> @client().login(cb)
  signup             : (cb) -> @client().signup(cb)
  push               : (cb) -> @client().push(cb)
  get_stored_records : ()   -> @client().get_stored_records()
   
  ##-----------------------------------------

  logout: (cb) ->
    # Do this one first, since force will logout a second time, but
    # ignore the return status code
    await @client().logout defer res
    @_timers.force()
    cb res

##=======================================================================

