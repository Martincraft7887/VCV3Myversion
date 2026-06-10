import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

function onEvent(e)
{
    if (e.event.name == "ToggleHUD")
    {
        var params:Array = e.event.params;

        var visible:Bool = params[0];
        var time:Float = params[1];
        var instant:Bool = params[2];

        var targetAlpha:Float = visible ? 1 : 0;

        FlxTween.cancelTweensOf(camHUD);

        if(instant)
        {
            camHUD.alpha = targetAlpha;
        }
        else
        {
            FlxTween.tween(camHUD, {alpha: targetAlpha}, time, {ease: FlxEase.smoothStepOut});
        }
    }
}
