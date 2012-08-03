
var inputs = {};
var cache = {};
var browser = {};

var context = {
    running : 0,
    key : null
};

var pp_timer = {
    set : false,
    set_at : 0,
    wiggle_room : 30, // don't sweat about 30 s in either direction
    timeout : 60*5    // timeout a PW in 5 minutes
}

function unix_time () {
    return Math.floor ((new Date ()).getTime() / 1000);
}

var display_prefs = {};

function key_data (data) {
    var tmp = [ data.email, data.passphrase, data.host, data.generation, data.secbits ];
    var key = tmp.join(";");
    data.key = key;
}

function $(n) { return document.getElementById(n); }

function toggle_computing() {
    $('result-need-input').style.visibility = "hidden";
    $('result-computing').style.visibility = "visible";
    $('result-computed').style.visibility = "hidden";
    $('select').style.visibility = "hidden";
}

function toggle_computed () {
    $('result-need-input').style.visibility = "hidden";
    $('result-computed').style.visibility = "visible";
    $('select').style.visibility = "visible";
    $('result-computing').style.visibility = "hidden";
}


function fnDeSelect() {
    if (document.selection) { 
        document.selection.empty(); 
    } else if (window.getSelection) { 
        window.getSelection().removeAllRanges(); 
    }
}

function fnSelect(obj) {
    fnDeSelect();
    var range;
    if (browser.mobsafari) {
	obj.focus();
	obj.setSelectionRange(0,16);
    } else if (document.selection) {
        range = document.body.createTextRange();
        range.moveToElementText(obj);
        range.select();
    } else if (window.getSelection) {
        range = document.createRange();
        range.selectNode(obj);
        window.getSelection().addRange(range);
    } 
}

function get_url_params() {
    var urlParams = {};
    var match,
        pl     = /\+/g,  // Regex for replacing addition symbol with a space
        search = /([^&=]+)=?([^&]*)/g,
        decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
        query  = window.location.hash.substring(1);

    while ((match = search.exec(query))) {
       urlParams[decode(match[1])] = decode(match[2]);
    }
    return urlParams;
}


function select_pw (event) {
    var e = $("generated_pw").firstChild;
    fnSelect(e); 
}

function format_pw (input) {
    var ret = input.slice(0, display_prefs.length);
    ret = add_syms (ret, display_prefs.nsym);
    return ret;
}

function finish_compute (obj) {
    obj.computing = false;
    context.key = null;
    toggle_computed();
    var e = $("generated_pw").firstChild;
    e.nodeValue = format_pw (obj.generated_pw);
}

function display_computing (val) {
    var e = $("computing").firstChild;
    e.nodeValue = "computing.... " + val;
}

function do_compute_loop (key, obj) {
    var my_obj = obj;
    var iters = 10;
    if (key != context.key) {
        /* bail out, we've changed to a different computation ... */
    } else if (pwgen(obj, iters, context)) {
        finish_compute (obj);
    } else {
        display_computing(obj.iter);
        /* don't block the browser */
        setTimeout (function () { do_compute_loop (key, my_obj); }, 0); 
    }
}

function do_compute (data) {
    toggle_computing();
    var key = data.key;
    var co = cache[key];
    if (!co) {
        cache[key] = data;
        co = data;
    }
    if (co.generated_pw) {
        finish_compute (co);
    } else if (!co.computing) {
        context.key = key;
        co.computing = true;
        co.iter = 0;
        display_computing("");
        setTimeout(function() { do_compute_loop (key, co); }, 500);
    }
}

function trim (w) {
    var rxx = /^(\s*)(.*?)(\s*)$/; 
    var m = w.match (rxx);
    return m[2];
}

function clean_host (h) {
    return trim(h).toLowerCase();
}

function clean_email (em) {
    return trim(em).toLowerCase();
}

function clean_passphrase (pp) {
    var tmp = trim(pp);
    // Replace any interior whitespace with just a single
    // plain space, but otherwise, interior whitespaces
    // count as part of the passphrase.
    return tmp.replace(/\s+/g, " ");
}

function pp_set_timer () {
    var now = unix_time();
    if (!pp_timer.set || (now - pp_timer.set_at) > pp_timer.wiggle_room) {
	pp_timer.set = true;
	pp_timer.set_at = now;
	setTimeout(pp_timer_event, pp_timer.timeout*1000);
    }
}

function pp_timer_event () {
    var now = unix_time();
    if (pp_timer.set && (now - pp_timer.set_at) >= pp_timer.timeout) {
	$("passphrase").value = "";
	cache = {};
	pp_timer.set = false;
	pp_timer.set_at = 0;
    }
}

function pp_input (event) {
    pp_set_timer();
    swizzle(event);
}

function swizzle (event) { 

    var se = event.srcElement;
    if (se.value.length > 0) {
        inputs[se.id] = 1;
    }

    var email, passphrase, host;

    if (inputs.passphrase && inputs.host && inputs.email) {
	email = clean_email ( $("email").value )
	passphrase = clean_passphrase ( $("passphrase").value )
	host = clean_host ( $("host").value );
    }

    if (passphrase && passphrase.length && host && host.length && email && email.length) {
        var data = {
	    "email" : email,
	    "host" : host,
	    "passphrase" : passphrase };

        var fields = [ "generation", "secbits" ];
        var i, f, v;
        for (i = 0; i < fields.length; i++) {
            f = fields[i];
            v = $(f).value;
            data[f] = v;
        }
        display_prefs.length = $("length").value;
        display_prefs.nsym = $("nsym").value;

        // Key the data, so that we can look it up in a hash-table.
        key_data (data);

        do_compute(data);
    }
    return 0;
}

function ungray(element) {
    element.className += " input-black";
}

function acceptFocus (event) { 
    var se = event.srcElement;
    if (!se.className.match("input-black")) {
        ungray(se);
        se.value = "";
    }
}

function prepopulate() {
    var p = get_url_params();
    if (typeof(p.email) != "undefined" && p.email.length > 0) {
        var e = $("email");
        ungray(e);
        e.value = p.email;
        inputs.email = 1;
    }
}

function domobiles() {
    
    var mobsafari = (/iphone|ipad|ipod/i.test(navigator.userAgent.toLowerCase()));
    var mobile =(/android|blackberry/i.test(navigator.userAgent.toLowerCase()));
    if (mobsafari) {
	browser.mobsafari = true;
	$('email').type = "email";
    }
    
}

function doExpand(event) {
	$('expander').style.display = "none";
	$('advanced').style.display = "inline";
}

function doCollapse(event) {
	$('expander').style.display = "inline";
 	$('advanced').style.display = "none";
}
