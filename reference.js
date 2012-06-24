#!/usr/bin/env node

var fs = require ('fs');

var lib = fs.readFileSync("./crypto-min.js");
eval(lib.toString());

function make_string_from_byte(byte, n) {
    var v = [];
    var i;
    for (i = 0; i < n; i++) {
        v[i] = byte;
    }
    var ret = CryptoJS.lib.WordArray.create(v, 1);
    return ret;
}

function repeat_string (s, n) {
    var v = [];
    var i;
    for (i = 0; i < n; i++) {
        v[i] = s;
    }
    return v.join("");
}

function make_string_from_bytes_between(a,b) {
    var v = [];
    for (i = 0; a <= b; i++) {
        v[i] = a;
        a++;
    }
    return CryptoJS.lib.WordArray.create(v,1);
}

// SHA2 Test vectors from http://tools.ietf.org/rfc/rfc4868.txt
var tv1 = {
    "key" : make_string_from_byte (0x0b, 64),
    "data" : "Hi There",
    "res" : "637edc6e01dce7e6742a99451aae82df23da3e92439e590e43e761b33e910fb8ac2878ebd5803f6f0b61dbce5e251ff8789a4722c1be65aea45fd464e89f8f5b"
};

var tv2 = {
    "key" : repeat_string("Jefe", 16),
    "data" : "what do ya want for nothing?",
    "res" : "cb370917ae8a7ce28cfd1d8f4705d6141c173b2a9362c15df235dfb251b154546aa334ae9fb9afc2184932d8695e397bfa0ffb93466cfcceaae38c833b7dba38"
};

var tv3 = {
    "key" : make_string_from_byte (0xaa, 64),
    "data" : make_string_from_byte (0xdd, 64),
    "res" : "2ee7acd783624ca9398710f3ee05ae41b9f9b0510c87e49e586cc9bf961733d8623c7b55cebefccf02d5581acc1c9d5fb1ff68a1de45509fbe4da9a433922655"
};

var tv4 = {
    "key" : make_string_from_bytes_between(0xa0, 0x40),
    "data": make_string_from_byte (0xcd, 50),
    "res" : "5e6688e5a3daec826ca32eaea224eff5e700628947470e13ad01302561bab108b8c48cbc6b807dcfbd850521a685babc7eae4a2a2e660dc0e86b931d65503fd2"
};

// All of our test vectors.
var tvs = [ tv1, tv2, tv3, tv4 ];

var j;
var rc = 0;
for (j = 0; j < tvs.length; j++) {
    var tv = tvs[j];
    var res = CryptoJS.HmacSHA512(tv.data, tv.key);
    if (res.toString() != tv.res) {
        console.log("XXX mismatch on test vector " + j + " : " + JSON.stringify (tv) + " /-> " + res +"\n");
        rc = 1;
    }
}

process.exit(rc);
