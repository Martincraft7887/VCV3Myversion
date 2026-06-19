import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

var extraChar:Character;
var originalX:Float;

function postCreate()
{
    var playerLine = strumLines.members[1];

    if (playerLine.characters.length > 1)
    {
        extraChar = playerLine.characters[1];
        originalX = extraChar.x;

        // Invisible durante toda la canción por defecto
        extraChar.alpha = 0;
    }
}

function stepHit(curStep:Int)
{
    if (extraChar == null) return;

    switch (curStep)
    {
        // Mostrar y desplazar
        case 831, 1600:

            extraChar.alpha = 1;

            FlxTween.cancelTweensOf(extraChar);

            FlxTween.tween(extraChar, {
                x: originalX + 300
            }, Conductor.stepCrochet * 8 / 1000, {
                ease: FlxEase.quadOut
            });

        // Regresar y ocultar
        case 859, 1628:

            FlxTween.cancelTweensOf(extraChar);

            FlxTween.tween(extraChar, {
                x: originalX
            }, Conductor.stepCrochet * 8 / 1000, {
                ease: FlxEase.quadOut,
                onComplete: function(_)
                {
                    extraChar.alpha = 0;
                }
            });
    }
}