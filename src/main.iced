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
    @update_login_button()

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

    $('#btn-login').click => 
      $('#btn-login').attr('disabled','disabled')
      @hide_login_dialogs()
      @disable_login_credentials()
      @e.login @login_cb

    $('#btn-logout').click =>
      $('#btn-logout').attr('disabled','disabled')
      @hide_login_dialogs()
      @e.logout @logout_cb      

    $('#btn-join').click => 
      $('#btn-join').attr('disabled','disabled')
      @disable_login_credentials()
      @e.signup @join_cb

  logout_cb: (status) =>
    console.log "lo cb: #{status} #{@e.is_logged_in()}"
    if status isnt sc.OK
      alert "Unhandled logout status #{status}"      
    $('#btn-login').attr('disabled', false)
    @enable_login_credentials()
    @e.set "passphrase", ''
    $('#input-passphrase').val ''
    @update_login_button()

  login_cb: (status) =>
    console.log "cb: #{status} #{@e.is_logged_in()}"
    if status is sc.OK
      @update_login_button()
    else
      @enable_login_credentials()    
      if status is sc.BAD_LOGIN
        @show_bad_login_dialog()
      else if status is sc.SERVER_DOWN
        @show_bad_general_dialog()
        $("#bad-general-msg").html """
          The server was unreachable. Perhaps you're offline?
          You can still use One Shall Pass, assuming you can recall
          the names of your hosts. All hashing is done in the browser.
        """
      else
        alert "Unhandled login error code: #{status}"

  join_cb: (status) =>
    @enable_login_credentials()
    if status is sc.OK
      @hide_bad_login_dialog()
      @show_good_join_dialog()
      $('.join-email').html @e.get 'email'      
    else
      @hide_bad_login_dialog()
      @show_bad_general_dialog()
      if status is sc.SERVER_DOWN
        $("#bad-general-msg").html """
          The server was unreachable and joining is not possible. Try again when connected?
        """
      else if status is sc.BAD_ARGS
        $("#bad-general-msg").html """
          The args you passed were not legit.
        """
      else
        alert "Unhandled join error code: #{status}"

    @update_login_button()

  show_bad_general_dialog: ->
    $("bad-general-dialog").show()

  show_good_join_dialog: ->
    $("#good-join-dialog").show()

  disable_login_credentials: ->
    $("#input-passphrase, #input-email").attr("disabled", "disabled")

  enable_login_credentials: ->
    $("#input-passphrase, #input-email").attr("disabled", false)

  hide_login_dialogs: ->
    @hide_bad_login_dialog()
    @hide_good_join_dialog()
    @hide_bad_general_dialog()

  hide_good_join_dialog: ->
    $("#good-join-dialog").hide()

  hide_bad_general_dialog: ->
    $("#bad-general-dialog").hide()

  show_bad_login_dialog: ->
    $("#bad-login-dialog").show()
    @hide_good_join_dialog()
    @hide_bad_general_dialog()

  hide_bad_login_dialog: ->
    $("#bad-login-dialog").hide()
    $('#btn-join').attr('disabled',false)

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
    @hide_bad_login_dialog()
    if @e.is_logged_in()
      $('#btn-logout').show()
      $('#btn-logout').attr "disabled", false
      $('#btn-login').hide()
    else 
      $('#btn-logout').hide()
      $('#btn-login').show()
    $('#btn-login').attr "disabled", not(@e.get('email') and @e.get('passphrase'))

  keymode_name: (keymode) ->
    switch keymode
      when keymodes.WEB_PW      then return "password"
      when keymodes.LOGIN_PW    then return "server password"
      when keymodes.RECORD_AES  then return "encryption key"
      when keymodes.RECORD_HMAC then return "authentication key"
      else return 'unknown keymode'


  on_compute_step: (keymode, step, total_steps) ->
    if keymode is keymodes.WEB_PW
      $('#output-password').val ''
    txt = "#{@keymode_name keymode} (#{step}/#{total_steps})"

    @jw_update keymode,
      status:     JobStatus.RUNNING
      frac_done:  step / total_steps
      txt:        txt
    
  on_compute_done: (keymode, key) ->
    @jw_update keymode,
      status:     JobStatus.COMPLETE
      frac_done:  1.0
      txt:        "#{@keymode_name keymode}"
    if keymode is keymodes.WEB_PW
      $('#output-password').val key
    
  jw_update: (label, changes) ->
    @jw.update label, changes
    @draw_job_watcher label

  draw_job_watcher: (label) ->
    el = $("#job-#{label}")
    if not el.length
      $('#job-watcher').prepend """
        <div class="job" id="job-#{label}" style="display:none;">job #{label}</div>
      """
      el = $("#job-#{label}")
      el.slideDown()

    j = @jw.getInfo label

    el.html """
      <div class="job-wrapper-status-#{j.status}">
        <div class="job-status">#{k for k,v of JobStatus when v is j.status}</div>
        <div class="job-txt">#{j.txt}</div>
        <div class="job-completion">
          <div class="job-completion-bar"></div>
        </div>
        <div class="clear"></div>
      </div>
    """
    bar_width = Math.floor j.frac_done * $("#job-#{label} .job-completion").width()
    bar = $("#job-watcher #job-#{label} .job-completion-bar").width bar_width

  on_timeout: ->
    console.log "session timeout. todo: clear forms"

# -----------------------------------------------------------------------------

$ ->
  new Frontend()
