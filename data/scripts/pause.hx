import VCSongText;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.FunkinText;
import funkin.backend.scripting.ModState;
import funkin.backend.utils.Paths;
import haxe.Json;
import lime.utils.Assets;

var pauseCam:FlxCamera;
var pauseBG:FlxSprite;
var pauseInfoTexts:FlxTypedGroup<FunkinText>;
var pauseMenuTexts:FlxTypedGroup<FunkinText>;
var pauseOptions:Array<String> = [];
var pauseSongText:FlxSprite = null;
var pauseLogo:FlxSprite = null;
var pauseTitleRevealed:Bool = false;
var pauseLogoHasIdleAnim:Bool = false;
var pauseLogoBaseScaleX:Float = 1;
var pauseLogoBaseScaleY:Float = 1;
var pauseLogoBumpTimer:Float = 0;
var pauseLogoBumpTween:FlxTween = null;
var songData:Dynamic = null;
var oldMouseVisible:Bool = false;

var logoTable = [
    {
        songs: [
            "light it up", "ruckus", "target practice", "burnout", "sporting", "boxing match",
            "sport swinging", "boxing gladiators", "flaming glove", "punch and gun", "fisticuffs",
            "blastout", "immortal", "king hit", "tko", "mat", "banger", "edgy", "venom",
            "disadvantage", "champion", "recovery", "last combat", "greedoom", "purgatory",
            "krakatoa", "showdown", "alter ego", "interregnum", "insano", "ballin",
            "sweet dreams", "sweet dreams ii", "flaming glove iii", "knocked", "edgelord",
            "rejected", "wastelands", "toxic", "veteran", "bombastic", "mattpurgation",
            "exodus", "take it", "cleverness", "tempo slayer", "total bravery", "ignis gladius",
            "king hit wawa", "warm up", "fishycuffs", "average voiid song", "penismatt",
            "wii remote", "damnale", "boxing match vip", "immortal vip", "king hit vip",
            "tko vip", "veteran vip", "edgy vip", "burnout vip", "alter ego vip",
            "target practice vip", "rejected vip"
        ],
        logo: "Logo"
    },
    {
        songs: [
            "power link", "revenge", "final destination", "final destination god",
            "shooting power", "thunderstorm", "disassembler", "cosmic memories",
            "new horizon", "galactic storm", "multiversal slash", "glowing collision",
            "radical showdown", "defamation of reality", "super saiyan", "haven",
            "rage", "intervention", "final destination old"
        ],
        logo: "LogoSXM"
    }
];

var defaultSong = '
{
    "composer": "",
    "charter": "",
    "originalComposer": "",
    "songFont": "dumbnerd.ttf",
    "songFontSize": 128,
    "infoFontSize": 24,
    "outerBorderTop": "#000000",
    "outerBorderBot": "#000000",
    "midBorderTop": "#c735ff",
    "midBorderBot": "#6414ea",
    "innerBorderTop": "#3f3f3f",
    "innerBorderBot": "#121617"
}';

var afkTime:Float = 0;
var hamsterLines:FlxTypedGroup<FlxSprite>;
var spawned:Bool = false;

var rightHamsters:Array<FlxSprite> = [];
var topHamsters:Array<FlxSprite> = [];

var cycleRunning:Bool = false;


var intersectionX:Float = 520;
var intersectionY:Float = 360;

var horizontalLanes:Int = 5; 
var verticalLanes:Int = 5;   

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
    {label: "Botplay", save: "voiidBotplay", fallback: false, needsRestart: false},
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

    event.cancel();
    pauseOptions = event.options;
    curSelected = 0;
    loadPauseCredits();

    pauseCam = new FlxCamera();
    pauseCam.bgColor = 0;
    FlxG.cameras.add(pauseCam, false);
    cameras = [pauseCam];
    oldMouseVisible = FlxG.mouse.visible;
    FlxG.mouse.visible = true;

    pauseBG = new FlxSprite().makeSolid(FlxG.width + 8, FlxG.height + 8, FlxColor.BLACK);
    pauseBG.alpha = 0;
    pauseBG.scrollFactor.set();
    pauseBG.screenCenter();
    add(pauseBG);
    FlxTween.tween(pauseBG, {alpha: 0.62}, 0.18, {ease: FlxEase.quadOut});

    createPauseSongHeader();

    pauseInfoTexts = new FlxTypedGroup<FunkinText>();
    add(pauseInfoTexts);
    addCreditInfoTexts();
    addInfoText("Blue balled: " + PlayState.deathCounter, 101);
    if (PlayState.opponentMode)
        addInfoText("OPPONENT MODE", 133);
    else if (PlayState.coopMode)
        addInfoText("CO-OP MODE", 133);

    pauseMenuTexts = new FlxTypedGroup<FunkinText>();
    add(pauseMenuTexts);
    for (i in 0...pauseOptions.length)
    {
        var txt = new FunkinText(90, FlxG.height * 0.46 + (i * 45), 0, getPauseOptionLabel(pauseOptions[i]), 32, true);
        txt.setFormat(Paths.font("Contb___.ttf"), 32, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        txt.borderSize = 1.25;
        txt.ID = i;
        txt.scrollFactor.set();
        txt.alpha = 0;
        pauseMenuTexts.add(txt);
        FlxTween.tween(txt, {alpha: 0.6, x: 110}, 0.16, {ease: FlxEase.quadOut, startDelay: i * 0.025});
    }

    hamsterLines = new FlxTypedGroup<FlxSprite>();
    add(hamsterLines);

    refreshPauseMenu();
    game.updateDiscordPresence();
}

function postCreate()
{
}

function loadPauseCredits()
{
    var basePath = "songs/" + PlayState.SONG.meta.name + "/credits.json";
    var diffPath = "songs/" + PlayState.SONG.meta.name + "/credits-" + PlayState.difficulty + ".json";

    try
    {
        if (Assets.exists(Paths.getPath(diffPath)))
            songData = Json.parse(Assets.getText(Paths.getPath(diffPath)));
        else if (Assets.exists(Paths.getPath(basePath)))
            songData = Json.parse(Assets.getText(Paths.getPath(basePath)));
        else
            songData = Json.parse(defaultSong);
    }
    catch(e:Dynamic)
    {
        songData = Json.parse(defaultSong);
    }
}

function getCreditField(name:String):String
{
    if (songData == null || Reflect.field(songData, name) == null) return "";
    return Std.string(Reflect.field(songData, name));
}

function getPauseSongDisplayName():String
{
    if (songData != null && Reflect.field(songData, "overrideName") != null)
        return Std.string(Reflect.field(songData, "overrideName"));
    return PlayState.SONG.meta.displayName;
}

function isFinalDestinationVip():Bool
{
    return PlayState.SONG != null && PlayState.SONG.meta != null
        && PlayState.SONG.meta.name.toLowerCase() == "final destination vip";
}

function getRevealTime():Float
{
    var jsonTime = getJsonFloat("startTime", -1);
    if (jsonTime >= 0) return jsonTime;
    return 0;
}

function shouldRevealPauseTitle():Bool
{
    return Conductor.songPosition >= getRevealTime();
}

function getPauseTitleText():String
{
    return shouldRevealPauseTitle() ? getPauseSongDisplayName() : "???";
}

function getPauseSongTextData():Dynamic
{
    if (!isFinalDestinationVip() || Conductor.songPosition < 156800)
        return songData;

    return Json.parse('
{
	"composer": "TheOnlyVolume,Wolfinu,ImSilv4,Aron_Aurora",
	"charter": "Sharik,Sanek,Parko",
	"originalComposer": "Srperez",

	"startTime": 156800,

	"songFont": "dumbnerd.ttf",
	"songFontSize": 64,
	"infoFontSize": 12,

	"diagonalSplit": true,
	"splitAngle": 45,
	"splitSoftness": 0.25,
	"splitOffset": 0.15,

	"outerBorderTop": "#000000",
	"outerBorderBot": "#000000",

	"midBorderTop": "#1ffbfe",
	"midBorderBot": "#ffa8f2",

	"innerBorderTop": "#1595f1",
	"innerBorderBot": "#5a3cb1",

	"leftOuterBorderTop": "#000000",
	"leftOuterBorderBot": "#000000",
	"leftMidBorderTop": "#1ffbfe",
	"leftMidBorderBot": "#1595f1",
	"leftInnerBorderTop": "#2a8cb5",
	"leftInnerBorderBot": "#0d3f88",

	"rightOuterBorderTop": "#000000",
	"rightOuterBorderBot": "#000000",
	"rightMidBorderTop": "#ff4bd8",
	"rightMidBorderBot": "#ff7a1f",
	"rightInnerBorderTop": "#b64f9f",
	"rightInnerBorderBot": "#8f1f00",

	"textOffsetY": 120,

	"logo": "FDVIP",
	"logoOffsetY": 0,
	"logoScale": 1,

	"sobelStrength": 0.6,
	"sobelIntensity": 1.0,

	"vipFont": "Onslaughter.otf",

	"outerBorderTopVIP": "#000000",
	"outerBorderBotVIP": "#000000",
	"midBorderTopVIP": "#474747",
	"midBorderBotVIP": "#474747",
	"innerBorderTopVIP": "#FFFFFF",
	"innerBorderBotVIP": "#FFFFFF",

	"outerBorderSize": 5,
	"midBorderSize": 2,
	"innerBorderSize": 2
}');
}

function getJsonFloat(field:String, fallback:Float):Float
{
    if (songData == null || Reflect.field(songData, field) == null)
        return fallback;

    var value = Std.parseFloat(Std.string(Reflect.field(songData, field)));
    return Math.isNaN(value) ? fallback : value;
}

function logoExists(logoName:String):Bool
{
    return Assets.exists(Paths.image("logos/" + logoName));
}

function getPauseLogoName():String
{
    if (!shouldRevealPauseTitle())
        return "";

    if (isFinalDestinationVip() && Conductor.songPosition >= 156800 && logoExists("FDVIP"))
        return "FDVIP";

    if (songData != null && Reflect.field(songData, "logo") != null && Std.string(Reflect.field(songData, "logo")) != "")
    {
        var jsonLogo = Std.string(Reflect.field(songData, "logo"));
        if (logoExists(jsonLogo)) return jsonLogo;
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

function getPauseLogoScale():Float
{
    if (isFinalDestinationVip() && Conductor.songPosition >= 156800)
        return 1.75;

    return getJsonFloat("logoScale", 0.8) * 1.8375;
}

function fitSpriteToBox(sprite:FlxSprite, maxW:Float, maxH:Float)
{
    if (sprite == null || sprite.width <= 0 || sprite.height <= 0) return;

    var scale = Math.min(maxW / sprite.width, maxH / sprite.height);
    if (scale < 1)
    {
        sprite.scale.set(sprite.scale.x * scale, sprite.scale.y * scale);
        sprite.updateHitbox();
    }
}

function tweenInFromRight(sprite:FlxSprite, targetX:Float, targetY:Float, delay:Float = 0)
{
    sprite.x = FlxG.width + 80;
    sprite.y = targetY;
    sprite.alpha = 0;
    FlxTween.tween(sprite, {x: targetX, alpha: 1}, 0.55, {ease: FlxEase.expoOut, startDelay: delay});
}

function createPauseSongHeader()
{
    var centerX = FlxG.width * 0.53;
    pauseTitleRevealed = shouldRevealPauseTitle();

    var logoName = getPauseLogoName();
    if (logoName != "")
    {
        try
        {
            pauseLogo = new FlxSprite();
            pauseLogo.frames = Paths.getFrames("logos/" + logoName);
            pauseLogo.animation.addByPrefix("idle", "idle", 24, true);
            pauseLogoHasIdleAnim = pauseLogo.animation.exists("idle");
            if (pauseLogoHasIdleAnim) pauseLogo.animation.play("idle");
            pauseLogo.setGraphicSize(Std.int(pauseLogo.width * getPauseLogoScale()));
            pauseLogo.updateHitbox();
            fitSpriteToBox(pauseLogo, 900, 360);
            pauseLogoBaseScaleX = pauseLogo.scale.x;
            pauseLogoBaseScaleY = pauseLogo.scale.y;
            pauseLogo.cameras = [pauseCam];
            pauseLogo.scrollFactor.set();
            add(pauseLogo);
            tweenInFromRight(pauseLogo, centerX - (pauseLogo.width * 0.5), 118 + getJsonFloat("logoOffsetY", 0) * 0.5, 0.05);
        }
        catch(e:Dynamic) {}
    }

    try
    {
        var titleData = getPauseSongTextData();
        var size = (pauseTitleRevealed ? getJsonFloat("songFontSize", 128) : 120) * 0.68;
        if (isFinalDestinationVip() && Conductor.songPosition >= 156800)
            size = 64 * 0.86;

        pauseSongText = createSongText(getPauseTitleText(), size, 10, titleData);
        fitSpriteToBox(pauseSongText, 560, 170);
        pauseSongText.cameras = [pauseCam];
        pauseSongText.scrollFactor.set();
        add(pauseSongText);
        tweenInFromRight(pauseSongText, centerX - (pauseSongText.width * 0.5), 455, 0.14);
    }
    catch(e:Dynamic) {}
}

function scaleSpriteFromCenter(sprite:FlxSprite, scaleX:Float, scaleY:Float)
{
    if (sprite == null) return;

    var centerX = sprite.x + sprite.width * 0.5;
    var centerY = sprite.y + sprite.height * 0.5;
    sprite.scale.set(scaleX, scaleY);
    sprite.updateHitbox();
    sprite.x = centerX - sprite.width * 0.5;
    sprite.y = centerY - sprite.height * 0.5;
}

function bumpPauseLogo()
{
    if (pauseLogo == null || pauseLogoHasIdleAnim) return;

    if (pauseLogoBumpTween != null)
        pauseLogoBumpTween.cancel();

    scaleSpriteFromCenter(pauseLogo, pauseLogoBaseScaleX * 1.08, pauseLogoBaseScaleY * 1.08);

    pauseLogoBumpTween = FlxTween.tween(pauseLogo.scale, {
        x: pauseLogoBaseScaleX,
        y: pauseLogoBaseScaleY
    }, 0.18, {
        ease: FlxEase.quadOut,
        onUpdate: function(_)
        {
            scaleSpriteFromCenter(pauseLogo, pauseLogo.scale.x, pauseLogo.scale.y);
        }
    });
}

function updatePauseLogoBump(elapsed:Float)
{
    if (pauseLogo == null || pauseLogoHasIdleAnim) return;

    pauseLogoBumpTimer += elapsed;
    var interval = Math.max(0.18, Conductor.crochet / 1000);
    if (pauseLogoBumpTimer >= interval)
    {
        pauseLogoBumpTimer = 0;
        bumpPauseLogo();
    }
}

function addCreditInfoTexts()
{
    var y = 18;
    var composer = getCreditField("composer");
    var charter = getCreditField("charter");
    var originalComposer = getCreditField("originalComposer");

    if (composer != "") { addInfoText("Composer: " + composer, y); y += 24; }
    if (charter != "") { addInfoText("Charter: " + charter, y); y += 24; }
    if (originalComposer != "") { addInfoText("Original: " + originalComposer, y); y += 24; }
}

function addInfoText(text:String, y:Float)
{
    if (text == null || text == "") return;

    var label = new FunkinText(FlxG.width - 560, y, 540, text, 18, false);
    label.setFormat(Paths.font("Contb___.ttf"), 18, FlxColor.WHITE, "right");
    label.scrollFactor.set();
    label.alpha = 0;
    label.updateHitbox();
    pauseInfoTexts.add(label);
    FlxTween.tween(label, {alpha: 1, y: y + 4}, 0.18, {ease: FlxEase.quadOut});
}

function getPauseOptionLabel(option:String):String
{
    return switch(option)
    {
        case "Restart Song": "Restart Song";
        case "Change Controls": "Controls";
        case "Change Options": "Options";
        case "Exit to menu": "Exit to Menu";
        case "Exit to charter": "Exit to Charter";
        default: option;
    }
}

function refreshPauseMenu()
{
    if (pauseMenuTexts == null) return;

    for (i in 0...pauseMenuTexts.members.length)
    {
        var txt = pauseMenuTexts.members[i];
        if (txt == null) continue;

        txt.text = (i == curSelected ? "> " : "  ") + getPauseOptionLabel(pauseOptions[i]);
        txt.alpha = i == curSelected ? 1 : 0.55;
        txt.color = i == curSelected ? 0xFFFFFFFF : 0xFFBBBBBB;
        txt.x = i == curSelected ? 118 : 105;
    }
}

function changePauseSelection(change:Dynamic)
{
    if (pauseOptions.length < 1) return;
    var amount = Std.int(change);
    if (amount == 0) return;
    curSelected = FlxMath.wrap(curSelected + amount, 0, pauseOptions.length - 1);
    refreshPauseMenu();
}

function clickPauseOption():Bool
{
    if (pauseMenuTexts == null || !FlxG.mouse.justPressed) return false;

    var mx = FlxG.mouse.x;
    var my = FlxG.mouse.y;

    for (i in 0...pauseMenuTexts.members.length)
    {
        var txt = pauseMenuTexts.members[i];
        if (txt == null) continue;

        var hitW = Math.max(txt.width, 300);
        if (mx >= txt.x - 18 && mx <= txt.x + hitW + 18 && my >= txt.y - 8 && my <= txt.y + txt.height + 8)
        {
            curSelected = i;
            refreshPauseMenu();
            if (pauseOptions[curSelected] == quickOptionName)
                openQuickOptions();
            else if (pauseOptions[curSelected] == "Change Options")
                openVoiidOptionsMenu();
            else
                selectOption();
            return true;
        }
    }

    return false;
}

function refreshQuickOptionLabels()
{
    try
    {
        if (pauseMenuTexts == null || pauseOptions == null) return;

        for (i in 0...pauseOptions.length)
        {
            var option = pauseOptions[i];
            if (option != quickOptionName) continue;

            var item = pauseMenuTexts.members[i];
            if (item != null) item.text = (i == curSelected ? "> " : "  ") + "Quick Options";
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

function changeQuickSelection(change:Dynamic)
{
    var amount = Std.int(change);
    if (amount == 0) return;
    quickSelected = FlxMath.wrap(quickSelected + amount, 0, quickItems.length - 1);
    refreshQuickMenu();
}

function clickQuickOption():Bool
{
    if (quickTexts == null || !FlxG.mouse.justPressed) return false;

    var mx = FlxG.mouse.x;
    var my = FlxG.mouse.y;

    for (i in 0...quickTexts.members.length)
    {
        var txt = quickTexts.members[i];
        if (txt == null) continue;

        if (mx >= txt.x && mx <= txt.x + txt.width && my >= txt.y - 8 && my <= txt.y + txt.height + 8)
        {
            quickSelected = i;
            refreshQuickMenu();
            toggleQuickSelected();
            return true;
        }
    }

    return false;
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

    if (event.name == "Change Options" || event.name == "Options")
    {
        event.cancel();
        openVoiidOptionsMenu();
        return;
    }

    if (event.name == quickOptionName)
    {
        event.cancel();
        openQuickOptions();
    }
}

function openVoiidOptionsMenu()
{
    Reflect.setField(FlxG.save.data, "voiidOptionsOpenedFromPause", true);
    if (PlayState.SONG != null && PlayState.SONG.meta != null)
        Reflect.setField(FlxG.save.data, "voiidPauseSong", PlayState.SONG.meta.name);
    Reflect.setField(FlxG.save.data, "voiidPauseDifficulty", PlayState.difficulty);
    Reflect.setField(FlxG.save.data, "voiidPauseVariation", PlayState.variation);
    Reflect.setField(FlxG.save.data, "voiidPauseStoryMode", PlayState.isStoryMode);
    Reflect.setField(FlxG.save.data, "voiidPauseOpponentMode", PlayState.opponentMode);
    Reflect.setField(FlxG.save.data, "voiidPauseCoopMode", PlayState.coopMode);
    Reflect.setField(FlxG.save.data, "voiidPauseChartingMode", PlayState.chartingMode);
    FlxG.save.flush();
    FlxG.switchState(new ModState("VoiidOptionsState"));
}

function onChangeItem(event)
{
    if (quickMenuOpen)
        event.cancel();
}

function update(elapsed:Float)
{
    updatePauseLogoBump(elapsed);

    if (quickMenuOpen)
    {
        if (FlxG.mouse.wheel != 0)
            changeQuickSelection(-FlxG.mouse.wheel);

        if (clickQuickOption())
            return;

        if (FlxG.keys.justPressed.UP)
            changeQuickSelection(-1);

        if (FlxG.keys.justPressed.DOWN)
            changeQuickSelection(1);

        if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
            toggleQuickSelected();

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
            toggleQuickSelected();

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
            closeQuickOptions();

        return;
    }

    if (FlxG.mouse.wheel != 0)
        changePauseSelection(-FlxG.mouse.wheel);

    if (clickPauseOption())
        return;

    if (FlxG.keys.justPressed.UP)
        changePauseSelection(-1);

    if (FlxG.keys.justPressed.DOWN)
        changePauseSelection(1);

    if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
    {
        if (pauseOptions[curSelected] == quickOptionName)
            openQuickOptions();
        else if (pauseOptions[curSelected] == "Change Options")
            openVoiidOptionsMenu();
        else
            selectOption();
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

function destroy()
{
    if (pauseLogoBumpTween != null)
        pauseLogoBumpTween.cancel();

    if (quickMenuOpen)
        closeQuickOptions();

    if (hamsterLines != null)
    {
        for (spr in hamsterLines.members)
        {
            if (spr != null)
                FlxTween.cancelTweensOf(spr);
        }
    }

    if (pauseCam != null && FlxG.cameras.list.contains(pauseCam))
        FlxG.cameras.remove(pauseCam, true);

    FlxG.mouse.visible = oldMouseVisible;
}
