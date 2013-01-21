
var state = {
    seed : [],
    last_n : [],
    getFocus : false,
    randshorts : [],
    prev : [],
    security_param : 58,
    showing_res : false,
    first_gen : null
};

function log2(x) {
    return Math.log(x) / Math.log(2);
}

function sha_to_shorts (input) {
    var digest = CryptoJS.SHA512(input);
    var out = [];
    var i;
    for (i = 0; i < digest.words.length; i++) {
	word = digest.words[i];
	out.push(word & 0xffff);
	out.push((word >> 16) + 0x7fff);
    }
    return out;
}

function $(n) { return document.getElementById(n); }

function acceptFocus(event) {
    var se = event.srcElement;
    if (!state.gotFocus) {
	se.value = "";
	state.gotFocus = true;
    }
}

function _gen1 () {
    if (state.randshorts.length === 0) {
	var input = state.seed.concat(state.lasthash);
	var v = sha_to_shorts(input.toString());
	state.lasthash = v.slice(0);
	state.randshorts = v;
    }
    var x = state.randshorts.pop();
    return x;
}

function gen1(hi) {
    var nbits = Math.ceil(log2(hi));
    var res = -1;
    var mask = ~(0x7fffffff << nbits);
    while (res < 0 || res >= hi) {
	res = _gen1() & mask;
    }
    return res;
}

function generate_pp() {
    var n = Math.ceil(state.security_param / log2(dict.words.length));
    var w = [];
    var i;
    for (i = 0; i < n; i++) {
	w.push (dict.words[gen1(dict.words.length)]);
    }
    return w.join(" ");
}

function show_results() {
    $("pp-status").style.display = "none";
    $("pp-0").style.display = "inline-block";
    state.showing_res = true;
}

function generate() {
    $("pp-0").firstChild.nodeValue = generate_pp();
    show_results();
}

function hide_results() {
    $("pp-status").style.display = "inline-block";
    $("pp-0").style.display = "none";
    state.showing_res = false;
}

// Wait 3 seconds or so between the first generation
// and any subsequent generations
function maybe_generate_2() {
    var go = false;
    var now = (new Date()).getTime();
    if (!state.first_gen) {
        state.first_gen = now;
        go = true;
    } else if (now - state.first_gen > 3000) {
        go = true;
    }
    if (go) {
        generate();
    }
}

function maybe_generate() {
    
    var l = state.seed.length / 2;
    if (l > 0) {
        var txt;
        if (l > state.security_param) {
            txt = "...computing...";
            maybe_generate_2();
        } else {
            if (state.showing_res) {
                hide_results();
            }
            txt = "Collected " + l + " of " + 
		state.security_param + "; need MORE";
        }
        $("pp-status").firstChild.nodeValue = txt;
    }
}

function gotInput (event) {
    var se = event.srcElement;
    
    var kc = event.keyCode;

    var found = false;
    var n = 5;
    for (i = 0; i < n && !found; i++) {
	if (state.last_n[i] == kc) {
	    found = true;
	}
    }
    
    if (!found) {
	var v = state.last_n;
	if (v.length == n) {
            v = v.slice(1);
	}
	v.push(kc);
	state.last_n = v;
	state.seed.push(new Date().getTime() % 100);
	state.seed.push(event.keyCode);
	maybe_generate();
    }
}

function entropyChanged(event) {
    state.security_param = event.srcElement.value;
    maybe_generate();
}

