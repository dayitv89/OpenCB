var rgbRegex = /^rgb\(\s*(-?\d+)(%?)\s*,\s*(-?\d+)(%?)\s*,\s*(-?\d+)(%?)\s*\)$/,
hexRegex = /^#?([a-f\d]{6})$/,
shortHexRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/;

// http://stackoverflow.com/questions/1335252/how-can-i-get-the-dom-element-which-contains-the-current-selection
function getSelectionBoundaryElement(isStart) {
    var range, sel, container;
    if (document.selection) {
        range = document.selection.createRange();
        range.collapse(isStart);
        return range.parentElement();
    } else {
        sel = window.getSelection();
        if (sel.getRangeAt) {
            if (sel.rangeCount > 0) {
                range = sel.getRangeAt(0);
            }
        } else {
            // Old WebKit
            range = document.createRange();
            range.setStart(sel.anchorNode, sel.anchorOffset);
            range.setEnd(sel.focusNode, sel.focusOffset);
            
            // Handle the case when the selection was selected backwards (from the end to the start in the document)
            if (range.collapsed !== sel.isCollapsed) {
                range.setStart(sel.focusNode, sel.focusOffset);
                range.setEnd(sel.anchorNode, sel.anchorOffset);
            }
        }
        
        if (range) {
            container = range[isStart ? "startContainer" : "endContainer"];
            
            // Check if the container is a text node and return its parent if so
            return container.nodeType === 3 ? container.parentNode : container;
        }
    }
}

function save()
{
    return document.body.innerHTML;
}

function restore(html)
{
    document.body.innerHTML = html;
}

function makeEditableAndHighlight__(colour, range) {
    var sel = window.getSelection();
    document.designMode = "on";
    if (range) {
        sel.removeAllRanges();
        sel.addRange(range);
    }
    // Use HiliteColor since some browsers apply BackColor to the whole block
    if (!document.execCommand("HiliteColor", false, colour)) {
        document.execCommand("BackColor", false, colour);
    }
    document.designMode = "off";
}

function makeEditableAndHighlight(colour) {
    var range, sel = window.getSelection();
    if (sel.rangeCount && sel.getRangeAt) {
        range = sel.getRangeAt(0);
    }
    makeEditableAndHighlight__(colour, range);
}

function componentFromStr(numStr, percent) {
    var num = Math.max(0, parseInt(numStr, 10));
    return percent ? Math.floor(255 * Math.min(100, num) / 100) : Math.min(255, num);
}

function highlight(colour) {
    var range;
    if (window.getSelection) {
        // IE9 and non-IE
        try {
            if (!document.execCommand("BackColor", false, colour)) {
                makeEditableAndHighlight(colour);
            }
        } catch (ex) {
            makeEditableAndHighlight(colour)
        }
    } else if (document.selection && document.selection.createRange) {
        // IE <= 8 case
        range = document.selection.createRange();
        range.execCommand("BackColor", false, colour);
    }
}

function isHighlighted() {
    var range, sel = window.getSelection();
    if (sel.rangeCount && sel.getRangeAt) {
        range = sel.getRangeAt(0);
    }
    document.designMode = "on";
    
    var state = document.queryCommandValue('backColor');
    var highlighted = !(state === 'rgba(0, 0, 0, 0)' || state === 'rgba(0, 0, 0)');
    
    document.designMode = "off";
    return highlighted;
}

function Colour(r, g, b) {
    // Make a new Colour object even when Colour is not called with the new operator
    if (!(this instanceof Colour)) {
        return new Colour(r, g, b);
    }
    
    if (typeof g == "undefined") {
        // Parse the colour string
        var colStr = r.toLowerCase(), result;
        
        // Check for hex value first, the short hex value, then rgb value
        if ( (result = hexRegex.exec(colStr)) ) {
            var hexNum = parseInt(result[1], 16);
            r = hexNum >> 16;
            g = (hexNum & 0xff00) >> 8;
            b = hexNum & 0xff;
        } else if ( (result = shortHexRegex.exec(colStr)) ) {
            r = parseInt(result[1] + result[1], 16);
            g = parseInt(result[2] + result[2], 16);
            b = parseInt(result[3] + result[3], 16);
        } else if ( (result = rgbRegex.exec(colStr)) ) {
            r = componentFromStr(result[1], result[2]);
            g = componentFromStr(result[3], result[4]);
            b = componentFromStr(result[5], result[6]);
        } else {
            throw new Error("Colour: Unable to parse colour string '" + colStr + "'");
        }
    }
    
    this.r = r;
    this.g = g;
    this.b = b;
}

Colour.prototype = {
equals: function(colour) {
    return this.r == colour.r && this.g == colour.g && this.b == colour.b;
}
};

// http://stackoverflow.com/questions/8076341/remove-highlight-added-to-selected-text-using-javascript
function unhighlight(node, colour) {
    if (!(colour instanceof Colour)) {
        colour = new Colour(colour);
    }
    
    if (node.nodeType == 1) {
        var bg = node.style.backgroundColor;
        if (bg && colour.equals(new Colour(bg))) {
            node.style.backgroundColor = "";
        }
    }
    var child = node.firstChild;
    while (child) {
        unhighlight(child, colour);
        child = child.nextSibling;
    }
}

function action()
{
    if (isHighlighted()) {
        unhighlight(getSelectionBoundaryElement(true), '#ffff00');
    } else {
        highlight('#ff0');
    }
}