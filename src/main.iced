Location                = require('./location').Location
Engine                  = require('./engine').Engine
sc                      = require('./status').codes
{JobWatcher, JobStatus} = require './job_watcher'
{keymodes}              = require './derive'

# -----------------------------------------------------------------------------


class Frontend

  constructor: ->
    @jw     = new JobWatcher()
    @e      = @create_engine()
    @prefill_ux()
    @attach_ux_events()

  prefill_ux: ->
    if (p = @e.get "passphrase") then $("#input-passphrase").val(p).addClass("modified")
    if (e = @e.get "email") then $("#input-email").val(e).addClass("modified")
    if (h = @e.get "host") then $("#input-host").val(h).addClass("modified")

  attach_ux_events: ->

    basic_inputs = [
      '#input-email'
      '#input-passphrase'
      '#input-host'
    ]
    $(basic_inputs.join ',').focus ->
      if not $(@).hasClass 'modified'
        $(@).val ''
        $(@).addClass 'modified'

    $('#input-email').keyup =>      
      @e.set "email", $('#input-email').val()
      @update_login_button()
      
    $('#input-passphrase').keyup =>
      @e.set "passphrase", $('#input-passphrase').val()
      @update_login_button()

    $('#input-host').keyup =>
      @e.set "host", $('#input-host').val()

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

  update_login_button: ->
    if @e.is_logged_in()
      $('#btn-logout').show()
      $('#btn-login').hide()
    else 
      $('#btn-logout').hide()
      $('#btn-login').show()
    $('#btn-login').attr "disabled", not(@e.get('email') and @e.get('passphrase'))

  on_compute_step: (keymode, step, total_steps) ->
    @jw_update keymode,
      status:     JobStatus.RUNNING
      frac_done:  step / total_steps
      txt:        "Calculating #{keymode}; #{step}/#{total_steps}"
    if keymode is keymodes.WEB_PW
      $('#output-password').val ''
    
    #console.log "ocs: #{keymode}, #{step}, #{total_steps}"

  on_compute_done: (keymode, key) ->
    @jw_update keymode,
      status:     JobStatus.COMPLETE
      frac_done:  1.0
      txt:        "Completed #{keymode}; #{key}"
    if keymode is keymodes.WEB_PW
      $('#output-password').val key
    
  jw_update: (label, changes) ->
    @jw.update label, changes
    @draw_job_watcher label

  draw_job_watcher: (label) ->
    el = $("#job-watcher #job-#{label}")
    if not el.length
      $('#job-watcher').prepend """
        <div class="job" id="job-#{label}" style="display:none;">job #{label}</div>
      """
      el = $("#job-watcher #job-#{label}")
      el.slideDown()

    j = @jw.getInfo label

    el.html """
      job #{label}: #{j.txt}
    """

  on_timeout: ->
    console.log "session timeout. todo: clear forms"

# -----------------------------------------------------------------------------

$ ->
  new Frontend()
