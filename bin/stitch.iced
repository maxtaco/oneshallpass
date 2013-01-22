
stitch = require 'stitch'
fs = require 'fs'

s = stitch.createPackage { paths : process.argv[2...] }
await s.compile defer err, source
if err
  process.stderr.write err + "\n"
  process.exit -1
process.stdout.write source
  
