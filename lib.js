
function isUpper(c) {
    return "A".charCodeAt(0) <= c && c <= "Z".charCodeAt(0);
}

function isLower(c) {
    return "a".charCodeAt(0) <= c && c <= "z".charCodeAt(0);
}

function isDigit (c) {
    return "0".charCodeAt(0) <= c && c <= "9".charCodeAt(0);
}

// Rules for 'OK' passwords:
//    - Within the first 8 characters:
//       - At least one: uppercase, lowercase, and digit
//       - No more than 5 of any one character class
//       - No symbols
//    - From characters 7 to 16:
//       - No symbols
function is_ok_pw (input) {
    var v = 0;
    var i = 0;

    var caps = 0;
    var lowers = 0;
    var digits = 0;
    var symbols = 0;
    var c;

    for (i = 0; i < 8; i++) {
        c = input.charCodeAt(i);
        if (isDigit(c)) {
            digits++;
        } else if (isUpper(c)) {
            caps++;
        } else if (isLower(c)) {
            lowers++;
        } else {
            return false;
        }
    }
    if (digits === 0 || lowers === 0 || caps === 0 || 
        digits > 5 || lowers > 5 || caps > 5) {
        return false;
    }

    for ( ; i < 16; i++) {
        c = input.charCodeAt(i);
        if (!isDigit(c) && !isUpper(c) && !isLower(c)) {
            return false;
        }
    }

    return true;
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
