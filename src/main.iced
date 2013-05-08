Location                = require('./lib/location.iced').Location
Engine                  = require('./lib/engine.iced').Engine
sc                      = require('./lib/status.iced').codes
{config}                = require('./lib/config.iced')
{JobWatcher, JobStatus} = require './lib/job_watcher.iced'
{keymodes}              = require './lib/derive.iced'

# -----------------------------------------------------------------------------


class Frontend

  constructor: ->
    @jw     = new JobWatcher()
    @e      = null             # the engine
    @create_engine()
    @attach_ux_events()
    @first_select()

  first_select: ->
    if $("#input-email").hasClass("modified") or $("#input-passphrase").hasClass("modified")
      if not $("#input-email").hasClass("modified") then $("#input-email").focus()
      else if not $("#input-passphrase").hasClass("modified") then $("#input-passphrase").focus()
      else $("#btn-login").focus()

  fill_both: (key, val, input_id) ->
    ### fills both the engine and the UI ###
    @e.set key, val
    $("##{input_id}").val(@e.get key).addClass "modified"
    @update_login_button()

  attach_ux_select : (f) ->
    html_field = "#input-#{f}"
    eng_field = f.replace("-", "_")
    $(html_field).change =>
      @e.set eng_field, parseInt $(html_field).val()

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
      @e.poke()
      
    $('#input-passphrase').keyup =>
      @e.set "passphrase", $('#input-passphrase').val()
      @update_login_button()
      @e.poke()

    $('#input-host').keyup =>
      before = @e.get 'host'
      @e.set "host", $('#input-host').val()
      after = @e.get 'host'
      $('#input-saved-host').val('') unless before is after
      @update_save_button()
      @e.poke()


    $('#input-notes').keyup =>
      @e.set "notes", $('#input-notes').val()
      @update_save_button()
      @e.poke()

    for f in [ 'generation', 'security-bits', 'algo-version', 'length', 'num-symbols']
      @attach_ux_select f

    $('#btn-hide-passphrase').click =>
      $('#input-passphrase').attr("type","password")
      $('#btn-hide-passphrase').hide()
      $('#btn-show-passphrase').show()
      @e.poke()
      
    $('#btn-show-passphrase').click =>
      $('#input-passphrase').attr("type","text")
      $('#btn-show-passphrase').hide()
      $('#btn-hide-passphrase').show()
      @e.poke()

    $('#btn-login').click => 
      $('#btn-login').attr('disabled','disabled')
      @hide_login_dialogs()
      @disable_login_credentials()
      @e.poke()
      @e.login @login_cb

    $('#btn-logout').click =>
      $('#btn-logout').attr('disabled','disabled')
      @hide_login_dialogs()
      @e.logout @logout_cb      

    $('#input-passphrase, #input-email').focus =>
      $('#input-email').removeClass('error')
      $('#input-passphrase').removeClass('error')


    $('#btn-join').click => 
      $('#input-email').removeClass('error')
      $('#input-passphrase').removeClass('error')
      $('#btn-join').attr('disabled','disabled')
      @disable_login_credentials()
      @e.signup @join_cb
      @e.poke()

    $('#faq-link').click =>
      $('#faq').show()
      $('#faq-link').parent().hide()
      @e.poke()

    $('#output-password').click =>
      $('#output-password').select()
      @e.poke()

    $("#input-saved-host").change =>
      v = $("#input-saved-host").val()
      if v and v.length
        @load_record_by_host v
      else
        @clear_host_notes_and_output()
      @e.poke()

    $("""#input-security-bits, #input-generation,
        #input-length, #input-host, #input-num-symbols,
        #input-notes, #input-algo-version
      """).change =>
      @update_save_button()

    $("#input-algo-version").change =>
      cfg = config.legacy
      bits = if (@e.get "algo_version") is cfg.algo_version then cfg.security_bits
      else (@e.get "security_bits") + 1
      @fill_both "security_bits", bits, "input-security-bits"

    $("#btn-save").click =>
      @e.poke()
      await @e.push defer status
      if status isnt sc.OK
        alert "Unhandled push status #{status}"
      else
        $("#btn-save").attr "disabled", "disabled"
        @maybe_show_saved_hosts()

    $("#btn-remove").click =>
      @e.poke()
      await @e.remove defer status
      if status isnt sc.OK
        alert "Unhandled remove status #{status}"
      else
        @clear_host_notes_and_output()
        @maybe_show_saved_hosts()

  toggle_remove_button : (f) ->
    val = if f then false else "disabled"
    $('#btn-remove').attr "disabled", val

  update_save_button: ->
    h = @e.get "host"
    if h and h.length
      $("#btn-save").attr "disabled", false
    else
      $("#btn-save").attr "disabled", "disabled"

  load_field : (r, f, dflt) ->
    v = dflt if not (v = r[f])? and dflt?
    @fill_both f, v, "input-#{f.replace '_', '-'}"

  load_record_by_host: (h) ->
    r = @e.get_record h
    # load the algo version first, since there might be race conditions
    # in setting it last with the background computation firing up
    @load_field r, "algo_version", config.input.defaults.algo_version
    for f in [ "security_bits", "generation", "length", "host", 
               "num_symbols" ]
      @load_field r, f
    @load_field r, "notes", ""
    $('#btn-save').attr 'disabled', 'disabled'
    @toggle_remove_button true

  logout_cb: (status) =>
    if status isnt sc.OK
      alert "Unhandled logout status #{status}"
    @clear_all_but_email()

  login_cb: (status) =>
    if status is sc.OK
      $('#input-email').addClass 'success'
      $('#input-passphrase').addClass 'success'
      @update_login_button()
      @maybe_show_saved_hosts()
      $("#save-row").slideDown()
      @fill_both 'host', '', "input-host"      
      @update_output_pw ''
      @update_save_button()
    else
      @enable_login_credentials()    
      if status is sc.BAD_ARGS
        alert "Bad arguments; pick a real email address and passphrase"
      else if status is sc.BAD_LOGIN
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
      recs = recs.sort (a,b) -> if a.host < b.host then -1 else 1
      $(".saved-hosts-bundle").slideDown()
      $("#input-saved-host").html """
        <option value="">- choose -</option>
      """ + ("""
        <option value="#{r.host}"
        >#{r.host}</option>
      """ for r in recs).join "\n"
      $("#input-saved-host").focus()
    else
      $(".saved-hosts-bundle").slideUp()


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
    $('#input-email').addClass('error')
    $('#input-passphrase').addClass('error')

    @hide_good_join_dialog()
    @hide_bad_general_dialog()

  hide_bad_login_dialog: ->
    $("#bad-login-dialog").hide()
    $('#btn-join').attr('disabled',false)

  create_engine: ->
    # We can specify these opts at the top level, so respect those defaults
    # if we've specified them....
    opts = if engine_opts? then engine_opts else {}
    
    opts.presets =
      algo_version: 3
    opts.hooks =
      on_compute_step: (keymode, step, ts) => @on_compute_step keymode, step, ts
      on_compute_done: (keymode, key)      => @on_compute_done keymode, key
      on_timeout:      ()                  => @on_timeout()

    p = new Location(window.location).decode_url_params()
    @e      = new Engine opts
    
    if p.passphrase     then @fill_both "passphrase", p.passphrase, "input-passphrase"
    if p.email          then @fill_both "email", p.email, "input-email"
    if p.host           then @fill_both "host", p.host, "input-host"
    if p.security_bits  then @fill_both "security_bits", p.security_bits, "input-security-bits"
    if p.generation     then @fill_both "generation", p.generation, "input-generation"
    if p.length         then @fill_both "length", p.length, "input-length"
    if p.num_symbols    then @fill_both "num_symbols", p.num_symbols, "input-num-symbols"

  update_login_button: ->
    @hide_bad_login_dialog()
    if @e.is_logged_in()
      $('#btn-logout').show()
      $('#btn-logout').attr "disabled", false
      $('#btn-login').hide()
      $('#notes-row').show()
    else 
      $('#btn-logout').hide()
      $('#btn-login').show()
      $('#notes-row').hide()
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
      @update_output_pw ''
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
    $('#output-password').val key
    if key and key.length
      if @pw_effect_timeout then clearTimeout @pw_effect_timeout
      $('#output-password').addClass("just-changed")
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
    @clear_all_but_email()

  clear_host_notes_and_output : () ->
    @fill_both 'host', '',       "input-host"
    @fill_both 'notes','',       "input-notes"
    @update_output_pw ''
    @toggle_remove_button false

  clear_all_but_email: ->
    $('#input-email').removeClass('success').removeClass('error')
    $('#input-passphrase').removeClass('success').removeClass('error')

    $("#save-row").slideUp()
    $(".saved-hosts-bundle").slideUp()
    $('#btn-login').attr('disabled', false)
    @enable_login_credentials()
    @fill_both 'passphrase', '', "input-passphrase"
    @clear_host_notes_and_output()
    @update_login_button()

# -----------------------------------------------------------------------------

$ ->
  new Frontend()
