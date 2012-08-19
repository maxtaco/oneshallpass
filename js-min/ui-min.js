
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
    timeout : 60*5,   // timeout a PW in 5 minutes
    timer_event : function () { $("passphrase").value = ""; }
};

var cache_timer = {
    set : false,
    set_at : 0,
    wiggle_room : 30,
    timeout : 60*30, // timeout the cache in 30 minutes
    timer_event : function () { cache = {}; }
};


function unix_time () {
    return Math.floor ((new Date ()).getTime() / 1000);
}

var display_prefs = {};

function key_data (data) {
    var tmp = [ data.version ];
    if (data.version == 1) {
	tmp = tmp.concat([data.email, data.passphrase, 
			  data.host, data.generation, data.secbits ]);
    } else {
	tmp = tmp.concat([data.email, data.passphrase, data.secbits ]);
    }
    var key = tmp.join(";");
    data.key = key;
}

function $(n) { return document.getElementById(n); }

function toggle_computing() {
    $('result-need-input').style.visibility = "hidden";
    $('result-computing').style.visibility = "visible";
    $('result-computed').style.visibility = "hidden";
}

function selectText(e) {
    e.srcElement.focus();
    e.srcElement.select();
}

function toggle_computed () {
    $('result-need-input').style.visibility = "hidden";
    $('result-computed').style.visibility = "visible";
    $('result-computing').style.visibility = "hidden";
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

function format_pw (input) {
    var ret = input.slice(0, display_prefs.length);
    ret = add_syms (ret, display_prefs.nsym);
    return ret;
}

function finish_compute (obj) {
    obj.computing = false;
    context.key = null;

    // v1 is done, but V2 has to run one last HMAC to
    // sign for this particular site.
    if (obj.version == 2) {
	pw = v2_finish_compute (obj);
    } else if (obj.version == 1) {
	pw = obj.generated_pw;
    }

    toggle_computed();
    $("generated_pw").value = format_pw(pw);
}

function display_computing (val) {
    var e = $("computing").firstChild;
    e.nodeValue = "computing.... " + val;
}

function versioned_pwgen(obj, iters, context) {
    var r = false;
    if (obj.version == 1) {
	r = v1_pwgen(obj,iters,context);
    } else if (obj.version == 2) {
	r = v2_pwgen(obj,iters,context);
    }
    return r;
}

function do_compute_loop (key, obj) {
    var my_obj = obj;
    var iters = 10;
    if (key != context.key) {
        /* bail out, we've changed to a different computation ... */
    } else if (versioned_pwgen(obj, iters, context)) {
        finish_compute (obj);
    } else {
        display_computing(obj.iter);
        /* don't block the browser */
        setTimeout (function () { do_compute_loop (key, my_obj); }, 0); 
    }
}

function make_compute_obj_from_cache (data, co) {
    var ret = {};
    if (data.version == 1) {
	ret = co;
    } else if (data.version == 2) {
	data.DK = co.DK;
	ret = data;
    }
    return ret;
}

function do_compute (data) {
    toggle_computing();
    var key = data.key;
    var co = cache[key];
    if (!co) {
        cache[key] = data;
        co = data;
    }
    if (co.compute_done) {
        finish_compute (make_compute_obj_from_cache (data, co));
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

function v1_clean_passphrase (pp) {
    var tmp = trim(pp);
    // Replace any interior whitespace with just a single
    // plain space, but otherwise, interior whitespaces
    // count as part of the passphrase.
    return tmp.replace(/\s+/g, " ");
}

function v2_clean_passphrase (pp) {
    // whitespace doesn't count anywhere
    return pp.replace(/\s+/g, "");
}

function clean_passphrase (pp, vv) {
    if (vv == 1) {
	return v1_clean_passphrase(pp);
    } else if (vv == 2) {
	return v2_clean_passphrase(pp);
    }
}

function set_timer (tmobj) {
    var now = unix_time();
    if (!tmobj.set || (now - tmobj.set_at) > tmobj.wiggle_room) {
	tmobj.set = true;
	tmobj.set_at = now;
	setTimeout(function () { timer_event(tmobj); }, 
		   tmobj.timeout*1000);
    }
}

function timer_event (tmobj) {
    var now = unix_time();
    if (tmobj.set && (now - tmobj.set_at) >= tmobj.timeout) {
	tmobj.set = false;
	tmobj.set_at = 0;
	tmobj.timer_event();
    }
}

function set_all_timers () {
    set_timer(pp_timer);
    set_timer(cache_timer);
}

function pp_input (event) {
    set_all_timers();
    swizzle(event);
}

function swizzle (event) { 

    var se = event.srcElement;
    if (se.value.length > 0) {
        inputs[se.id] = 1;
    }

    var email, passphrase, host;
    var version = $("version").value;

    if (inputs.passphrase && inputs.host && inputs.email) {
	email = clean_email ( $("email").value )
	passphrase = clean_passphrase ( $("passphrase").value, version )
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
	data.version = version;
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
    var params = [ "email", "version", "length", "secbits", "passphrase" ];
    var i;
    for (i in params) {
	curr = params[i];
	if (typeof(p[curr]) != "undefined" && p[curr].length > 0) {
            var e = $(curr);
            ungray(e);
            e.value = p[curr];
            inputs[curr] = 1;
	}
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
