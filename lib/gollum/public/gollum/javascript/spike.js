document.getElementById("highlight-menu").style.display="none";
function gText(e) {
    if (getSelectionText() != ""){
      document.getElementById("highlight-menu").style.display="inline";
    }
    else{
      document.getElementById("highlight-menu").style.display="none";
    }
}

document.onmouseup = gText;
if (!document.all) document.captureEvents(Event.MOUSEUP);

function getSelectionText() {
    var text = "";
    if (window.getSelection) {
        text = window.getSelection().toString();
    } else if (document.selection && document.selection.type != "Control") {
        text = document.selection.createRange().text;
    }
    return text;
}
