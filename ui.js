
var inputs={};

function acceptInput (event) { 
    var se = event.srcElement;
    if (!se.className.match("input-black")) {
        event.srcElement.className += " input-black";
        event.srcElement.value = "";
        inputs[se.id.split('-')[1]] = 1;
    }
    swizzle();
}

function swizzle () { 
    if (inputs.passphrase && inputs.domain && inputs.email) {
    }
    return 0;
}
