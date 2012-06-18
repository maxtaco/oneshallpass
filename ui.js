
var inputs={};

var context = {
    attempt : 1,
    running : 0
};

function swizzle (event) { 

    var se = event.srcElement;
    inputs[se.id.split('-')[1]] = 1;

    if (inputs.passphrase && inputs.domain && inputs.email && inputs.version) {
        var data = {};
        var fields = [ "passphrase", "domain", "email", "version",
                       "secbits", "nsym", "length" ];
        var i;
        for (i = 0; i < fields.length; i++) {
            if (true) {
                var f = fields[i];
                var k = "field-" + f;
                var v = document.getElementById(k).value;
                data[f] = v;
            }
        }
        var attempt = context.attempt;
        context.attempt ++;
        compute (attempt, context, data, document.getElementById("result"));
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

