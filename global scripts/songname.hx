import VCSongText;
import flixel.util.FlxTimer;
import flixel.text.FlxTextBorderStyle;
import flixel.math.FlxMath;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.GradientType;
import openfl.geom.Matrix;



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
var displaySongName:String = "";

var timeTxt:FlxText = null;
var timerBarBG:FlxSprite = null;
var timerBarFill:FlxSprite = null;
var revealedTimerSongName:Bool = false;
var pendingTimerSongName:String = "";
var timerBarWidth:Float = 600;
var timerBarHeight:Float = 16;
var timerBarPadding:Float = 4;
var timerTopY:Float = 2;
var timerTextTopY:Float = 20;
var timerSkinPrefix:String = "voiid/";
var timerSkinChanges:Array<Dynamic> = [];



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
var songCreditEntries:Array<Dynamic> = [];
var nextCreditIndex:Int = 0;
var preloadWarmupObjects:Array<Dynamic> = [];
var preloadWarmupFrames:Int = 0;
var pausePreloadWarmupObjects:Array<Dynamic> = [];
var loadedBaseCreditData:Dynamic = null;
var loadedSecondCreditData:Dynamic = null;
var loadedRawSecondCreditData:Dynamic = null;
// pause.hx is created only when pausing, so its reusable resources live here.
// Global scripts stay alive for the whole song and ScriptPack.get() can expose
// this cache to the temporary pause script without modifying PlayState fields.
var voiidPauseCache:Dynamic = null;




var logoTable = [

    
    {
        songs: [    
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

    
    "alter ego",
    "interregnum",
    "insano",
    "ballin",
    "sweet dreams",
    "sweet dreams ii",

    
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




function logoExists(logoName:String):Bool
{
    return Assets.exists(Paths.image("logos/" + logoName));
}

function getDataFloat(data:Dynamic, field:String, fallback:Float):Float
{
    if (data == null || Reflect.field(data, field) == null)
        return fallback;

    var value = Std.parseFloat(Std.string(Reflect.field(data, field)));
    return Math.isNaN(value) ? fallback : value;
}

function getJsonFloat(field:String, fallback:Float):Float
{
    return getDataFloat(songData, field, fallback);
}

function getDataBool(data:Dynamic, field:String, fallback:Bool):Bool
{
    if (data == null || Reflect.field(data, field) == null)
        return fallback;

    var v = Std.string(Reflect.field(data, field)).toLowerCase();
    return v == "true" || v == "1";
}

function getJsonBool(field:String, fallback:Bool):Bool
{
    return getDataBool(songData, field, fallback);
}

function getDataInt(data:Dynamic, field:String, fallback:Int):Int
{
    if (data == null || Reflect.field(data, field) == null)
        return fallback;

    var value = Std.parseInt(Std.string(Reflect.field(data, field)));
    return value == null ? fallback : value;
}

function getJsonInt(field:String, fallback:Int):Int
{
    return getDataInt(songData, field, fallback);
}

function loadCreditData(fileName:String):Dynamic
{
    var path = "songs/" + PlayState.SONG.meta.name + "/" + fileName;

    try
    {
        if (Assets.exists(path))
            return Json.parse(Assets.getText(path));
    }
    catch(e:Dynamic) {}

    return null;
}

function loadSongCreditEntries()
{
    songCreditEntries = [];
    nextCreditIndex = 0;
    loadedBaseCreditData = null;
    loadedSecondCreditData = null;
    loadedRawSecondCreditData = null;

    var baseData = loadCreditData("credits.json");
    if (baseData == null)
        baseData = Json.parse(defaultSong);
    loadedBaseCreditData = baseData;

    songCreditEntries.push({
        data: baseData,
        time: getDataFloat(baseData, "startTime", 0)
    });

    var secondData = loadCreditData("credits2.json");
    if (secondData != null)
    {
        loadedRawSecondCreditData = secondData;
        secondData = mergeCreditData(baseData, secondData);
        loadedSecondCreditData = secondData;

        songCreditEntries.push({
            data: secondData,
            time: getDataFloat(secondData, "startTime", 0)
        });
    }

    songCreditEntries.sort(function(a, b) {
        if(a.time < b.time) return -1;
        else if(a.time > b.time) return 1;
        else return 0;
    });
}

function mergeCreditData(baseData:Dynamic, overrideData:Dynamic):Dynamic
{
    var merged = cloneData(baseData);

    for (field in Reflect.fields(overrideData))
        Reflect.setField(merged, field, Reflect.field(overrideData, field));

    return merged;
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

function getCustomLogoXOffset():Float
{
    if (!logoFromJson || songData == null || songData.logoOffsetX == null)
        return 0;
    var offset = Std.parseFloat(Std.string(songData.logoOffsetX));
    return Math.isNaN(offset) ? 0 : offset;
}

function getDefaultSongName():String {
    if (displaySongName != null && displaySongName != "")
        return displaySongName;
    if (PlayState.SONG != null && PlayState.SONG.meta != null && PlayState.SONG.meta.displayName != null)
        return Std.string(PlayState.SONG.meta.displayName);
    return curSong;
}

function revealTimerSongName(?name:String) {
    revealedTimerSongName = true;
    pendingTimerSongName = name != null && name != "" ? name : getDefaultSongName();
    updateTimerText();
}

function cacheTimerSkinChanges() {
    timerSkinChanges = [];
    for (event in events) {
        if (event.name == "Change UI Skin") {
            timerSkinChanges.push({
                time: event.time,
                prefix: event.params[0]
            });
        }
    }

    if (timerSkinChanges.length > 0) {
        timerSkinChanges.sort(function(a, b) {
            if(a.time < b.time) return -1;
            else if(a.time > b.time) return 1;
            else return 0;
        });

        if (timerSkinChanges[0].time <= 0)
            timerSkinPrefix = timerSkinChanges[0].prefix;
    }
}

function updateTimerSkinBySongPosition() {
    if (timerSkinChanges.length == 0) return;

    var prefix = timerSkinPrefix;
    for (change in timerSkinChanges) {
        if (Conductor.songPosition >= change.time)
            prefix = change.prefix;
        else
            break;
    }
    timerSkinPrefix = prefix;
}

function isPaperTimer():Bool {
    return timerSkinPrefix == "paper/";
}

function saveBool(name:String, fallback:Bool):Bool {
    var value = Reflect.field(FlxG.save.data, name);
    if (value == null)
        return fallback;
    return value == true;
}

function saveString(name:String, fallback:String):String {
    var value = Reflect.field(FlxG.save.data, name);
    if (value == null || Std.string(value) == "")
        return fallback;
    return Std.string(value);
}

function getTimerTags():String {
    if (!saveBool("voiidTimerFlags", true))
        return "";

    var tags:Array<String> = [];
    if (saveBool("voiidBotplay", false))
        tags.push("BOT");
    if (saveBool("voiidNoDeath", false))
        tags.push("NO DEATH");
    if (saveBool("voiidNoDeathDied", false))
        tags.push("DIED");

    return tags.length > 0 ? " (" + tags.join(") (") + ")" : "";
}

function formatTime(seconds:Int):String {
    if (seconds < 0) seconds = 0;
    return Std.int(seconds / 60) + ":" + CoolUtil.addZeros(Std.string(seconds % 60), 2);
}

function getOpponentTimerColor():Int {
    try {
        if (dad != null && dad.iconColor != null)
            return dad.iconColor;
    } catch(e:Dynamic) {}

    return 0xFFFF0000;
}
function getPlayerTimerColor():Int {
    try {
        if (boyfriend != null && boyfriend.iconColor != null)
            return boyfriend.iconColor;
    } catch(e:Dynamic) {}

    return 0xFF66FFFF;
}

function updateTimerGradient()
{
    if (timerBarFill == null)
        return;

    var w = Std.int(timerBarWidth - (timerBarPadding * 2));
    var h = Std.int(timerBarHeight - (timerBarPadding * 2));

    var shape = new Shape();
    var matrix = new Matrix();

    matrix.createGradientBox(w, h, 0);

    shape.graphics.beginGradientFill(
        GradientType.LINEAR,
        [
            getOpponentTimerColor(),
            getPlayerTimerColor()
        ],
        [1, 1],
        [0, 255],
        matrix
    );

    shape.graphics.drawRect(0, 0, w, h);
    shape.graphics.endFill();

    var bmp = new BitmapData(w, h, true, 0x00000000);
    bmp.draw(shape);

    timerBarFill.pixels = bmp;
    timerBarFill.dirty = true;
}

function createTimerUI() {
    var style = saveString("voiidTimeBarStyle", "leather engine");
    timerBarHeight = style == "psych engine" ? 20 : (style == "old kade engine" ? 10 : 16);
    timerBarPadding = style == "old kade engine" ? 2 : 4;

    var pos = saveString("voiidTimeBarPosition", "top");
    timerTopY = pos == "bottom" ? FlxG.height - 34 : 2;
    timerTextTopY = pos == "bottom" ? FlxG.height - 58 : 20;

    timerBarBG = new FlxSprite(0, timerTopY);
    timerBarBG.makeGraphic(Std.int(timerBarWidth), Std.int(timerBarHeight), 0xFF000000);
    timerBarBG.scrollFactor.set();
    timerBarBG.screenCenter(FlxAxes.X);
    timerBarBG.cameras = [camHUD];
    add(timerBarBG);

    timerBarFill = new FlxSprite(timerBarBG.x + timerBarPadding, timerBarBG.y + timerBarPadding);
    timerBarFill.makeGraphic(
        Std.int(timerBarWidth - (timerBarPadding * 2)),
        Std.int(timerBarHeight - (timerBarPadding * 2)),
        0xFFFFFFFF
    );

    updateTimerGradient();
    timerBarFill.scrollFactor.set();
    timerBarFill.origin.set(0, 0);
    timerBarFill.scale.x = 0;
    timerBarFill.cameras = [camHUD];
    add(timerBarFill);

    timeTxt = new FlxText(0, timerTextTopY, 900, "???", 16);
    timeTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    timeTxt.scrollFactor.set();
    timeTxt.borderSize = 2;
    timeTxt.bold = true;
    timeTxt.screenCenter(FlxAxes.X);
    timeTxt.cameras = [camHUD];
    add(timeTxt);
    updateTimerText();
}

function updateTimerText() {
    if (timeTxt == null)
        return;

    var songName = revealedTimerSongName ? pendingTimerSongName : "???";
    if (songName == null || songName == "")
        songName = getDefaultSongName();

    var difficulty = PlayState.difficulty != null ? PlayState.difficulty.toUpperCase() : "";
    var timeRemaining = 0;
    if (inst != null)
        timeRemaining = Std.int(Math.max(0, inst.length - Conductor.songPosition) / 1000);

if (isPaperTimer()) {
    timeTxt.text = formatTime(timeRemaining);
    timeTxt.size = 24;
    timeTxt.borderSize = 2.5;
    timeTxt.fieldWidth = 220;

    
    timeTxt.updateHitbox();

    if (healthBarBG != null) {
        timeTxt.x = healthBarBG.x + (healthBarBG.width * 0.5) - (timeTxt.fieldWidth * 0.5);

        
        var paperTimerOffset:Float = 12;

        if (!downscroll) {
            
            timeTxt.y = healthBarBG.y + paperTimerOffset;
        } else {
            
            timeTxt.y = healthBarBG.y + healthBarBG.height - paperTimerOffset - timeTxt.height;
        }
    } else {
        timeTxt.screenCenter(FlxAxes.X);
        timeTxt.y = downscroll ? FlxG.height - 118 : 18;
    }

    return;
}


    timeTxt.text = songName + " - " + difficulty + " (" + formatTime(timeRemaining) + ")" + getTimerTags();
    timeTxt.size = 16;
    timeTxt.borderSize = 2;
    timeTxt.fieldWidth = 900;
    timeTxt.y = timerTextTopY;
    timeTxt.screenCenter(FlxAxes.X);
}

function updateTimerBar() {
    if (timerBarFill == null || inst == null || inst.length <= 0)
        return;

    if (isPaperTimer()) {
        timerBarBG.visible = false;
        timerBarFill.visible = false;
        return;
    }

    timerBarBG.visible = true;
    timerBarFill.visible = true;

    timerBarFill.scale.x = FlxMath.bound(Conductor.songPosition / inst.length, 0, 1);
    timerBarFill.updateHitbox();
    timerBarFill.x = timerBarBG.x + timerBarPadding;
    timerBarFill.y = timerBarBG.y + timerBarPadding;
}

function clearPopupSprites()
{
    centerFollowers = [];

    if (logoBumpTween != null)
    {
        logoBumpTween.cancel();
        logoBumpTween = null;
    }

    for (obj in [t1, tLeft, tRight, logo])
    {
        if (obj != null)
        {
            remove(obj);
            obj.destroy();
        }
    }

    t1 = null;
    tLeft = null;
    tRight = null;
    logo = null;
    logoHasIdleAnim = false;
    logoBaseScaleX = 1;
    logoBaseScaleY = 1;
}

function preparePopup(data:Dynamic)
{
    clearPopupSprites();
    songData = data;

    logoScale = getJsonFloat("logoScale", 0.8);
    customTextOffsetY = getJsonFloat("textOffsetY", 200);

    useSplitText = getJsonBool("splitText", false);
    splitTextAt = getJsonInt("splitTextAt", -1);
    splitTextGap = getJsonFloat("splitTextGap", 0);
    displaySongName = PlayState.SONG.meta.displayName;

    if (songData.overrideName != null)
        displaySongName = Std.string(songData.overrideName);

    if (useSplitText)
    {
        var fullText = displaySongName;

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
            splitLeftData
        );

        tRight = makeCoolText(
            rightText,
            songData.songFontSize,
            12,
            splitRightData
        );
    }
    else
    {
        t1 = makeCoolText(
            displaySongName,
            songData.songFontSize,
            12,
            songData
        );
    }

    var logoName = getLogoName();

    logo = new FlxSprite();
    logo.frames = Paths.getFrames("logos/" + logoName);
    logo.animation.addByPrefix("idle", "idle", 24, false);

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

function capturePreparedPopup():Dynamic
{
    return {
        data: songData,
        text: t1,
        leftText: tLeft,
        rightText: tRight,
        logo: logo,
        splitText: useSplitText,
        splitGap: splitTextGap,
        displayName: displaySongName,
        textY: customTextOffsetY,
        logoFromJson: logoFromJson,
        logoHasIdleAnim: logoHasIdleAnim,
        logoBaseScaleX: logoBaseScaleX,
        logoBaseScaleY: logoBaseScaleY
    };
}

function detachPreparedPopupGlobals()
{
    t1 = null;
    tLeft = null;
    tRight = null;
    logo = null;
    songData = null;
    centerFollowers = [];
    logoBumpTween = null;
}

function setPreparedObjectAlpha(obj:Dynamic, value:Float)
{
    if (obj == null)
        return;

    obj.alpha = value;

    // VCSongText draws the VIP child manually, outside the parent's alpha.
    // Mirror the warmup alpha so it cannot flash at full opacity.
    var child = Reflect.field(obj, "childText");
    if (child != null)
        child.alpha = value;
}

function addPreparedObjectsToWarmup(prepared:Dynamic)
{
    for (obj in [prepared.text, prepared.leftText, prepared.rightText, prepared.logo])
    {
        if (obj == null)
            continue;

        // Let OpenFL upload the generated bitmap and compile its shader during
        // the first rendered frame. The alpha is intentionally imperceptible.
        setPreparedObjectAlpha(obj, 0.001);
        obj.visible = true;
        preloadWarmupObjects.push(obj);
    }
}

function finishPreloadWarmup()
{
    for (obj in preloadWarmupObjects)
    {
        if (obj == null)
            continue;
        obj.visible = false;
        setPreparedObjectAlpha(obj, 1);
    }

    for (obj in pausePreloadWarmupObjects)
    {
        if (obj == null)
            continue;

        obj.visible = false;
        setPreparedObjectAlpha(obj, 1);
        remove(obj, false);
    }

    preloadWarmupObjects = [];
    pausePreloadWarmupObjects = [];
    preloadWarmupFrames = 0;
}

function updatePreloadWarmup()
{
    if (preloadWarmupFrames <= 0)
        return;

    preloadWarmupFrames--;
    if (preloadWarmupFrames <= 0)
        finishPreloadWarmup();
}

function preloadCreditPopups()
{
    preloadWarmupObjects = [];
    preloadWarmupFrames = 0;

    for (entry in songCreditEntries)
    {
        entry.prepared = null;

        if (entry.time == -1)
            continue;

        try
        {
            preparePopup(entry.data);
            entry.prepared = capturePreparedPopup();
            addPreparedObjectsToWarmup(entry.prepared);
            detachPreparedPopupGlobals();
        }
        catch(e:Dynamic)
        {
            clearPopupSprites();
            detachPreparedPopupGlobals();
            trace("[songname] No se pudo precargar un cartel: " + Std.string(e));
        }
    }

    // Keep the objects drawable for one full frame before hiding them.
    if (preloadWarmupObjects.length > 0)
        preloadWarmupFrames = 2;
}

function activatePreparedPopup(prepared:Dynamic)
{
    clearPopupSprites();

    songData = prepared.data;
    t1 = prepared.text;
    tLeft = prepared.leftText;
    tRight = prepared.rightText;
    logo = prepared.logo;
    useSplitText = prepared.splitText;
    splitTextGap = prepared.splitGap;
    displaySongName = prepared.displayName;
    customTextOffsetY = prepared.textY;
    logoFromJson = prepared.logoFromJson;
    logoHasIdleAnim = prepared.logoHasIdleAnim;
    logoBaseScaleX = prepared.logoBaseScaleX;
    logoBaseScaleY = prepared.logoBaseScaleY;

    for (obj in [t1, tLeft, tRight, logo])
    {
        if (obj != null)
        {
            obj.visible = false;
            setPreparedObjectAlpha(obj, 1);
        }
    }
}

function loadPausePreloadCreditSet(suffix:String):Dynamic
{
    var songPath = "songs/" + PlayState.SONG.meta.name + "/";
    var diffAsset = Paths.getPath(songPath + "credits" + suffix + "-" + PlayState.difficulty + ".json");

    try
    {
        if (Assets.exists(diffAsset))
            return Json.parse(Assets.getText(diffAsset));
    }
    catch(e:Dynamic) {}

    // Reuse the JSON already loaded by the song popup whenever there is no
    // difficulty-specific file, avoiding a second disk read at startup.
    if (suffix == "")
        return loadedBaseCreditData;
    if (suffix == "2")
        return loadedRawSecondCreditData;

    return null;
}

function getPausePreloadTitle(data:Dynamic):String
{
    if (data != null && Reflect.field(data, "overrideName") != null)
        return Std.string(Reflect.field(data, "overrideName"));
    return PlayState.SONG.meta.displayName;
}

function getPausePreloadFontSize(data:Dynamic, revealed:Bool):Float
{
    if (!revealed)
        return getDataFloat(data, "pauseHiddenSongFontSize", 120) * 0.68;

    if (data != null && Reflect.field(data, "pauseSongFontSize") != null)
        return getDataFloat(data, "pauseSongFontSize", 64);

    return getDataFloat(data, "songFontSize", 128) * 0.68;
}

function fitPausePreloadText(sprite:FlxSprite, maxW:Float, maxH:Float)
{
    if (sprite == null || sprite.width <= 0 || sprite.height <= 0)
        return;

    var scale = Math.min(maxW / sprite.width, maxH / sprite.height);
    if (scale < 1)
    {
        sprite.scale.set(sprite.scale.x * scale, sprite.scale.y * scale);
        sprite.updateHitbox();
    }
}

function createPausePreloadText(text:String, data:Dynamic, revealed:Bool):FlxSprite
{
    var result = createSongText(text, getPausePreloadFontSize(data, revealed), 10, data);
    fitPausePreloadText(result, 560, 170);
    result.cameras = [camGame];
    result.scrollFactor.set();
    result.visible = true;
    setPreparedObjectAlpha(result, 0.001);
    add(result);
    pausePreloadWarmupObjects.push(result);
    return result;
}

function getPausePreloadLogoName(data:Dynamic):String
{
    if (data != null && Reflect.field(data, "logo") != null && Std.string(Reflect.field(data, "logo")) != "")
    {
        var jsonLogo = Std.string(Reflect.field(data, "logo"));
        if (logoExists(jsonLogo))
            return jsonLogo;
    }

    var curSongName = PlayState.SONG.meta.name.toLowerCase();
    for (entry in logoTable)
    {
        for (song in entry.songs)
        {
            if (curSongName == song.toLowerCase() && logoExists(entry.logo))
                return entry.logo;
        }
    }

    return logoExists("Logo") ? "Logo" : "";
}

function createPausePreloadEntry(data:Dynamic):Dynamic
{
    if (data == null)
        return null;

    var cachedText:FlxSprite = null;
    try
    {
        cachedText = createPausePreloadText(getPausePreloadTitle(data), data, true);
    }
    catch(e:Dynamic)
    {
        trace("[songname] No se pudo precargar el título de pausa: " + Std.string(e));
    }

    var logoName = getPausePreloadLogoName(data);
    if (logoName != "")
    {
        try
        {
            Paths.getFrames("logos/" + logoName);
            Paths.image("logos/" + logoName);
        }
        catch(e:Dynamic) {}
    }

    return {
        data: data,
        text: cachedText,
        logoName: logoName
    };
}

function preloadPauseMenuAssets()
{
    if (PlayState.instance == null)
        return;

    var baseData = loadPausePreloadCreditSet("");
    if (baseData == null)
        baseData = Json.parse(defaultSong);

    var secondOverride = loadPausePreloadCreditSet("2");
    var secondData = secondOverride == null ? null : mergeCreditData(baseData, secondOverride);

    var baseEntry = createPausePreloadEntry(baseData);
    var secondEntry = createPausePreloadEntry(secondData);
    var hiddenText:FlxSprite = null;
    var cachedBackground:FlxSprite = null;

    try
    {
        hiddenText = createPausePreloadText("???", baseData, false);
    }
    catch(e:Dynamic)
    {
        trace("[songname] No se pudo precargar el título oculto de pausa: " + Std.string(e));
    }

    try
    {
        cachedBackground = new FlxSprite().makeSolid(FlxG.width + 8, FlxG.height + 8, FlxColor.BLACK);
        cachedBackground.alpha = 0;
        cachedBackground.visible = false;
        cachedBackground.scrollFactor.set();
        cachedBackground.screenCenter();
    }
    catch(e:Dynamic) {}

    // PauseSubState always loads this track, even with its default UI cancelled.
    // Decode it during song startup so opening pause does not hit the disk.
    try Assets.getMusic(Paths.music("breakfast")) catch(e:Dynamic) {}
    try Paths.font("Contb___.ttf") catch(e:Dynamic) {}

    voiidPauseCache = {
        songName: Std.string(PlayState.SONG.meta.name),
        difficulty: Std.string(PlayState.difficulty),
        variation: Std.string(PlayState.variation),
        baseData: baseData,
        secondData: secondData,
        baseEntry: baseEntry,
        secondEntry: secondEntry,
        hiddenText: hiddenText,
        background: cachedBackground,
        menuTexts: null,
        menuSignature: ""
    };

    if (pausePreloadWarmupObjects.length > 0)
        preloadWarmupFrames = Math.max(preloadWarmupFrames, 2);
}

function showPreparedPopup()
{
    revealTimerSongName(displaySongName);

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
        getCustomLogoXOffset(),
        -100 + getCustomLogoYOffset()
    );
}




function postCreate()
{
    centerX = FlxG.width / 2;
    centerY = FlxG.height / 2;

    cacheTimerSkinChanges();
    loadSongCreditEntries();
    createTimerUI();
    preloadCreditPopups();
    preloadPauseMenuAssets();
}



function makeCoolText(text:String, size:Float, spacing:Float, data:Dynamic)
{
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




function update(elapsed)
{
    updatePreloadWarmup();
    updateCenterFollowers(elapsed);
    updateTimerSkinBySongPosition();
    
    if (nextCreditIndex < songCreditEntries.length)
    {
        var entry = songCreditEntries[nextCreditIndex];
        var popupTime:Float = entry.time;

        if (popupTime == -1)
        {
            nextCreditIndex++;
        }
        else if (Conductor.songPosition >= popupTime)
        {
            showedPopup = true;
            nextCreditIndex++;

            // If the popup starts immediately, stop the warmup before activating
            // it so the next frame cannot hide the active objects again.
            if (preloadWarmupFrames > 0)
                finishPreloadWarmup();

            if (entry.prepared != null)
            {
                var prepared = entry.prepared;
                entry.prepared = null;
                activatePreparedPopup(prepared);
            }
            else
                preparePopup(entry.data);

            showPreparedPopup();
        }
    }

    updateTimerText();
    updateTimerBar();

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

function destroyPauseCacheObject(obj:Dynamic)
{
    if (obj == null)
        return;

    try FlxTween.cancelTweensOf(obj) catch(e:Dynamic) {}
    try remove(obj, false) catch(e:Dynamic) {}

    try
    {
        if (FlxG.state != null && FlxG.state.subState != null)
            FlxG.state.subState.remove(obj, false);
    }
    catch(e:Dynamic) {}

    var child = Reflect.field(obj, "childText");
    if (child != null)
    {
        try child.destroy() catch(e:Dynamic) {}
    }

    try obj.destroy() catch(e:Dynamic) {}
}

function destroy()
{
    var cache = voiidPauseCache;
    if (cache == null)
        return;

    destroyPauseCacheObject(Reflect.field(cache, "hiddenText"));
    destroyPauseCacheObject(Reflect.field(cache, "background"));
    destroyPauseCacheObject(Reflect.field(cache, "menuTexts"));

    for (field in ["baseEntry", "secondEntry"])
    {
        var entry = Reflect.field(cache, field);
        if (entry != null)
            destroyPauseCacheObject(Reflect.field(entry, "text"));
    }

    voiidPauseCache = null;
    pausePreloadWarmupObjects = [];
}
