import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

var uiHidden:Bool = false;
var uiToggleTxt:FlxText = null;

function update(elapsed:Float) {
    if (FlxG.keys.justPressed.F4) {
        toggleUI();
    }
    
    if (uiHidden) {
        if (scoreTxt != null) scoreTxt.visible = false;
        if (missesTxt != null) missesTxt.visible = false;
        if (accuracyTxt != null) accuracyTxt.visible = false;
        if (uiToggleTxt != null) uiToggleTxt.visible = true;
    } else {
        if (scoreTxt != null) scoreTxt.visible = true;
        if (missesTxt != null) missesTxt.visible = true;
        if (accuracyTxt != null) accuracyTxt.visible = true;
        if (uiToggleTxt != null) uiToggleTxt.visible = false;
    }
}

function toggleUI() {
    uiHidden = !uiHidden;
}

function onNoteHit(event) {
}