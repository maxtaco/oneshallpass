
engine = null

main = () ->
  docmod = require './document'
  engmod = require './engine'
  doc = new docmod.Browser window.document
  engine = new engmod.Engine doc
  engine.start()

window.onload = () -> main()
