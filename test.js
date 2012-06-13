var lib = require('./lib');

var pw = process.argv[2];
var site = process.argv[3];
var generation = process.argv[4];
var safety = parseInt (process.argv[5]);
var nsyms = parseInt(process.argv[6]);

var arr = lib.pwgen(pw, site, generation, safety, 20);
var pw = lib.add_syms(arr[0], nsyms);

console.log (pw);
