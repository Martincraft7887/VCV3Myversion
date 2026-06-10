import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.backend.FunkinText;
import funkin.backend.utils.Paths;

var afkTime:Float = 0;
var hamsterLines:FlxTypedGroup<FlxSprite>;
var spawned:Bool = false;

var rightHamsters:Array<FlxSprite> = [];
var topHamsters:Array<FlxSprite> = [];

var cycleRunning:Bool = false;

// CONFIG INTERSECCIÓN
var intersectionX:Float = 520;
var intersectionY:Float = 360;

var horizontalLanes:Int = 5; // filas de derecha a izquierda
var verticalLanes:Int = 5;   // filas de arriba hacia abajo

var hamstersPerHorizontalLane:Int = 7;
var hamstersPerVerticalLane:Int = 6;

var laneSpacing:Float = 70;
var hamsterSpacing:Float = 115;

var minPassTime:Float = 15;
var maxPassTime:Float = 30;

var quickOptionName:String = "Quick Options";
var quickMenuOpen:Bool = false;
var quickSelected:Int = 0;

var quickBG:FlxSprite = null;
var quickTitle:FunkinText = null;
var quickNotice:FunkinText = null;
var quickTexts:FlxTypedGroup<FunkinText> = null;

var quickItems:Array<Dynamic> = [
    {label: "Botplay", save: "voiidBotplay", fallback: true, needsRestart: false},
    {label: "No mechanics", save: "voiidNoMechanics", fallback: false, needsRestart: true},
    {label: "Modcharts", save: "voiidModcharts", fallback: true, needsRestart: true},
    {label: "No death", save: "voiidNoDeath", fallback: false, needsRestart: false}
];

function saveBool(name:String, fallback:Bool):Bool
{
    var value = Reflect.field(FlxG.save.data, name);

    if (value == null)
    {
        Reflect.setField(FlxG.save.data, name, fallback);
        FlxG.save.flush();
        return fallback;
    }

    return value == true;
}

function setSaveBool(name:String, value:Bool)
{
    Reflect.setField(FlxG.save.data, name, value);
    FlxG.save.flush();
}

function quickItemLabel(index:Int):String
{
    var item = quickItems[index];
    return item.label + ": " + (saveBool(item.save, item.fallback) ? "ON" : "OFF");
}

function create(event)
{
    if (!event.options.contains(quickOptionName))
        event.options.insert(Std.int(Math.max(1, event.options.length - 1)), quickOptionName);
}

function postCreate()
{
    hamsterLines = new FlxTypedGroup<FlxSprite>();
    add(hamsterLines);
    refreshQuickOptionLabels();
}

function refreshQuickOptionLabels()
{
    try
    {
        if (grpMenuShit == null || menuItems == null) return;

        for (i in 0...menuItems.length)
        {
            var option = menuItems[i];
            if (option != quickOptionName) continue;

            var item = grpMenuShit.members[i];
            if (item != null) item.text = "Quick Options";
        }
    }
    catch(e:Dynamic) {}
}

function openQuickOptions()
{
    if (quickMenuOpen) return;

    quickMenuOpen = true;
    quickSelected = 0;

    quickBG = new FlxSprite(0, 0).makeSolid(FlxG.width, FlxG.height, 0xEE000000);
    quickBG.scrollFactor.set();
    add(quickBG);

    quickTitle = new FunkinText(0, 120, FlxG.width, "Quick Options", 36, true);
    quickTitle.alignment = "center";
    quickTitle.scrollFactor.set();
    add(quickTitle);

    quickNotice = new FunkinText(0, 470, FlxG.width, "", 20, true);
    quickNotice.alignment = "center";
    quickNotice.scrollFactor.set();
    quickNotice.alpha = 0;
    add(quickNotice);

    quickTexts = new FlxTypedGroup<FunkinText>();
    add(quickTexts);

    for (i in 0...quickItems.length)
    {
        var txt = new FunkinText(0, 230 + (i * 62), FlxG.width, "", 28, true);
        txt.alignment = "center";
        txt.scrollFactor.set();
        quickTexts.add(txt);
    }

    refreshQuickMenu();
}

function closeQuickOptions()
{
    quickMenuOpen = false;

    if (quickBG != null) { remove(quickBG); quickBG.destroy(); quickBG = null; }
    if (quickTitle != null) { remove(quickTitle); quickTitle.destroy(); quickTitle = null; }

    if (quickNotice != null)
    {
        FlxTween.cancelTweensOf(quickNotice);
        remove(quickNotice);
        quickNotice.destroy();
        quickNotice = null;
    }

    if (quickTexts != null)
    {
        remove(quickTexts);
        quickTexts.destroy();
        quickTexts = null;
    }
}

function refreshQuickMenu()
{
    if (quickTexts == null) return;

    for (i in 0...quickTexts.members.length)
    {
        var txt = quickTexts.members[i];
        if (txt == null) continue;

        txt.text = (i == quickSelected ? "> " : "  ") + quickItemLabel(i) + (i == quickSelected ? " <" : "  ");
        txt.alpha = i == quickSelected ? 1 : 0.55;
    }
}

function toggleQuickSelected()
{
    var item = quickItems[quickSelected];

    setSaveBool(item.save, !saveBool(item.save, item.fallback));
    refreshQuickMenu();

    if (item.needsRestart == true)
        showQuickNotice("Restart song to apply changes");
}

function showQuickNotice(text:String)
{
    if (quickNotice == null) return;

    FlxTween.cancelTweensOf(quickNotice);

    quickNotice.text = text;
    quickNotice.alpha = 1;

    FlxTween.tween(quickNotice, {alpha: 0}, 0.35, {
        startDelay: 2,
        ease: FlxEase.quadIn
    });
}

function onSelectOption(event)
{
    if (quickMenuOpen)
    {
        event.cancel();
        return;
    }

    if (event.name == quickOptionName)
    {
        event.cancel();
        openQuickOptions();
    }
}

function onChangeItem(event)
{
    if (quickMenuOpen)
        event.cancel();
}

function update(elapsed:Float)
{
    if (quickMenuOpen)
    {
        if (FlxG.keys.justPressed.UP)
        {
            quickSelected = FlxMath.wrap(quickSelected - 1, 0, quickItems.length - 1);
            refreshQuickMenu();
        }

        if (FlxG.keys.justPressed.DOWN)
        {
            quickSelected = FlxMath.wrap(quickSelected + 1, 0, quickItems.length - 1);
            refreshQuickMenu();
        }

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
            toggleQuickSelected();

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
            closeQuickOptions();

        return;
    }

    afkTime += elapsed;

    if (afkTime >= 30 && !spawned)
    {
        spawned = true;
        createHamsterIntersection();
    }

    if (FlxG.keys.justPressed.ANY)
    {
        afkTime = 0;

        if (spawned)
        {
            spawned = false;
            cycleRunning = false;

            for (spr in hamsterLines.members)
            {
                if (spr != null)
                {
                    FlxTween.cancelTweensOf(spr);
                    spr.destroy();
                }
            }

            hamsterLines.clear();
            rightHamsters = [];
            topHamsters = [];
        }
    }
}

function makeHamster():FlxSprite
{
    var hamster = new FlxSprite();

    hamster.frames = Paths.getSparrowAtlas("hampster/hampster");
    hamster.animation.addByPrefix("Hampster", "Hampster", 24, true);
    hamster.animation.play("Hampster");

    hamster.antialiasing = true;

    hamster.setGraphicSize(150, 150);
    hamster.updateHitbox();

    hamster.scrollFactor.set();

    return hamster;
}

function getRandomMoveEase():Dynamic
{
    return switch(FlxG.random.int(0, 11))
    {
        case 0: FlxEase.linear;
        case 1: FlxEase.sineInOut;
        case 2: FlxEase.quadInOut;
        case 3: FlxEase.cubeInOut;
        case 4: FlxEase.quartInOut;
        case 5: FlxEase.quintInOut;
        case 6: FlxEase.backOut;
        case 7: FlxEase.elasticOut;
        case 8: FlxEase.bounceOut;
        case 9: FlxEase.expoOut;
        case 10: FlxEase.circInOut;
        default: FlxEase.sineOut;
    }
}

function laneOffset(index:Int, total:Int):Float
{
    return (index - ((total - 1) / 2)) * laneSpacing;
}

function createHamsterIntersection()
{
    rightHamsters = [];
    topHamsters = [];

    for (lane in 0...horizontalLanes)
    {
        for (i in 0...hamstersPerHorizontalLane)
        {
            var h = makeHamster();

            h.x = FlxG.width + 180 + (i * hamsterSpacing) + FlxG.random.int(-20, 60);
            h.y = intersectionY + laneOffset(lane, horizontalLanes) + FlxG.random.float(-10, 10);

            hamsterLines.add(h);
            rightHamsters.push(h);
        }
    }

    for (lane in 0...verticalLanes)
    {
        for (i in 0...hamstersPerVerticalLane)
        {
            var h = makeHamster();

            h.x = intersectionX + laneOffset(lane, verticalLanes) + FlxG.random.float(-10, 10);
            h.y = -200 - (i * hamsterSpacing) - FlxG.random.int(0, 180);

            hamsterLines.add(h);
            topHamsters.push(h);
        }
    }

    cycleRunning = true;
    startIntersectionCycle();
}

function startIntersectionCycle()
{
    if (!spawned || !cycleRunning) return;

    resetIntersectionPositions();
    bunchRightHamsters();

    var topPassTime = FlxG.random.float(minPassTime, maxPassTime);
    var rightPassTime = FlxG.random.float(minPassTime, maxPassTime);

    new FlxTimer().start(1.0, function(tmr:FlxTimer)
    {
        if (!spawned || !cycleRunning) return;

        passTopHamsters(topPassTime);

        new FlxTimer().start(topPassTime + FlxG.random.float(0.5, 1.5), function(tmr2:FlxTimer)
        {
            if (!spawned || !cycleRunning) return;

            passRightHamsters(rightPassTime);

            new FlxTimer().start(rightPassTime + FlxG.random.float(0.8, 2.0), function(tmr3:FlxTimer)
            {
                if (!spawned || !cycleRunning) return;
                startIntersectionCycle();
            });
        });
    });
}

function bunchRightHamsters()
{
    var perLane = hamstersPerHorizontalLane;

    for (i in 0...rightHamsters.length)
    {
        var h = rightHamsters[i];
        if (h == null) continue;

        FlxTween.cancelTweensOf(h);

        var lane = Std.int(i / perLane);
        var pos = i % perLane;

        var stopX = intersectionX + 220 + (pos * 80) + FlxG.random.float(-18, 18);
        var stopY = intersectionY + laneOffset(lane, horizontalLanes) + FlxG.random.float(-12, 12);

        FlxTween.tween(h, {
            x: stopX,
            y: stopY
        }, FlxG.random.float(0.8, 2.2), {
            ease: FlxEase.backOut,
            startDelay: FlxG.random.float(0, 0.65)
        });
    }
}

function passTopHamsters(duration:Float)
{
    var perLane = hamstersPerVerticalLane;

    for (i in 0...topHamsters.length)
    {
        var h = topHamsters[i];
        if (h == null) continue;

        FlxTween.cancelTweensOf(h);

        var lane = Std.int(i / perLane);
        var pos = i % perLane;

        h.x = intersectionX + laneOffset(lane, verticalLanes) + FlxG.random.float(-12, 12);
        h.y = -220 - (pos * hamsterSpacing) - FlxG.random.int(0, 180);

        FlxTween.tween(h, {
            y: FlxG.height + 220 + FlxG.random.int(0, 180)
        }, FlxG.random.float(duration * 0.75, duration * 1.15), {
            ease: getRandomMoveEase(),
            startDelay: FlxG.random.float(0, duration * 0.35)
        });
    }
}

function passRightHamsters(duration:Float)
{
    var perLane = hamstersPerHorizontalLane;

    for (i in 0...rightHamsters.length)
    {
        var h = rightHamsters[i];
        if (h == null) continue;

        FlxTween.cancelTweensOf(h);

        var lane = Std.int(i / perLane);
        var pos = i % perLane;

        h.x = intersectionX + 220 + (pos * 80) + FlxG.random.float(-18, 18);
        h.y = intersectionY + laneOffset(lane, horizontalLanes) + FlxG.random.float(-15, 15);

        FlxTween.tween(h, {
            x: -260 - FlxG.random.int(0, 300)
        }, FlxG.random.float(duration * 0.75, duration * 1.15), {
            ease: getRandomMoveEase(),
            startDelay: FlxG.random.float(0, duration * 0.35)
        });
    }
}

function resetIntersectionPositions()
{
    for (i in 0...rightHamsters.length)
    {
        var h = rightHamsters[i];
        if (h == null) continue;

        FlxTween.cancelTweensOf(h);

        var lane = Std.int(i / hamstersPerHorizontalLane);
        var pos = i % hamstersPerHorizontalLane;

        h.x = FlxG.width + 180 + (pos * hamsterSpacing) + FlxG.random.int(0, 250);
        h.y = intersectionY + laneOffset(lane, horizontalLanes) + FlxG.random.float(-10, 10);
        h.alpha = 1;
    }

    for (i in 0...topHamsters.length)
    {
        var h = topHamsters[i];
        if (h == null) continue;

        FlxTween.cancelTweensOf(h);

        var lane = Std.int(i / hamstersPerVerticalLane);
        var pos = i % hamstersPerVerticalLane;

        h.x = intersectionX + laneOffset(lane, verticalLanes) + FlxG.random.float(-10, 10);
        h.y = -220 - (pos * hamsterSpacing) - FlxG.random.int(0, 250);
        h.alpha = 1;
    }
}