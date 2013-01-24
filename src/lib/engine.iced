
util = require './util'
{config} = require './config'
derive = require './derive'
doc = require './document'

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
  rxx = /^(\s*)(.*?)(\s*)$/
  m = x.match rxx
  m[2]
  
input_clean = (x) ->
  ret = input_trim(x).toLowerCase()
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

  key_fields : -> [ 'email', 'passphrase', 'host', 'generation', 'secbits' ]
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
    
  key_fields : -> [ 'email', 'passphrase', 'secbits' ]
  key_deriver : (i) -> new derive.V2 i 
  version : () -> 2
        
##=======================================================================

class Input
  
  constructor : (@_eng, @keymode = derive.keymodes.WEB_PW, @fixed = {}) ->
    SELECT = [ false, null ]
    @_template =
      email :  [ true, (x) -> input_clean x ]
      passphrase : [ true, (x) => @_clean_passphrase x ]
      host : [ true, (x) -> input_clean x ]
      version : SELECT
      secbits : SELECT
      nsym : SELECT
      generation : SELECT
      length : SELECT
    @_got_input = {}
    
  #-----------------------------------------
  
  get_version_obj : () -> VersionObj.make @get 'version'
  timeout : () -> config.timeouts.input
  clear : -> @_got_input.passphrpase = false

  #-----------------------------------------
  
  # Serialize the input and assign it a unique ID
  unique_id : (version_obj) ->
    parts = [ version_obj.version(), @_keymode ]
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
    
    compute_hook = (i) =>
      if (ret = (uid is @unique_id(vo))) and i % 10 is 0
        @_eng._doc.show_computing i, @_mode
      ret

    co = @_eng._cache.lookup uid

    (vo.key_deriver @).run co, compute_hook, cb

  #-----------------------------------------

  get : (k) ->
    if not (p = @_template[k])? then null
    else if (f = @fixed[k])? then f
    else
      raw = @_eng._doc.q(k).value
      if not p[0]                      then parseInt raw, 10
      else if p[1]? and @_got_input[k] then p[1](raw)

  set : (k) -> @_got_input[k] = true
  
  #-----------------------------------------

  _clean_passphrase : (pp) -> @get_version_obj().clean_passphrase pp

  #-----------------------------------------

  is_ready : () ->
    for k of @_template
      return false if not (v = @get k)?
    true
    
##=======================================================================

exports.SanitizedInput = class SanitizedInput extends Input
  constructor : (main) ->
    super main

##=======================================================================

class Timer

  #-----------------------------------------
  
  constructor : (@_obj) ->
    @_last_set = null
    
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
    @_timers = (new Timer o for o in [ @_eng._doc, @_eng._cache ])
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

##=======================================================================

exports.Engine = class Engine
  
  ##-----------------------------------------
  
  constructor : (@_doc, @_loc) ->
    @_cache = new Cache
    @_inp = new Input @
    @_timers = new Timers @

  ##-----------------------------------------

  toggle_timers : (b) -> @_timers.toggle b

  ##-----------------------------------------

  _autofill : () ->
    fields = [ "email", "version", "length", "secbits", "passphrase" ]
    go = false
    for k in fields when (v = @_loc.get k)?
      @_inp.set k
      @_doc.autofill k, v
      go = true
    @maybe_run() if go
   
  ##-----------------------------------------

  start : () ->
    @_timers.start()
    @_autofill()
   
  ##-----------------------------------------

  got_input : (event) ->
    @_timers.poke()
    se = event.srcElement
    @_inp.set se.id
    @maybe_run()

  ##-----------------------------------------

  run : () ->
    await @_inp.derive_key defer dk
    @_doc.set_generated_pw dk if dk
    
  ##-----------------------------------------

  maybe_run : () ->
    @run() if @_inp.is_ready()
  
  ##-----------------------------------------

  new_input : (mode, fixed) -> new Input @, mode, fixed
    
##=======================================================================

