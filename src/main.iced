
util = require './util'

##=======================================================================

class Cache
  constructor : () ->
    @_c = {}
    @_poke()

  poke : () ->
    @_last_access = util.unix_time()

  lookup : (sio) ->
    k = sio.key()
    obj = @_c[k] = si unless (obj = @_c[k])?
    return obj
  
##=======================================================================

class TestDocument
  constructor : ->
  getElementById : -> (x) -> @[x]

##=======================================================================


##=======================================================================

input_trim : (x) ->
  rxx = /^(\s*)(.*?)(\s*)$/
  m = x.match rxx
  m[2]
input_clean : (x) -> input_trim(x).toLowerCase()

##=======================================================================

class PwGen

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
  
  clean_passphrase : (pp) ->
    # Replace any interior whitepsace with just a single
    # plain space, but otherwise, interior whitespaces count
    # as part of the passphrase
    input_trim(pp).replace /\s+/g, " "

  key_fields : -> [ 'email', 'passphrase', 'host', 'generation', 'secbits' ]
  
##-----------------------------------------------------------------------

class Version2Obj extends VersionObj
  
  clean_passphrase : (pp) ->
    # strip out all spaces!
    pp.replace /\s+/g, ""
    
  key_fields : -> [ 'email', 'passphrase', 'secbits' ]

##=======================================================================

class Input
  constructor : -> @_key = null
  get : (k) -> @[k]
  set : (k,v) -> @[k] = v
  get_version_obj : () -> VersionObj.make @get 'version'

  # "Key" this input so we can see if it's changed while the alg is running
  key : () ->
    unless @_key?
      @_key = (@get f for f in get_version_obj().key_fields()).join ";" 
    @_key

##=======================================================================

class RawInput extends Input
  
  constructor : (@_main) ->
    @_key = null
    SELECT = [ false, null ]
    @_template =
      email :  [ true, @_clean ]
      passphrase : [ true, @_clean_passphrase ]
      host : [ true, @_clean ]
      select : SELECT
      version : SELECT
      secbits : SELECT
      nsym : SELECT
      generation : SELECT
      length : SELECT

  #-----------------------------------------

  get : (k) ->
    if not (p = @_template[k])? then null
    else if not (v = @[k])? and not p[0] then (@[k] = @_main._doc.getElementById k)
    else v
  
  #-----------------------------------------

  @_clean : (x) -> input_clean x
  @_clean_passphrase : (pp) -> @get_version_obj().clean_passphrase pp

  #-----------------------------------------
  
  set : (k, v) ->
    @_key = null
    if not (p = @_template[k])? then null
    else if p[1] then (@[k] = p[1].call @, v)
    else (@[k] = v)
    
  #-----------------------------------------

  santize : () ->
    si = new SanitizedInput @_main
    for k of @_template
      if not (v = @get k)? then return null
      si[k] = v
    si

##=======================================================================

class SanitizedInput extends Input
  constructor : (@_main) ->

##=======================================================================

class DerivedKey
  constructor : (@_pwi) ->

##=======================================================================

class BrowserInfo

##=======================================================================

class Main
  
  ##-----------------------------------------

  constructor : (@_doc) ->
    @_cache = new Cache
    @_bi = new BrowserInfo()
    @_ri = new RawInput @

  ##-----------------------------------------

  got_input : (event) ->
    se = event.srcElement
    @_ri.set se.id, se.value
    @maybe_run()

  ##-----------------------------------------

  run : () ->
    key = @_si.key()

    # If we already had an object for this input, grab that instead.
    # Otherwise, we'll add this one to cache...
    @_si = @_cache.lookup @_si

    await @_si.derive_key defer dk

    @_doc.set_generated_pw dk
    
  ##-----------------------------------------

  maybe_run : () ->
    @run() if (@_si = @_ri.sanitize())?
    
  ##-----------------------------------------
  
##=======================================================================

  
