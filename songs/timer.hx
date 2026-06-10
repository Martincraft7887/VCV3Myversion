// hi, credit to chuyun for the original script! i ended up modifying it to what is now (X:XX / X:XX format + song title), so i figured credit was due
// if you want to check out the original, head on over to https://gamebanana.com/tools/16673

import openfl.geom.Rectangle;
import openfl.text.TextFormat;
import flixel.text.FlxTextBorderStyle;
import flixel.ui.FlxBar;
import flixel.FlxG;

var timeTxt:FlxText;
var songnameTxt:FlxText;

function create() {
    timeTxt = new FlxText(0, 25, 400, "X:XX", 32);
    timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    timeTxt.scrollFactor.set();
    timeTxt.alpha = 0;
    timeTxt.borderColor = 0xFF000000;
    timeTxt.borderSize = 2;
    timeTxt.screenCenter(FlxAxes.X);
	timeTxt.bold = true;
    add(timeTxt);

    timeTxt.cameras = [camHUD];
	
	songnameTxt = new FlxText(0, 5, 400, curSong.toUpperCase(), 32);
    songnameTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    songnameTxt.scrollFactor.set();
    songnameTxt.alpha = 0;
    songnameTxt.borderColor = 0xFF000000;
    songnameTxt.borderSize = 2;
    songnameTxt.screenCenter(FlxAxes.X);
	songnameTxt.bold = true;
    add(songnameTxt);

    songnameTxt.cameras = [camHUD];
}

function onSongStart() {
    if (timeTxt != null) {
    FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    }
	FlxTween.tween(songnameTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
}

function update(elapsed:Float) {

    if (inst != null && timeTxt != null) {
        var timeRemaining = Std.int((Conductor.songPosition) / 1000);
		var timeLength = Std.int((inst.length) / 1000);
        var seconds = CoolUtil.addZeros(Std.string(timeRemaining % 60), 2);
        var minutes = Std.int(timeRemaining / 60);
		var secondsL = CoolUtil.addZeros(Std.string(timeLength % 60), 2);
        var minutesL = Std.int(timeLength / 60);
        timeTxt.text = minutes + ":" + seconds + " / " + minutesL + ":" + secondsL;
    }
   
    }