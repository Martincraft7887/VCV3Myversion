import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

var uno:FlxSprite;
var dos:FlxSprite;
var tres:FlxSprite;
var cuatro:FlxSprite;

var centerX:Float;
var centerY:Float;

function create()
{
    centerX = FlxG.width / 2;
    centerY = FlxG.height / 2;

    uno = makeNum("uno-god");
    dos = makeNum("dos-god");
    tres = makeNum("tres-god");
    cuatro = makeNum("cuatro-god");

    add(uno);
    add(dos);
    add(tres);
    add(cuatro);

    resetPositions();
}

function makeNum(name:String):FlxSprite
{
    var spr = new FlxSprite();
    spr.loadGraphic(Paths.image(name));

    spr.cameras = [camHUD];

    spr.scale.set(0.65, 0.65); 
    spr.updateHitbox();

    spr.visible = false;

    return spr;
}

function resetPositions()
{
    uno.x = centerX - uno.width/2;
    uno.y = FlxG.height + 200;

    dos.x = -dos.width - 200;
    dos.y = centerY - dos.height/2;

    tres.x = centerX - tres.width/2;
    tres.y = -tres.height - 200;

    cuatro.x = FlxG.width + cuatro.width + 200;
    cuatro.y = centerY - cuatro.height/2;
}

function stepHit()
{
    if(curStep == 352) showNum(uno, "down");
    //if(curStep == 708) showNum(dos, "left");
    //if(curStep == 712) showNum(tres, "up");
    //if(curStep == 716) showNum(cuatro, "right");
}

function showNum(spr:FlxSprite, dir:String)
{
    spr.visible = true;

    var targetX = centerX - spr.width/2;
    var targetY = centerY - spr.height/2;

    FlxTween.tween(spr, {x:targetX, y:targetY}, 0.22, {
        ease:FlxEase.quadOut,
        onComplete:function(t)
        {
            var exitX = spr.x;
            var exitY = spr.y;

            switch(dir)
            {
                case "down": exitY = FlxG.height + 200;
                case "left": exitX = -spr.width - 200;
                case "up": exitY = -spr.height - 200;
                case "right": exitX = FlxG.width + spr.width + 200;
            }

            FlxTween.tween(spr, {x:exitX, y:exitY}, 0.22, {
                startDelay:0.12,
                ease:FlxEase.quadIn,
                onComplete:function(t2)
                {
                    spr.visible = false;
                }
            });
        }
    });
}