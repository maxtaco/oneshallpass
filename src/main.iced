
##=======================================================================

class Cache
  
##=======================================================================

class TestDocument
  constructor : ->
  getElementById : -> (x) -> @[x]


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
  
##-----------------------------------------------------------------------

class Version2Obj extends VersionObj
  
  clean_passphrase : (pp) ->
    # strip out all spaces!
    pp.replace /\s+/g, ""
    

##=======================================================================

class RawInput
  
  constructor : (@_doc) ->
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
    else if not (v = @[k])? and not p[0] then (@[k] = @_doc.getElementById k)
    else v
  
  #-----------------------------------------

  @_clean : (x) -> input_clean x
  @_clean_passphrase : (pp) -> @get_version_obj().clean_passphrase pp

  #-----------------------------------------

  get_version_obj : () -> VersionObj.make @get 'version'
   
  #-----------------------------------------
  
  set : (k, v) ->
    if not (p = @_template[k])? then null
    else if p[1] then (@[k] = p[1].call @, v)
    else (@[k] = v)
    
  #-----------------------------------------

  santize : () ->
    so = new SanitizedInput
    for k of @_template
      if not (v = @get k)? then return null
      so[k] = v
    so
    
##=======================================================================

class SanitizedInput

##=======================================================================

class DerivedKey
  constructor : (@_pwi) ->

##=======================================================================

class BrowserInfo

##=======================================================================

class Main
  constructor : (@_doc) ->
    @_cache = new Cache()
    @_bi = new BrowserInfo()
    @_ri = new RawInput @_doc

  got_input : (event) ->
    se = event.srcElement
    @_ri.set se.id, se.value
    
  
##=======================================================================

  
