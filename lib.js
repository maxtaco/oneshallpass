
function isUpper(c) {
    return "A".charCodeAt(0) <= c && c <= "Z".charCodeAt(0);
}

function isLower(c) {
    return "a".charCodeAt(0) <= c && c <= "z".charCodeAt(0);
}

function isDigit (c) {
    return "0".charCodeAt(0) <= c && c <= "9".charCodeAt(0);
}

function is_varied_pw (input) {
    var v = 0;
    var i = 0;
    for (i = 0; v != 7 &&  i < 8; i++) {
        var c = input.charCodeAt(i);
        if (isDigit(c)) {
            v |= 1;
        } else if (isUpper(c)) {
            v |= 2;
        } else if (isLower(c)) {
            v |= 4;
        }
    }
    return v == 7;
}

// a weird base64 encoding that always winds up with at least
// 1 digit, 1 upper, and 1 lower in the first 8 characters...
function shifting_base64 (hash) {
    var orig_map = CryptoJS.enc.Base64._map;
    var map = orig_map;
    var cut = 32;
    var x;
    var go = true;
    var i = 0;
    while (go) {
        x = hash.toString(CryptoJS.enc.Base64);
        if (is_varied_pw (x)) {
            go = false;
        } else {
            map = map.slice(cut,64) + map.slice(0, cut);
            cut--;
            if (cut < 1) { cut = 32; }
            CryptoJS.enc.Base64._map = map;
        }
        i++;
    } 
    CryptoJS.enc.Base64._map = orig_map;
    return x;
}


function pwgen (obj, iters, context) {

    obj.generated_pw = null;
    var d = 1 << parseInt(obj.secbits, 10);
    var i;
    for (i = 0; i < iters && !obj.generated_pw && obj.key == context.key; i++) {

        var arr = [ "PassThePeas v1.0", obj.email, obj.domain, 
                    obj.generation, obj.iter ];
        var text = arr.join ("; ");
        var hash = CryptoJS.HmacSHA512(text, obj.passphrase);
        var b16 = hash.toString();
        var b64 = hash.toString(CryptoJS.enc.Base64);

        var tail = parseInt(b16.slice (b16.length-8, b16.length), 16);

        if (tail % d === 0 && is_varied_pw(b64)) {
            obj.generated_pw = b64;
        } else {
            obj.iter++;
        }
    }
    var ret = !!obj.generated_pw;
    return ret;
}


function translate_at_indices (input, indices, _map) {

    var last = 0;
    var arr = [];
    for (var j = 0; j < indices.length; j++) {
        var index = indices[j];
        arr.push (input.slice(last, index));
        var c = input.charAt(index);
        var i = CryptoJS.enc.Base64._map.indexOf(c);
        c = _map.charAt(i%_map.length);
        arr.push (c);
        last = index+1;
    }
    arr.push(input.slice(last, input.length));
    return arr.join("");
}

function add_syms_at_indices (input, indices) {
    var _map = "`~!@#$%^&*()-_+={}[]|;:,<>.?/";
    return translate_at_indices(input, indices, _map);
}

function add_syms (input, n) {
    var indices = []
    if (n*2 > input.length) {
        n = input.length / 2;
    }
    for (var i = 0; i < n; i++) {
        indices.push(2*i + 1);
    }
    return add_syms_at_indices(input, indices);
}

if (typeof(exports) != "undefined") {
    exports.add_syms = add_syms;
    exports.add_syms_at_indices = add_syms_at_indices;
    exports.pwgen = pwgen;
}
