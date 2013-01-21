#!/usr/bin/env node

var fs = require ('fs');

var lib = fs.readFileSync("./js-min/crypto-min.js");
eval(lib.toString());

function check_vector(v) {
    var opts = { keySize : v.dkLen, iterations: v.c };
    
    // Get the raw word array.
    var raw = CryptoJS.PBKDF2(v.P, v.S, opts)

    // Convert to string, and also truncate after the first dkLen
    // bytes.  Note it takes 2 hex-encoding character to encode a byte,
    // so double it up...
    var r = raw.toString().slice(0,v.dkLen*2);

    var res = true;
    if (r != v.DK) {
	console.log ("XXX failure for case " + JSON.stringify(v) + 
		     "; got " + r);
	res = false;
    }
    return res;
}


// Test vectors from http://tools.ietf.org/html/rfc6070
var test_vectors = [
    { 
        "rfc" : 6070,
        "case" : 1, 
	"P" : "password",
	"S" : "salt",
	"c" : 1,
	"dkLen" : 20,
	"DK" : "0c60c80f961f0e71f3a9b524af6012062fe037a6"
    },

    { 
        "rfc" : 6070,
        "case" : 2,
	"P" : "password",
	"S" : "salt",
	"c" : 2,
	"dkLen" : 20,
	"DK" : "ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957"
    },

    {
        "rfc" : 6070,
        "case" : 3,
	"P" : "password",
	"S" : "salt",
	"c" : 4096,
	"dkLen" : 20,
	"DK" : "4b007901b765489abead49d926f721d065a429c1"
    },

    {
        "rfc" : 6070,
        "case" : 5,
	"P" : "passwordPASSWORDpassword",
	"S" : "saltSALTsaltSALTsaltSALTsaltSALTsalt",
	"c" : 4096,
	"dkLen" : 25,
	"DK" : "3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038"

    },

    {
	"rfc" : 6070,
	"case" : 6,
	"P" : "pass\0word",
	"S" : "sa\0lt",
	"c" : 4096,
	"dkLen" : 16,
	"DK" : "56fa6aa75548099dcc37d7f03425e0c3"
    }

    ];

var crazy_test_skip_for_now = [

    {
        "rfc" : 6070,
        "case" : 4,
	"P" : "password",
	"S" : "salt",
	"c" : 16777216,
	"dkLen" : 20,
	"DK" : "eefe3d61cd4da4e4e9945b3d6ba2158c2634e984"
    }
];

var j;
var rc = 0;
for (j = 0; j < test_vectors.length; j++) {
    var tv = test_vectors[j];
    if (!check_vector(tv)) {
        rc = 1;
    }
}

process.exit(rc);
