Location                = require('./location').Location
Engine                  = require('./engine').Engine
sc                      = require('./status').codes
{JobWatcher, JobStatus} = require './job_watcher'
{keymodes}              = require './derive'

# -----------------------------------------------------------------------------


class Frontend

  constructor: ->
    @jw     = new JobWatcher()
    @e      = null             # the engine
    @create_engine()
    @attach_ux_events()


  fill_engine_and_ui: (key, val, input_id) ->
    @e.set key, val
    $("##{input_id}").val(@e.get key).addClass "modified"
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
      @update_save_button()

    $('#input-generation').change =>
      @e.set "generation", parseInt $('#input-generation').val()

    $('#input-security-bits').change =>
      @e.set "security_bits", parseInt $('#input-security-bits').val()

    $('#input-num-symbols').change =>
      @e.set "num_symbols", $('#input-num-symbols').val()

    $('#input-length').change =>
      @e.set "length", $('#input-length').val()

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

    $('#faq-link').click =>
      $('#faq').show()
      $('#faq-link').parent().hide()

    $('#output-password').click =>
      $('#output-password').select()

    $("#input-saved-host").change =>
      v = $("#input-saved-host").val()
      if v and v.length
        @load_record_by_host v

    $("""#input-security-bits, #input-generation,
        #input-length, #input-host, #input-num-symbols
      """).change =>
      @update_save_button()

    $("#btn-save").click =>
      @e.push @push_cb

  update_save_button: ->
    h = @e.get "host"
    if h and h.length
      $("#btn-save").attr "disabled", false
    else
      $("#btn-save").attr "disabled", "disabled"
  
  load_record_by_host: (h) ->
    recs = @e.get_stored_records()
    for r in recs when r.host is h
      @fill_engine_and_ui "security_bits", r.security_bits, "input-security-bits"
      @fill_engine_and_ui "generation", r.generation, "input-generation"
      @fill_engine_and_ui "length", r.length, "input-length"
      @fill_engine_and_ui "host", h, "input-host"
      @fill_engine_and_ui "num_symbols", r.num_symbols, "input-num-symbols"
      $('#btn-save').attr 'disabled', 'disabled'

  push_cb: (status) =>
    if status isnt sc.OK
      alert "Unhandled push status #{status}"
    else
      $("#btn-save").attr "disabled", "disabled"
      @maybe_show_saved_hosts()

  logout_cb: (status) =>
    if status isnt sc.OK
      alert "Unhandled logout status #{status}"
    $("#save-row").slideUp()      
    $(".saved-hosts-bundle").slideUp()
    $('#btn-login').attr('disabled', false)
    @enable_login_credentials()
    @fill_engine_and_ui 'passphrase', '', "input-passphrase"
    @fill_engine_and_ui 'host', '', "input-host"
    @update_output_pw ''
    @update_login_button()

  login_cb: (status) =>
    if status is sc.OK
      @update_login_button()
      @maybe_show_saved_hosts()
      $("#save-row").slideDown()
      @fill_engine_and_ui 'host', '', "input-host"
      @update_output_pw ''
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

  maybe_show_saved_hosts: =>
    recs = @e.get_stored_records()
    if recs.length
      $(".saved-hosts-bundle").slideDown()
      $("#input-saved-host").html """
        <option value="">- choose -</option>
      """ + ("""
        <option value="#{r.host}"
        >#{r.host}</option>
      """ for r in recs).join "\n"

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
    @e      = new Engine opts
    
    if params.passphrase then @fill_engine_and_ui "passphrase", params.passphrase, "input-passphrase"
    if params.email      then @fill_engine_and_ui "email", params.email, "input-email"
    if params.host       then @fill_engine_and_ui "host", params.host, "input-host"

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
      when keymodes.WEB_PW      then return "base hash (#{@e.get('security_bits')}-bit)"
      when keymodes.LOGIN_PW    then return "server password"
      when keymodes.RECORD_AES  then return "encryption key"
      when keymodes.RECORD_HMAC then return "authentication key"
      else return 'unknown keymode'


  on_compute_step: (keymode, step, total_steps) ->
    if keymode is keymodes.WEB_PW
      $('#output-password').val ''
    txt = "#{@keymode_name keymode} (#{step+1}/#{total_steps+1})"

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
      @update_output_pw key

  update_output_pw: (key) ->
    $('#output-password').addClass("just-changed").val(key)
    if @pw_effect_timeout then clearTimeout @pw_effect_timeout
    @pw_effect_timeout = setTimeout (->
      $('#output-password').removeClass "just-changed"
    ), 500

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
