
var inputs={};

function acceptInput (event, fieldname) {
    var se = event.srcElement;
    if (!se.className.match("input-black")) {
        event.srcElement.className += " input-black";
        event.srcElement.value = "";
        inputs[fieldname] = 1;
    }
}
