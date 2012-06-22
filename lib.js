
function isUpper(c) {
    return "A".charCodeAt(0) <= c && c <= "Z".charCodeAt(0);
}

function isLower(c) {
    return "a".charCodeAt(0) <= c && c <= "z".charCodeAt(0);
}

function isDigit (c) {
    return "0".charCodeAt(0) <= c && c <= "9".charCodeAt(0);
}

function is_ok_pw (input) {
    var v = 0;
    var i = 0;
    var nosym = true;
    for (i = 0; i < 16; i++) {
        var c = input.charCodeAt(i);
        var base = (i < 8);
        if (isDigit(c)) {
            if (base) { v |= 1; }
        } else if (isUpper(c)) {
            if (base) { v |= 2; }
        } else if (isLower(c)) {
            if (base) { v |= 4; }
        } else {
            nosym = false;
        }
    }
    return v == 7 && nosym;
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

        if (tail % d === 0 && is_ok_pw(b64)) {
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
