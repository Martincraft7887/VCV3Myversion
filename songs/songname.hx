import VCSongText;
import flixel.util.FlxTimer;

// ==========================
// VARIABLES
// ==========================
var t1;
var logo;
var showedPopup = false;
var logoOffsetX:Float = 0;
var logoOffsetY:Float = -100;

var textOffsetX:Float = 0;
var textOffsetY:Float = 200;
var centerX:Float;
var centerY:Float;

var logoTweenOffsetX:Float = 0;
var logoTweenOffsetY:Float = 0;

var textTweenOffsetX:Float = 0;
var textTweenOffsetY:Float = 0;
var centerFollowers:Array<Dynamic> = [];
var logoHasIdleAnim:Bool = false;
var logoBaseScaleX:Float = 1;
var logoBaseScaleY:Float = 1;
var logoBumpTween:FlxTween = null;
var logoFromJson:Bool = false;

var centerFollowLerp:Float = 0.12;
var logoScale:Float = 0.8;
var customTextOffsetY:Float = 200;

var tLeft;
var tRight;
var useSplitText:Bool = false;
var splitTextAt:Int = -1;
var splitTextGap:Float = 0;
var splitLeftData = null;
var splitRightData = null;



var defaultSong = '
{
    "songFont": "dumbnerd.ttf",
    "songFontSize": 128,

    "outerBorderTop": "#000000",
    "outerBorderBot": "#000000",

    "midBorderTop": "#c735ff",
    "midBorderBot": "#6414ea",

    "innerBorderTop": "#3f3f3f",
    "innerBorderBot": "#121617"
}';

var songData = null;

// ==========================
// TABLA DE LOGOS
// ==========================
var logoTable = [

    // DEFAULT
    {
        songs: [    // Story mode
    "light it up",
    "ruckus",
    "target practice",
    "burnout",
    "sporting",
    "boxing match",
    "sport swinging",
    "boxing gladiators",
    "flaming glove",
    "punch and gun",
    "fisticuffs",
    "blastout",
    "immortal",
    "king hit",
    "tko",
    "mat",
    "banger",
    "edgy",
    "venom",
    "disadvantage",
    "champion",
    "recovery",
    "last combat",
    "greedoom",
    "purgatory",
    "krakatoa",
    "showdown",

    // Collabs
    "alter ego",
    "interregnum",
    "insano",
    "ballin",
    "sweet dreams",
    "sweet dreams ii",

    // Extras
    "flaming glove iii",
    "knocked",
    "edgelord",
    "rejected",
    "wastelands",
    "toxic",
    "veteran",
    "bombastic",
    "mattpurgation",
    "exodus",
    "take it",
    "cleverness",
    "tempo slayer",
    "total bravery",
    "ignis gladius",
    "king hit wawa",
    "warm up",
    "fishycuffs",
    "average voiid song",
    "penismatt",
    "wii remote",
    "damnale",

    // VIP remixes
    "boxing match vip",
    "immortal vip",
    "king hit vip",
    "tko vip",
    "veteran vip",
    "edgy vip",
    "burnout vip",
    "alter ego vip",
    "target practice vip",
    "rejected vip"],
        logo: "Logo"
    },

    // SXM
    {
        songs: [
            "power link",
            "revenge",
            "final destination",
            "final destination god",
            "shooting power",
            "thunderstorm",
            "disassembler",
            "cosmic memories",
            "new horizon",
            "galactic storm",
            "multiversal slash",
            "glowing collision",
            "radical showdown",
            "defamation of reality",
            "super saiyan",
            "haven",
            "rage",
            "intervention",
            "final destination old"
        ],

        logo: "LogoSXM"
    }
];

// ==========================
// OBTENER LOGO
// ==========================
function logoExists(logoName:String):Bool
{
    return Assets.exists(Paths.image("logos/" + logoName));
}

function getJsonFloat(field:String, fallback:Float):Float
{
    if (songData == null || Reflect.field(songData, field) == null)
        return fallback;

    var value = Std.parseFloat(Std.string(Reflect.field(songData, field)));
    return Math.isNaN(value) ? fallback : value;
}

function getJsonBool(field:String, fallback:Bool):Bool
{
    if (songData == null || Reflect.field(songData, field) == null)
        return fallback;

    var v = Std.string(Reflect.field(songData, field)).toLowerCase();
    return v == "true" || v == "1";
}

function getJsonInt(field:String, fallback:Int):Int
{
    if (songData == null || Reflect.field(songData, field) == null)
        return fallback;

    var value = Std.parseInt(Std.string(Reflect.field(songData, field)));
    return value == null ? fallback : value;
}

function cloneData(data:Dynamic):Dynamic
{
    return Json.parse(Json.stringify(data));
}

function applySplitColors(data:Dynamic, prefix:String):Dynamic
{
    var d = cloneData(data);

    if (Reflect.field(data, prefix + "OuterBorderTop") != null)
        d.outerBorderTop = Reflect.field(data, prefix + "OuterBorderTop");
    if (Reflect.field(data, prefix + "OuterBorderBot") != null)
        d.outerBorderBot = Reflect.field(data, prefix + "OuterBorderBot");

    if (Reflect.field(data, prefix + "MidBorderTop") != null)
        d.midBorderTop = Reflect.field(data, prefix + "MidBorderTop");
    if (Reflect.field(data, prefix + "MidBorderBot") != null)
        d.midBorderBot = Reflect.field(data, prefix + "MidBorderBot");

    if (Reflect.field(data, prefix + "InnerBorderTop") != null)
        d.innerBorderTop = Reflect.field(data, prefix + "InnerBorderTop");
    if (Reflect.field(data, prefix + "InnerBorderBot") != null)
        d.innerBorderBot = Reflect.field(data, prefix + "InnerBorderBot");

    return d;
}

function getLogoName()
{
    logoFromJson = false;

    if (songData != null && songData.logo != null && Std.string(songData.logo) != "")
    {
        var jsonLogo = Std.string(songData.logo);
        if (logoExists(jsonLogo))
        {
            logoFromJson = true;
            return jsonLogo;
        }
    }

    var curSongName = PlayState.SONG.meta.name.toLowerCase();

    for (entry in logoTable)
    {
        for (song in entry.songs)
        {
            if (curSongName == song.toLowerCase())
            {
                if (logoExists(entry.logo))
                    return entry.logo;
                break;
            }
        }
    }

    return "Logo";
}

function getCustomLogoYOffset():Float
{
    if (!logoFromJson || songData == null || songData.logoOffsetY == null)
        return 0;
    var offset = Std.parseFloat(Std.string(songData.logoOffsetY));
    return Math.isNaN(offset) ? 0 : offset;
}

// ==========================
// INIT
// ==========================
function postCreate()
{
    centerX = FlxG.width / 2;
    centerY = FlxG.height / 2;

    // ==========================
    // JSON
    // ==========================
    if (Assets.exists("songs/" + PlayState.SONG.meta.name + "/credits.json"))
    {
        songData = Json.parse(
            Assets.getText("songs/" + PlayState.SONG.meta.name + "/credits.json")
        );
    }
    else
    {
        songData = Json.parse(defaultSong);
    }
    logoScale = getJsonFloat("logoScale", 0.8);
    customTextOffsetY = getJsonFloat("textOffsetY", 200);

    // ==========================
    // TEXTO
    // ==========================
    useSplitText = getJsonBool("splitText", false);
    splitTextAt = getJsonInt("splitTextAt", -1);
    splitTextGap = getJsonFloat("splitTextGap", 0);

    if (useSplitText)
    {
        var fullText = PlayState.SONG.meta.displayName;

        if (songData.overrideName != null)
            fullText = Std.string(songData.overrideName);

        if (splitTextAt < 0)
            splitTextAt = Math.floor(fullText.length / 2);

        var leftText = fullText.substr(0, splitTextAt);
        var rightText = fullText.substr(splitTextAt);

        splitLeftData = applySplitColors(songData, "left");
        splitRightData = applySplitColors(songData, "right");

        tLeft = makeCoolText(
            leftText,
            songData.songFontSize,
            12,
            Json.stringify(splitLeftData)
        );

        tRight = makeCoolText(
            rightText,
            songData.songFontSize,
            12,
            Json.stringify(splitRightData)
        );
    }
    else
    {
        t1 = makeCoolText(
            PlayState.SONG.meta.displayName,
            songData.songFontSize,
            12,
            Json.stringify(songData)
        );
    }
    // ==========================
    // LOGO ANIMADO
    // ==========================
    var logoName = getLogoName();

    logo = new FlxSprite();

    logo.frames = Paths.getFrames("logos/" + logoName);

    // prefijo de animación
    logo.animation.addByPrefix(
        "idle",
        "idle",
        24,
        false // <- sin loop
    );

    logoHasIdleAnim = logo.animation.exists("idle");
    if (logoHasIdleAnim)
        logo.animation.play("idle");

    logo.setGraphicSize(Std.int(logo.width * logoScale));
    logo.updateHitbox();
    logoBaseScaleX = logo.scale.x;
    logoBaseScaleY = logo.scale.y;

    logo.cameras = [camGame];
    logo.scrollFactor.set(1, 1);
    logo.visible = false;

    add(logo);
}

// ==========================
// CREAR TEXTO
// ==========================
function makeCoolText(text:String, size:Float, spacing:Float, dataString:String)
{
    var data = Json.parse(dataString);

    var t = createSongText(text, size, spacing, data);

    t.cameras = [camGame];
    t.scrollFactor.set(1, 1);
    t.visible = false;

    add(t);

    return t;
}


function showSplitText(
    leftObj:FlxSprite,
    rightObj:FlxSprite,
    enterDir:String,
    exitDir:String,
    durationMS:Int,
    xOffset:Float,
    yOffset:Float
)
{
    leftObj.visible = true;
    rightObj.visible = true;

    stopFollowingCenter(leftObj);
    stopFollowingCenter(rightObj);

    var totalWidth = leftObj.width + rightObj.width + splitTextGap;
    var maxHeight = Math.max(leftObj.height, rightObj.height);

    var targetX = camGame.scroll.x + (camGame.width - totalWidth) / 2 + xOffset;
    var targetY = camGame.scroll.y + (camGame.height - maxHeight) / 2 + yOffset;

    var leftTargetX = targetX;
    var rightTargetX = targetX + leftObj.width + splitTextGap;

    var leftTargetY = targetY;
    var rightTargetY = targetY;

    var enterX = targetX;
    var enterY = targetY;

    switch(enterDir)
    {
        case "down":
            enterY = camGame.scroll.y + camGame.height + 200;
        case "up":
            enterY = camGame.scroll.y - maxHeight - 200;
        case "left":
            enterX = camGame.scroll.x - totalWidth - 200;
        case "right":
            enterX = camGame.scroll.x + camGame.width + totalWidth + 200;
    }

    leftObj.x = enterX;
    leftObj.y = enterY;

    rightObj.x = enterX + leftObj.width + splitTextGap;
    rightObj.y = enterY;

    FlxTween.tween(leftObj, {x: leftTargetX, y: leftTargetY}, 0.8, {
        ease: FlxEase.expoOut
    });

    FlxTween.tween(rightObj, {x: rightTargetX, y: rightTargetY}, 0.8, {
        ease: FlxEase.expoOut,

        onComplete: function(_)
        {
            new FlxTimer().start(durationMS / 1000, function(_)
            {
                var exitX = targetX;
                var exitY = targetY;

                switch(exitDir)
                {
                    case "down":
                        exitY = camGame.scroll.y + camGame.height + 200;
                    case "up":
                        exitY = camGame.scroll.y - maxHeight - 200;
                    case "left":
                        exitX = camGame.scroll.x - totalWidth - 200;
                    case "right":
                        exitX = camGame.scroll.x + camGame.width + totalWidth + 200;
                }

                FlxTween.tween(leftObj, {x: exitX, y: exitY}, 0.4, {
                    ease: FlxEase.expoIn,
                    onComplete: function(_) {
                        leftObj.visible = false;
                    }
                });

                FlxTween.tween(rightObj, {x: exitX + leftObj.width + splitTextGap, y: exitY}, 0.4, {
                    ease: FlxEase.expoIn,
                    onComplete: function(_) {
                        rightObj.visible = false;
                    }
                });
            });
        }
    });
}
// ==========================
// ENTRADA
// ==========================
function setupEnter(obj:FlxSprite, enterDir:String, targetX:Float, targetY:Float)
{
    switch(enterDir)
    {
        case "down":
            obj.x = targetX;
            obj.y = camGame.scroll.y + camGame.height + 200;

        case "up":
            obj.x = targetX;
            obj.y = camGame.scroll.y - obj.height - 200;

        case "left":
            obj.x = camGame.scroll.x - obj.width - 200;
            obj.y = targetY;

        case "right":
            obj.x = camGame.scroll.x + camGame.width + obj.width + 200;
            obj.y = targetY;
    }
}

// ==========================
// SALIDA
// ==========================
function getExitPos(obj:FlxSprite, exitDir:String, targetX:Float, targetY:Float)
{
    var pos = {
        x: targetX,
        y: targetY
    };

    switch(exitDir)
    {
        case "down":
            pos.y = camGame.scroll.y + camGame.height + 200;

        case "up":
            pos.y = camGame.scroll.y - obj.height - 200;

        case "left":
            pos.x = camGame.scroll.x - obj.width - 200;

        case "right":
            pos.x = camGame.scroll.x + camGame.width + obj.width + 200;
    }

    return pos;
}

function getCenteredPos(obj:FlxSprite, xOffset:Float, yOffset:Float)
{
    return {
        x: camGame.scroll.x + (camGame.width - obj.width) / 2 + xOffset,
        y: camGame.scroll.y + (camGame.height - obj.height) / 2 + yOffset
    };
}

function followCenter(obj:FlxSprite, xOffset:Float, yOffset:Float)
{
    for (data in centerFollowers)
    {
        if (data.obj == obj)
        {
            data.xOffset = xOffset;
            data.yOffset = yOffset;
            data.active = true;
            return data;
        }
    }

    var data = {
        obj: obj,
        xOffset: xOffset,
        yOffset: yOffset,
        active: true
    };
    centerFollowers.push(data);
    return data;
}

function stopFollowingCenter(obj:FlxSprite)
{
    for (data in centerFollowers)
    {
        if (data.obj == obj)
            data.active = false;
    }
}

function updateCenterFollowers(elapsed:Float)
{
    var ratio = 1 - Math.pow(1 - centerFollowLerp, elapsed * 60);

    for (data in centerFollowers)
    {
        if (data.active && data.obj != null && data.obj.visible)
        {
            var pos = getCenteredPos(data.obj, data.xOffset, data.yOffset);
            data.obj.x += (pos.x - data.obj.x) * ratio;
            data.obj.y += (pos.y - data.obj.y) * ratio;
        }
    }
}
// ==========================
// MOSTRAR OBJETO
// ==========================
// ==========================
// MOSTRAR OBJETO
// ==========================
function showObject(
    obj:FlxSprite,
    enterDir:String,
    exitDir:String,
    durationMS:Int,
    xOffset:Float,
    yOffset:Float
)
{
    obj.visible = true;

    stopFollowingCenter(obj);

    var targetPos = getCenteredPos(obj, xOffset, yOffset);
    var targetX = targetPos.x;
    var targetY = targetPos.y;

    setupEnter(obj, enterDir, targetX, targetY);

    FlxTween.tween(obj,
    {
        x: targetX,
        y: targetY
    },
    0.8,
    {
        ease: FlxEase.expoOut,

        onComplete: function(_)
        {
            followCenter(obj, xOffset, yOffset);

            new FlxTimer().start(durationMS / 1000, function(_)
            {
                stopFollowingCenter(obj);

                var centeredPos = getCenteredPos(obj, xOffset, yOffset);
                obj.x = centeredPos.x;
                obj.y = centeredPos.y;

                var exitPos = getExitPos(
                    obj,
                    exitDir,
                    centeredPos.x,
                    centeredPos.y
                );

                FlxTween.tween(obj,
                {
                    x: exitPos.x,
                    y: exitPos.y
                },
                0.4,
                {
                    ease: FlxEase.expoIn,

                    onComplete: function(_)
                    {
                        obj.visible = false;
                    }
                });
            });
        }
    });
}

// ==========================
// UPDATE
// ==========================
function update(elapsed)
{
    updateCenterFollowers(elapsed);
    
    if (!showedPopup)
    {
        var popupTime = 0;

        if (songData.startTime != null)
            popupTime = songData.startTime;

        if (popupTime == -1)
        {
            showedPopup = true;
            return;
        }

        if (Conductor.songPosition >= popupTime)
        {
            showedPopup = true;

        if (useSplitText)
        {
            showSplitText(
                tLeft,
                tRight,
                "down",
                "right",
                2500,
                0,
                customTextOffsetY
            );
        }
        else
        {
            showObject(
                t1,
                "down",
                "right",
                2500,
                0,
                customTextOffsetY
            );
        }
            showObject(
                logo,
                "left",
                "up",
                2500,
                0,
                -100 + getCustomLogoYOffset()
            );
        }
    }

}
function beatHit(curBeat:Int)
{
    if(logo != null && logo.visible)
    {
        if (logoHasIdleAnim)
        {
            logo.animation.play("idle", true);
        }
        else
        {
            if (logoBumpTween != null) logoBumpTween.cancel();
            var centerX = logo.x + logo.width / 2;
            var centerY = logo.y + logo.height / 2;

            logo.scale.set(logoBaseScaleX * 1.08, logoBaseScaleY * 1.08);
            logo.updateHitbox();

            logo.x = centerX - logo.width / 2;
            logo.y = centerY - logo.height / 2;

            logoBumpTween = FlxTween.tween(
                logo.scale,
                {x: logoBaseScaleX, y: logoBaseScaleY},
                0.18,
                {
                    ease: FlxEase.quadOut,
                    onUpdate: function(_) {
                        logo.updateHitbox();
                        logo.x = centerX - logo.width / 2;
                        logo.y = centerY - logo.height / 2;
                    }
                }
            );
        }
    }
}
