
engine = null
doc = null

main = () ->
  docmod = require './document'
  locmod = require './location'
  engmod = require './engine'
  doc = new docmod.Browser window.document
  loc = new locmod.Location window.location
  engine = new engmod.Engine doc, loc
  engine.start()

window.onload = () -> main()

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

show_advanced = (b) ->
  tbody_enable doc.q('advanced-expander'), not b
  tbody_enable doc.q('advanced'), b
  
click_run_timers = (e) ->
  engine.toggle_timers event.srcElement.checked

select_text = (e) ->
  e.srcElement.focus()
  e.srcElement.select()
