import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.system.Conductor;
import funkin.game.PlayState;

var skipTxt:FlxText;

var firstPlayerTime:Float = -1;
var firstOpponentTime:Float = -1;
var firstSingTime:Float = -1;

var skipTargetTime:Float = 0;

var canSkip:Bool = true;
var skipped:Bool = false;

var skipVisibleTime:Float = 0;

function forceSongSeek(time:Float)
{
    var ps = PlayState.instance;
    if (ps == null) return;

    var target = Math.max(0, time);

    Conductor.songPosition = target;

    if (ps.inst != null)
    {
        ps.inst.pause();
        ps.inst.time = target;
    }

    if (ps.vocals != null)
    {
        ps.vocals.pause();
        ps.vocals.time = target;
    }

    try {
        scripts.call("forceModchartSeekSync", [Conductor.getStepForTime(target)]);
    } catch(e:Dynamic) {}

    if (ps.inst != null) ps.inst.play();
    if (ps.vocals != null) ps.vocals.play();
    ps.resyncVocals();
}

function postCreate()
{
    skipTxt = new FlxText(0, 100, FlxG.width, "PRESS SHIFT TO SKIP", 28);
    skipTxt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, "center");
    skipTxt.scrollFactor.set();
    skipTxt.screenCenter(FlxAxes.X);
    skipTxt.cameras = [camOther];
    skipTxt.alpha = 0;
    add(skipTxt);
}

function onNoteCreation(event)
{
    if (event.note.isSustainNote) return;

    if (event.note.mustPress)
    {
        if (firstPlayerTime < 0 || event.note.strumTime < firstPlayerTime)
            firstPlayerTime = event.note.strumTime;
    }
    else
    {
        if (firstOpponentTime < 0 || event.note.strumTime < firstOpponentTime)
            firstOpponentTime = event.note.strumTime;
    }

    var earliest:Float = -1;

    if (firstPlayerTime >= 0 && firstOpponentTime >= 0)
        earliest = Math.min(firstPlayerTime, firstOpponentTime);
    else if (firstPlayerTime >= 0)
        earliest = firstPlayerTime;
    else if (firstOpponentTime >= 0)
        earliest = firstOpponentTime;

    if (earliest >= 0)
    {
        firstSingTime = earliest;
        skipTargetTime = Math.max(0, firstSingTime - (Conductor.stepCrochet * 12));
    }
}

function update(elapsed:Float)
{
    if (skipTxt == null) return;

    var ps = PlayState.instance;
    if (ps == null) return;

    if (ps.startingSong)
    {
        skipTxt.alpha = 0;
        return;
    }

    // mostrar texto
    if (skipTxt.alpha < 1 && skipVisibleTime < 2)
        skipTxt.alpha += elapsed * 2;

    // contar tiempo visible
    skipVisibleTime += elapsed;

    // desaparecer después de 2 segundos
    if (skipVisibleTime >= 2 || skipped)
        skipTxt.alpha -= elapsed * 2;

    // detectar tecla
    if (FlxG.keys.justPressed.SHIFT && canSkip && !skipped && Conductor.songPosition < skipTargetTime)
    {
        skipped = true;
        canSkip = false;
        forceSongSeek(skipTargetTime);
    }
}
