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
    @prefill_ux()
    @attach_ux_events()

  prefill_ux: ->
    console.log "Todo: fill ux"

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

    $('#input-email').keyup => @engine.set "email", $('#input-email').val()
    $('#input-passphrase').keyup => @engine.set "passphrase", $('#input-passphrase').val()
    $('#input-host').keyup => @engine.set "host", $('#input-host').val()



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
