Location                = require('./location').Location
Engine                  = require('./engine').Engine
sc                      = require('./status').codes
{JobWatcher, JobStatus} = require './job_watcher'
{keymodes}              = require './derive'

# -----------------------------------------------------------------------------


class Frontend

  constructor: ->
    @jw     = new JobWatcher()
    @engine = @create_engine()
    @engine.set "email", "chris@foobar.com"
    @engine.set "passphrase", "bleah bleah bleah"
    @engine.set "host", "walmart"

    @prefill_ux()
    @attach_ux_events()

  prefill_ux: ->
    console.log "Todo: fill ux"

  attach_ux_events: ->

  create_engine: ->
    opts =
      presets:
        algo_version: 2
      hooks:
        on_compute_step: (keymode, step, ts) => @on_compute_step keymode, step, ts
        on_compute_done: (keymode, key)      => @on_compute_done keymode, key
        on_timeout:      ()                  => @on_timeout()

    params = new Location(window.location).decode_url_params()
    opts.presets[k] = v for k,v of params
    return new Engine opts

  on_compute_step: (keymode, step, total_steps) ->
    @jw_update keymode,
      status:     JobStatus.RUNNING
      frac_done:  step / total_steps
      txt:        "Calculating #{keymode}; #{step}/#{total_steps}"
    

    #console.log "ocs: #{keymode}, #{step}, #{total_steps}"

  on_compute_done: (keymode, key) ->
    @jw_update keymode,
      status:     JobStatus.COMPLETE
      frac_done:  1.0
      txt:        "Completed #{keymode}; #{key}"
    
  jw_update: (label, changes) ->
    @jw.update label, changes
    @draw_job_watcher label

  draw_job_watcher: (label) ->
    el = $("#job-watcher #job-#{label}")
    if not el.length
      $('#job-watcher').prepend """
        <div id="job-#{label}" style="display:none;">job #{label}</div>
      """
      el = $("#job-watcher #job-#{label}")
    el.stop(true).slideDown().delay(10000).slideUp()

    j = @jw.getInfo label
    el.html """
      job #{label}: #{j.txt}
    """

  on_timeout: ->
    console.log "session timeout. todo: clear forms"

# -----------------------------------------------------------------------------

$ ->
  new Frontend()
 

###

attach_ux_events = ->
  $('#btn-no-sync, #btn-sync, #login-row').mouseover ->
    $('#sync-explanation').addClass 'highlight'
  $('#btn-no-sync, #btn-sync, #login-row').mouseout ->
    $('#sync-explanation').removeClass 'highlight'
  $('#btn-login').click -> click_login @
  $('#input-email, #input-passphrase, #input-service').focus -> $(@).addClass 'modified'
  $('#input-email, #input-passphrase, #input-service').keyup (e) ->
    engine.got_input $(@).attr('id')
    if engine.has_login_info()
      $('#btn-login').attr("disabled", false)

click_login = (e) ->
  console.log "logging in"
  $('#login-status-row').slideDown 'fast'
  $('#btn-login').attr("disabled", "disabled")
  #if $('#input-email').val() and $('#input-passhprase').val()
  #  try_to_login 
  #  console.log "logging in"
  #  $('#login-status-row').slideDown 'fast'
  #  $('#btn-login').attr("disabled", "disabled")
  #else



main = () ->
  docmod = require './document'
  locmod = require './location'
  engmod = require './engine'
  doc = new docmod.Browser window.document
  loc = new locmod.Location window.location
  engine = new engmod.Engine doc, loc

  engine.start()

ungrey = (e) ->
  e.className += " input-black"
  
accept_focus = (e) ->
  se = event.srcElement
  se.value = "" if doc.ungrey se

accept_form_input = (e) ->
  engine.got_input e

click_hide_passphrase = (e) ->
  hide = event.srcElement.checked
  (doc.q 'passphrase').type = if hide then "password" else "text"

tbody_enable = (e, b) ->
  e.style.display = if b then "table-row-group" else "none"
trow_enable = (e, b) -> 
  e.style.display = if b then "table-row" else "none"
inline_enable = (e, b) ->
  e.style.display = if b then 'inline' else 'none' 

show_advanced = (b) ->
  tbody_enable doc.q('advanced-expander'), not b
  tbody_enable doc.q('advanced'), b
  
click_run_timers = (e) ->
  engine.toggle_timers e.srcElement.checked

select_text = (e) ->
  e.srcElement.focus()
  e.srcElement.select()

click_sync = (e) ->
  b = e.srcElement.checked
  tbody_enable doc.q('sync-details'), b
  trow_enable doc.q('sync-note-row'), b
  inline_enable doc.q('sync-push-button'), b
  doc.clear_sync_status()
  engine.toggle_sync b
  for f in [ 'passphrase', 'email' ]
    doc.q(f).readOnly = b

click_signup = (e) ->
  engine.client().signup()

push_record = (e) ->
  engine.client().push_record()

select_stored_recored = (e) ->
  engine.select_stored_record(e.srcElement.value)
  


###
