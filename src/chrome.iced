
inp = ( 0x36363636 for i in [0...3])
wa = CryptoJS.lib.WordArray.create inp

pp = ""
$ -> run_test()

run_test = () ->
  val = null
  bads = []
  for i in [0...100]
    sha = CryptoJS.algo.SHA512.create()
    out = sha.finalize wa
    if not val?
      first = out
      val = out.words[0]
    else if val isnt out.words[0]
      bads.push [i].concat out.words
  display_result first, bads

display_result = (first, bads) ->
  if bads.length
    row0 = [ 0 ].concat first.words
    rows = [ row0 ].concat bads
    trs = 
      for b in rows
        "<tr>" + ("<td>#{w}</td>" for w in b).join(' ') + "</tr>"
    headings = ["Attempt"].concat("Word #{b}" for b in [0...32])
    ths = ("<th>#{h}</td>" for h in headings)
    headrow = "<tr>" + ths.join(" ") + "</tr>"

    tab = "<h2>Errors Found!</h2>\n<table border=1>#{headrow} #{trs.join('\n')}</table>"
    $("#shitcan").append tab
  else
    $("#shitcan").append "No problems found; try again....."

