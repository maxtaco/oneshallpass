#!/usr/bin/env node

fs = require ('fs');

lib = fs.readFileSync("./build/js-min/crypto.js").toString()
eval lib
derive = require '../src/lib/derive'

check_vector = (CryptoJS, v, cb) ->
  opts = { keySize : v.dkLen / 4, iterations: v.c };
    
  # Get the raw word array.
  raw_cjs = CryptoJS.PBKDF2(v.P, v.S, opts)
  v2o = new derive.V3 { get : () -> 0 }, CryptoJS.algo.SHA1
  await v2o.test CryptoJS, v.P, v.S, v.c, defer raw_us

  # Convert to string, and also truncate after the first dkLen
  # bytes.  Note it takes 2 hex-encoding character to encode a byte,
  # so double it up...
  [res_cjs, res_us] = (r.toString()[0...v.dkLen*2] for r in [ raw_cjs, raw_us])

  res = true
  if res_cjs isnt v.DK
    console.log "XXX failure for case (with CryptoJS code) #{JSON.stringify v}"
    res = false 
  if res_us isnt v.DK
    console.log "XXX failure for case (with our code) #{JSON.stringify v}"
    res = false
  cb res

# Test vectors from http://tools.ietf.org/html/rfc6070
test_vectors = [{
    rfc : 6070,
    case : 1, 
  	P : "password",
  	S : "salt",
  	c : 1,
  	dkLen : 20,
  	DK : "0c60c80f961f0e71f3a9b524af6012062fe037a6"
  },{
    rfc : 6070,
    case : 2,
  	P : "password",
  	S : "salt",
  	c : 2,
  	dkLen : 20,
  	DK : "ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957"
  }, {
    rfc : 6070,
    case : 3,
  	P : "password",
  	S : "salt",
  	c : 4096,
  	dkLen : 20,
  	DK : "4b007901b765489abead49d926f721d065a429c1"
  }, {
    rfc : 6070,
    case : 5,
  	P : "passwordPASSWORDpassword",
  	S : "saltSALTsaltSALTsaltSALTsaltSALTsalt",
  	c : 4096,
  	dkLen : 20,
  	DK : "3d2eec4fe41c849b80c8d83662c0e44a8b291a96"
  }, {
  	rfc : 6070,
  	case : 6,
  	P : "pass\0word",
  	S : "sa\0lt",
  	c : 4096,
  	dkLen : 16,
  	DK : "56fa6aa75548099dcc37d7f03425e0c3"
  } ]

crazy_test_skip_for_now = {
  rfc : 6070,
  case : 4,
	P : "password",
	S : "salt",
	c : 16777216,
	dkLen : 20,
	DK : "eefe3d61cd4da4e4e9945b3d6ba2158c2634e984"
}

eval fs.readFileSync("./build/js-min/crypto.js").toString()

rc = 0
for v in test_vectors
  await check_vector CryptoJS, v, defer res
  rc = 1 unless res
process.exit rc
