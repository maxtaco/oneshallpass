
var inputs = {};
var cache = {};

var context = {
    attempt : 1,
    running : 0,
    key : null
};

var display_prefs = {};

function key_data (data) {
    var tmp = [ data.email, data.passphrase, data.domain, data.generation, data.secbits ];
    var key = tmp.join(";");
    data.key = key;
}

function format_pw (input) {
    var ret = input.slice(0, display_prefs.length);
    ret = add_syms (ret, display_prefs.nsym);
    return ret;
}

function finish_compute (obj) {
    obj.computing = false;
    context.key = null;
    var e = document.getElementById("generated_pw").firstChild;
    e.nodeValue = format_pw (obj.generated_pw);
}

function do_compute_loop (key, obj) {
    var my_obj = obj;
    var iters = 100;
    if (key != context.key) {
        console.log ("dbg 1 " + obj.key);
        /* bail out, we've changed to a different computation ... */
    } else if (pwgen(obj, iters, context)) {
        console.log ("dbg 2 " + obj.key + " -> " + obj.generated_pw);
        finish_compute (obj);
    } else {
        console.log ("dbg 3 " + obj.key);
        /* don't block the browser */
        setTimeout (function () { do_compute_loop (key, my_obj); }, 0); 
    }
}

function do_compute (data) {
    var key = data.key;
    var co = cache[key];
    if (!co) {
        cache[key] = data;
        co = data;
        console.log ("cache miss for " + key);
    }
    if (co.generated_pw) {
        finish_compute (co);
    } else if (!co.computing) {
        context.key = key;
        co.computing = true;
        co.iter = 0;
        do_compute_loop (key, co);
    }
}

function swizzle (event) { 

    var se = event.srcElement;
    inputs[se.id.split('-')[1]] = 1;

    if (inputs.passphrase && inputs.domain && inputs.email && inputs.generation) {
        var data = {};
        var fields = [ "passphrase", "domain", "email", "generation", "secbits" ];
        var i;
        for (i = 0; i < fields.length; i++) {
            if (true) {
                var f = fields[i];
                var k = "field-" + f;
                var v = document.getElementById(k).value;
                data[f] = v;
            }
        }
        display_prefs.length = document.getElementById("field-length").value;
        display_prefs.nsym = document.getElementById("field-nsym").value;

        // Key the data, so that we can look it up in a hash-table.
        key_data (data);

        do_compute(data);
    }
    return 0;
}

function acceptInput (event) { 
    var se = event.srcElement;
    if (!se.className.match("input-black")) {
        event.srcElement.className += " input-black";
        event.srcElement.value = "";
    }
}

