#!/usr/bin/env node

var fs = require ('fs');

var lib = fs.readFileSync("./crypto-min.js");
eval(lib.toString());

function make_wa_from_byte(byte, n) {
    var v = [];
    var i;
    var word = (byte << 24) | (byte << 16) | (byte << 8) | byte;
    for (i = 0; i < (n >> 2); i++) {
        v.push(word);
    }
    var ret = CryptoJS.lib.WordArray.create(v);
    if (n % 4 !== 0) {
        word = 0;
        for (i = 0; i < n % 4; i++) {
            word |= (byte << (8*(3 - i)));
        }
        ret.concat(CryptoJS.lib.WordArray.create([word], n%4));
    }
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

function make_wa_from_bytes_between(a,b) {
    var v = [];
    var slot = 0;
    var word = 0;
    var bytes = 0;
    while (a <= b) {
        word |= (a << 8*(3-slot));
        slot++;
        a++;
        if (slot == 4) {
            slot = 0;
            v.push(word);
            word = 0;
        }
        bytes++;
    }
    if (slot !== 0) {
        v.push(word);
    }
    return CryptoJS.lib.WordArray.create(v, bytes);
}

// Test vectors from http://tools.ietf.org/rfc/rfc4868.txt
// Test vectors from http://tools.ietf.org/html/rfc4231.txt

var test_vectors = [
    { 
        "rfc" : 4231,
        "case" : 1, 
        "key" : make_wa_from_byte(0x0b, 20),
        "data" : "Hi There",
        "res" : "87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854"
    },

    { 
        "rfc" : 4231,
        "case" : 2,
        "key" : make_wa_from_byte (0xaa, 20),
        "data" : make_wa_from_byte (0xdd, 50),
        "res" : "fa73b0089d56a284efb0f0756c890be9b1b5dbdd8ee81a3655f83e33b2279d39bf3e848279a722c806b485a47e67c807b946a337bee8942674278859e13292fb"
    },

    {
        "rfc" : 4231,
        "case" : 3,
        "key" : "Jefe",
        "data": "what do ya want for nothing?",
        "res" : "164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea2505549758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737"
    },

    {
        "rfc" : 4231,
        "case" : 4,
        "key" : make_wa_from_bytes_between(0x01,0x19),
        "data" : make_wa_from_byte(0xcd,50),
        "res" : "b0ba465637458c6990e5a8c5f61d4af7e576d97ff94b872de76f8050361ee3dba91ca5c11aa25eb4d679275cc5788063a5f19741120c4f2de2adebeb10a298dd"
    },

    {
        "rfc" : 4231,
        "case" : 6,
        "key" : make_wa_from_byte (0xaa, 131),
        "data" : "Test Using Larger Than Block-Size Key - Hash Key First",
        "res" : "80b24263c7c1a3ebb71493c1dd7be8b49b46d1f41b4aeec1121b013783f8f3526b56d037e05f2598bd0fd2215d6a1e5295e64f73f63f0aec8b915a985d786598"
    },

    {
        "rfc" : 4231,
        "case" : 7,
        "key" : make_wa_from_byte(0xaa, 131),
        "data" : "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.",
        "res" : "e37b6a775dc87dbaa4dfa9f96e5e3ffddebd71f8867289865df5a32d20cdc944b6022cac3c4982b10d5eeb55c3e4de15134676fb6de0446065c97440fa8c6a58"

    },

    {
        "rfc" : 4868,
        "case" : 1,
        "key" : make_wa_from_byte (0x0b, 64),
        "data" : "Hi There",
        "res" : "637edc6e01dce7e6742a99451aae82df23da3e92439e590e43e761b33e910fb8ac2878ebd5803f6f0b61dbce5e251ff8789a4722c1be65aea45fd464e89f8f5b"

    },

    {
        "rfc" : 4868,
        "case" : 2,
        "key" : repeat_string("Jefe", 16),
        "data" : "what do ya want for nothing?",
        "res" : "cb370917ae8a7ce28cfd1d8f4705d6141c173b2a9362c15df235dfb251b154546aa334ae9fb9afc2184932d8695e397bfa0ffb93466cfcceaae38c833b7dba38"
    },
    
    {
        "rfc" : 4868,
        "case" : 3,
        "key" : make_wa_from_byte (0xaa, 64),
        "data" : make_wa_from_byte (0xdd, 50),
        "res" : "2ee7acd783624ca9398710f3ee05ae41b9f9b0510c87e49e586cc9bf961733d8623c7b55cebefccf02d5581acc1c9d5fb1ff68a1de45509fbe4da9a433922655"
    }

    ];

var j;
var rc = 0;
for (j = 0; j < test_vectors.length; j++) {
    var tv = test_vectors[j];
    var res = CryptoJS.HmacSHA512(tv.data, tv.key);
    if (res.toString() != tv.res) {
        console.log("XXX mismatch on test vector " + JSON.stringify (tv) + " /-> " + res +"\n");
        rc = 1;
    }
}

process.exit(rc);
