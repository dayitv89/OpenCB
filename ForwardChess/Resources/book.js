var CurVar=0, activeAnchor=-1, startAnchor=-1, activeAnchorBG = "#CCCCCC", TargetDocument, isSetupBoard=false, BoardSetupMode='copy';
function SetMove(mm_vv) { 
    if (parent.frames[0].SetMove) 
        parent.frames[0].SetMove(mm_vv); 
}

function contents_href(key) {
    location.hash = key;
}

function HighlightMove(nn) { 
    var ii, cc, bb, jj=0, ll=document.anchors.length;
    if (ll == 0) 
        return;
    if (! document.anchors[0].style) 
        return;
    if ((activeAnchor >= 0) && (ll > activeAnchor)) { 
        document.anchors[activeAnchor].style.backgroundColor = "";
        activeAnchor = -1;
    }
    if (isNaN(startAnchor)) { 
        while ((jj<ll) && (document.anchors[jj].name != startAnchor)) jj++;
    }
    for (ii=jj; ((ii<ll) && (activeAnchor < 0)); ii++) { 
        if (document.anchors[ii].name == nn) { 
            activeAnchor = ii;
            document.anchors[activeAnchor].style.backgroundColor = activeAnchorBG;
            window.scrollTo(0,findPosY(document.anchors[activeAnchor])-(window.innerHeight/2 - 10));
            return;
        }
    }
}

function HighlightMoveNoScrolling(nn) {
    var ii, cc, bb, jj=0, ll=document.anchors.length;
    if (ll == 0)
        return;
    if (! document.anchors[0].style)
        return;
    if ((activeAnchor >= 0) && (ll > activeAnchor)) {
        document.anchors[activeAnchor].style.backgroundColor = "";
        activeAnchor = -1;
    }
    if (isNaN(startAnchor)) {
        while ((jj<ll) && (document.anchors[jj].name != startAnchor)) jj++;
    }
    for (ii=jj; ((ii<ll) && (activeAnchor < 0)); ii++) {
        if (document.anchors[ii].name == nn) {
            activeAnchor = ii;
            document.anchors[activeAnchor].style.backgroundColor = activeAnchorBG;
            //window.scrollTo(0,findPosY(document.anchors[activeAnchor])-(window.innerHeight/2 - 10));
            return;
        }
    }
}



function findPosY(obj) {
    var curtop = 0;
    if (obj.offsetParent) {
        while (1) {
            curtop+=obj.offsetTop;
            if (!obj.offsetParent) {
                break;
            }
            obj=obj.offsetParent;
        }
    } else if (obj.y) {
        curtop+=obj.y;
    }
    return curtop;
}