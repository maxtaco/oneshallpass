
var state = {
    seed : [],
    last_n : [],
    getFocus : false,
    randshorts : [],
    prev : []
}

// The number of bits of entropy in the password
var security_param = 58;

function $(n) { return document.getElementById(n); }

function acceptFocus(event) {
    var se = event.srcElement;
    if (!state.gotFocus) {
	se.value = "";
	state.gotFocus = true;
    }
}
function gotInput (event) {
    var se = event.srcElement;

    var kc = event.keyCode;

    var found = false;
    var n = 10;
    for (i = 0; i < n && !found; i++) {
	if (state.last_n[i] == kc) {
	    found = true;
	}
    }

    if (!found) {
	var v = state.last_n.slice(1);
	v.push(kc);
	state.last_n = v;
		 
	state.seed.push(new Date().getTime() % 100);
	state.seed.push(event.keyCode);
    
	var l = state.seed.length / 2;
	var txt;
	if (l > security_param) {
	    txt = "...computing...";
	    generate();
	} else {
	    txt = "I got " + l + " pieces of junk but I need MORE!"
	}
	$("pw-status").firstChild.nodeValue = txt;
    }
}

function sha_to_shorts (input) {
    var digest = CryptoJS.SHA512(input);
    var out = [];
    for (var i = 0; i < digest.words.length; i++) {
	word = digest.words[i];
	out.push(word & 0xffff);
	out.push((word >> 16) + 0x7fff);
    }
    console.log ("sha_to_shorts: " + input + " -> " + out.toString());
    return out;
}

function _gen1 () {
    if (state.randshorts.length == 0) {
	var input = state.seed.concat(state.lasthash);
	var v = sha_to_shorts(input.toString());
	state.lasthash = v.slice(0);
	state.randshorts = v;
    }
    var x = state.randshorts.pop()
    console.log ("_gen1() -> " + x);
    return x;
}

function log2(x) {
    return Math.log(x) / Math.log(2);
}

function gen1(hi) {
    console.log ("hi = " + hi);
    var nbits = Math.ceil(log2(hi));
    var res = -1;
    console.log ("nibts: " + nbits);
    var mask = ~(0x7fffffff << nbits);
    console.log ("mask: " +  mask);
    while (res < 0 || res >= hi) {
	res = _gen1() & mask;
    }
    console.log ("gen1() -> " + res);
    return res;
}

function generate_pw() {
    var n = Math.ceil(security_param / log2(dict.words.length));
    var w = [];
    for (var i = 0; i < n; i++) {
	w.push (dict.words[gen1(dict.words.length)]);
    }
    return w.join(" ");
}

function generate() {
    var n = 5;
    var pws = [];
    $("pw-status").style.display = "none";
    for (var i = 0; i < n; i++) {
	var el = $("pw-" + i);
	el.style.display = "inline-block";
	el.firstChild.nodeValue = generate_pw();
    }
}
    
