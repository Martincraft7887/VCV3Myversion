import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import VCSongText;

// ==========================
// VARIABLES
// ==========================
var lyric1;
var lyric2;
var lyric3;
var lyric4;
var lyric5;
var lyric6;
var lyric7;
var lyric8;

var centerX:Float;
var centerY:Float;

// ==========================
// INIT
// ==========================
function postCreate()
{
    centerX = FlxG.width / 2;
    centerY = FlxG.height / 2;

    // BOW (rosa)
    lyric1 = makeCoolText("BOW", 128, 16, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#ff9369",
        "midBorderBot": "#dd0000",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');

    // BEFORE ME (azul)
    lyric2 = makeCoolText("BEFORE ME", 128, 16, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#ff9369",
        "midBorderBot": "#dd0000",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');

    // MORTALS (rojo)
    lyric3 = makeCoolText("MORTALS", 128, 16, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#ff9369",
        "midBorderBot": "#dd0000",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');

    lyric4 = makeCoolText("UNTAPPED", 128, 16, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#ff9369",
        "midBorderBot": "#dd0000",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');
    lyric5 = makeCoolText("POWERS", 128, 16, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#ff9369",
        "midBorderBot": "#dd0000",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');
    lyric6 = makeCoolText("I MADE IT", 128, 16, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#ff9369",
        "midBorderBot": "#dd0000",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');
    lyric7 = makeCoolText("Can you even", 50, 10, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#c170b9",
        "midBorderBot": "#c23a86",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');
    lyric8 = makeCoolText("KEEP UP WITH THIS!?", 50, 10, '{
        "songFont": "dumbnerd.ttf",
        "outerBorderTop": "#000000",
        "outerBorderBot": "#000000",
        "midBorderTop": "#c170b9",
        "midBorderBot": "#c23a86",
        "innerBorderTop": "#363636",
        "innerBorderBot": "#000000"
    }');
    
}

// ==========================
// CREAR TEXTO (FIX JSON)
// ==========================
function makeCoolText(text:String, size:Float, spacing:Float, dataString:String)
{
    var data = Json.parse(dataString);

    var t = createSongText(text, size, spacing, data);

    t.cameras = [camOther];
    t.visible = false;

    add(t);
    return t;
}

// ==========================
// MOSTRAR TEXTO
// ==========================
function showText(t, enterDir:String, exitDir:String, durationSteps:Int, xOffset:Float, yOffset:Float)
{
    t.visible = true;

    var targetX = centerX - t.width/2 + xOffset;
    var targetY = centerY - t.height/2 + yOffset;

    // ==========================
    // POSICIÓN INICIAL (ENTRADA)
    // ==========================
    switch(enterDir)
    {
        case "down":
            t.x = targetX;
            t.y = FlxG.height + 200;

        case "up":
            t.x = targetX;
            t.y = -t.height - 200;

        case "left":
            t.x = -t.width - 200;
            t.y = targetY;

        case "right":
            t.x = FlxG.width + t.width + 200;
            t.y = targetY;
    }

    // ==========================
    // ENTRADA
    // ==========================
    FlxTween.tween(t, {x:targetX, y:targetY}, 0.25, {
        ease:FlxEase.quadOut,
        onComplete:function(_)
        {
            var waitTime = (durationSteps * Conductor.stepCrochet) / 1000;

            var exitX = targetX;
            var exitY = targetY;

            // ==========================
            // DIRECCIÓN DE SALIDA
            // ==========================
            switch(exitDir)
            {
                case "down": exitY = FlxG.height + 200;
                case "up": exitY = -t.height - 200;
                case "left": exitX = -t.width - 200;
                case "right": exitX = FlxG.width + t.width + 200;
            }

            // ==========================
            // SALIDA
            // ==========================
            FlxTween.tween(t, {x:exitX, y:exitY}, 0.25, {
                startDelay:waitTime,
                ease:FlxEase.quadIn,
                onComplete:function(_) {
                    t.visible = false;
                }
            });
        }
    });
}

// ==========================
// STEPS
// ==========================
// showText(texto, entrada, salida, duracion, X, Y);
function stepHit()
{
    if(curStep == 832)
    {
        showText(lyric1, "down", "left", 20, 0, -120);
        showText(lyric2, "up", "right", 20, 0, 0);
        showText(lyric3, "down", "left", 20, 0, 120);
    }

    if(curStep == 854)
    {
        showText(lyric4, "up", "right", 5, 0, -60);
        showText(lyric5, "down", "left", 5, 0, 60);
    }
    if(curStep == 1017)
        showText(lyric6, "down", "up", 1, 0, 0);
    if(curStep == 1808)
        showText(lyric7, "down", "down", 6, 0, 200);
    if(curStep == 1816)
        showText(lyric8, "down", "down", 5, 0, 200);
    if(curStep == 2393)
        showText(lyric6, "down", "up", 1, 0, 0);

}