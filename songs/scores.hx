import flixel.text.FlxTextBorderStyle;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.game.PlayState;
var hudVisible:Bool = true;
var hudBase:FlxText;
var hudRating:FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
var disabledSongs = [
    "final destination vip",
    "rejected vip"
];

function isDisabledSong():Bool
{
    return curSong != null && disabledSongs.contains(curSong.toLowerCase());
}
function postCreate()
{
    trace(curSong);
    var ps = PlayState.instance;
    if (ps == null) return;

    // ❌ No aplicar en esta canción
    if (isDisabledSong()) return;
    // Ocultar HUD original
    ps.scoreTxt.visible = false;
    ps.missesTxt.visible = false;
    ps.accuracyTxt.visible = false;

    // Texto base
    hudBase = new FlxText(0, FlxG.height - 30, 0, "");
        hudBase.setFormat(
            Paths.font("Contb___.ttf"),
            18,
            FlxColor.WHITE,
            "left",
            FlxTextBorderStyle.OUTLINE,
            FlxColor.BLACK
        );

        hudBase.borderSize = 2;
        hudBase.borderQuality = 2;
    hudBase.scrollFactor.set();
    hudBase.cameras = [ps.camHUD];
    add(hudBase);

    // Texto rating
    hudRating = new FlxText(0, FlxG.height - 30, 0, "");

    hudRating.setFormat(
        Paths.font("Contb___.ttf"),
        18,
        FlxColor.WHITE,
        "left",
        FlxTextBorderStyle.OUTLINE,
        FlxColor.BLACK
    );

    hudRating.borderSize = 2;
    hudRating.borderQuality = 2;

    hudRating.scrollFactor.set();
    hudRating.cameras = [ps.camHUD];

    add(hudRating);
}

function update(elapsed:Float)
{
    var ps = PlayState.instance;
    if (ps == null) return;

    // ❌ No aplicar en esta canción
    if (isDisabledSong()) return;
    var scoreStr = "Score: " + ps.songScore;
    var missesStr = "Combo Breaks: " + ps.misses;

    var baseText:String;
    var ratingStr:String = "";

    if(ps.accuracy >= 0)
    {
        var accPercent = Math.round(ps.accuracy * 10000) / 100.0;
        var accStr = "Accuracy: " + accPercent + "%";

        ratingStr = getRating(ps.accuracy);

        baseText = scoreStr + " | " + missesStr + " | " + accStr + " | ";

        hudRating.visible = true;
    }
    else
    {
        // Antes de tocar notas
        baseText = scoreStr + " | " + missesStr;

        hudRating.visible = false;
    }

    hudBase.text = baseText;
    hudRating.text = ratingStr;

    hudRating.color = getRatingColor(ratingStr);

    var totalWidth = hudBase.width + hudRating.width;
    var startX = (FlxG.width - totalWidth) / 2;

    hudBase.x = startX;
    hudRating.x = startX + hudBase.width;
}
function getRatingColor(r:String):Int
{
    switch(r)
    {
        case "S++": return FlxColor.fromRGB(160, 0, 255);
        case "S+":  return FlxColor.fromRGB(255, 0, 200);
        case "S":   return FlxColor.fromRGB(210, 0, 255);

        case "A": return FlxColor.fromRGB(80, 140, 255);
        case "B": return FlxColor.fromRGB(60, 110, 255);
        case "C": return FlxColor.fromRGB(40, 80, 220);
        case "D": return FlxColor.fromRGB(25, 60, 180);

        case "E": return FlxColor.fromRGB(100, 100, 100);

        default: return FlxColor.WHITE;
    }
}

function getRating(acc:Float):String
{
    if(acc >= 1) return "S++";
    else if(acc >= 0.98) return "S+";
    else if(acc >= 0.95) return "S";
    else if(acc >= 0.90) return "A";
    else if(acc >= 0.85) return "B";
    else if(acc >= 0.80) return "C";
    else if(acc >= 0.70) return "D";
    else return "E";
}
function onEvent(e)
{
    if(e.event.name == "Toggle Custom HUD")
    {
        var ps = PlayState.instance;
        if(ps == null) return;

        var params:Array = e.event.params;

        // bool
        hudVisible = params[0];

        // steps
        var steps:Float = params[1];

        // steps -> segundos
        var duration:Float = (Conductor.stepCrochet / 1000) * steps;

        var targetAlpha:Float = hudVisible ? 1 : 0;

        if(hudVisible)
        {
            hudBase.visible = true;
            hudRating.visible = true;

            ps.healthBar.visible = true;
            ps.healthBarBG.visible = true;

            ps.iconP1.visible = true;
            ps.iconP2.visible = true;
        }

        FlxTween.tween(hudBase, {alpha: targetAlpha}, duration, {
            ease: FlxEase.quadOut
        });

        FlxTween.tween(hudRating, {alpha: targetAlpha}, duration, {
            ease: FlxEase.quadOut
        });

        FlxTween.tween(ps.healthBar, {alpha: targetAlpha}, duration, {
            ease: FlxEase.quadOut
        });

        FlxTween.tween(ps.healthBarBG, {alpha: targetAlpha}, duration, {
            ease: FlxEase.quadOut
        });

        FlxTween.tween(ps.iconP1, {alpha: targetAlpha}, duration, {
            ease: FlxEase.quadOut
        });

        FlxTween.tween(ps.iconP2, {alpha: targetAlpha}, duration, {
            ease: FlxEase.quadOut,
            onComplete: function(twn)
            {
                if(!hudVisible)
                {
                    hudBase.visible = false;
                    hudRating.visible = false;

                    ps.healthBar.visible = false;
                    ps.healthBarBG.visible = false;

                    ps.iconP1.visible = false;
                    ps.iconP2.visible = false;
                }
            }
        });
    }
}