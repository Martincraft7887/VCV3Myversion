import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxAxes;
import flixel.util.FlxStringUtil;
import flixel.group.FlxTypedGroup;

import funkin.menus.FreeplaySonglist;
import funkin.game.PlayState;
import funkin.savedata.FunkinSave;
import funkin.backend.utils.AudioAnalyzer;

import Type;
import Reflect;
import haxe.Json;
import VCSongText;
using StringTools;

// =====================
// CATEGORY HUB
// =====================

var inCategoryMenu:Bool = true;
var categoryIndex:Int = 0;

var categoryNames:Array<String> = [
    "--- Story mode ---",
    "--- Collabs ---",
    "--- Extras ---",
    "--- VIP remixes ---"
];

var categoryTexts:Array<FlxText> = [];
var skipCategoryText:FlxText;
var selectorInputLock:Float = 0;
var categoryInputLock:Float = 0;
var pendingSelectorOpen:Bool = false;
var pendingSelectorTarget:String = null;

// =====================
// FREEPLAY CUSTOM
// =====================

function clefInterp(delta, value, target, timescale = 1) {
    if (value > target) return delta * (Math.abs(value - target) * timescale);
    if (value < target) return delta * (Math.abs(value - target) * -timescale);
    return value;
}

function makeRect(x, y, w, h, col) {
    s = new FlxSprite(x, y).makeGraphic(w, h, col);
    return s;
}

function repeat(char, loops = 0) {
    if (loops <= 0) return "";

    var str = "";
    for (i in 0...loops) {
        str += char;
    }

    return str;
}

function makeText(x, y, str = "", size = 16, align = "left", outline = true) {
    var t = new FunkinText(x, y, 0, str, size, outline);
    t.antialiasing = Options.antialiasing;
    t.alignment = align;
    return t;
}

function makeSongText(x, y, str = "") {
    var t = new VCSongText(x, y, 0, str);
    t.size = songTextSize;
    t.antialiasing = Options.antialiasing;
    t.font = Paths.font(songFont);
    t.border1Size = 0;
    t.border2Size = 5;
    t.borderIterations = 8;
    t.border2Color = 0xFF000000;
    t.scale.set(0.6, 0.6);
    t.updateHitbox();
    t.centerOffsets();
    if (t.width > 650) {
        t.setGraphicSize(650);
        t.updateHitbox();
        t.centerOffsets();
    }
    return t;
}

function makeSongBack(selected:Bool = false) {
    var spr = new FlxSprite();
    spr.loadGraphic(Paths.image(selected ? "menus/freeplay/square_song_selected" : "menus/freeplay/square_song"));
    spr.scale.set(0.9, 0.9);
    spr.updateHitbox();
    spr.antialiasing = Options.antialiasing;
    if (selected) spr.alpha = 0;
    return spr;
}

function loadFreeplayBGPorts() {
    freeplayBGPorts = [];

    for (lib in Paths.assetsTree.libraries) {
        if (lib.exists(Paths.getPath("data/freeplaySongs.json"), "TEXT")) {
            var freeplaySongs = Json.parse(lib.getText(Paths.getPath("data/freeplaySongs.json")));
            for (cat in freeplaySongs.categories) {
                for (song in cat.songs) {
                    if (song.port != null) {
                        freeplayBGPorts.push({
                            name: Std.string(song.name).toLowerCase(),
                            port: Std.string(song.port)
                        });
                    }
                }
            }
        }
    }
}

function getFreeplayBGPort(songName:String) {
    var key = songName.toLowerCase();
    for (data in freeplayBGPorts) {
        if (data.name == key) return data.port;
    }
    return null;
}

var selection = 0;
function changeSelection(delta, reference) {
    if (delta == 0 || reference == null) return;
    selection += delta;
    if (selection > reference.length - 1) selection = 0;
    if (selection < 0) selection = reference.length - 1;

    CoolUtil.playMenuSFX(0);
}

var visBar:FlxSprite;
var spect:AudioAnalyzer;
var visualizerBarWidth:Int = 360;
var visualizerBarThickness:Int = 2;

var bg;
var songBG:FlxSprite;
var dotsTop:FlxSprite;
var dotsBottom:FlxSprite;
var freeplayTitle:FunkinText;
var songList;
var group = [];
var groupBacks = [];
var groupSelectedBacks = [];
var songFont:String = "dumbnerd.ttf";
var songTextSize:Int = 128;
var songTextWidth:Float = 900;
var lastLoadedSongBG:String = "";
var freeplayBGPorts = [];

var diffText;

var gap = 64;
var selectionY = 0;
var isSelected = false;
var transitioningOut = false;

var modeNum = 0;
var lastModeNum = 0;
var currentMode = [
    "Solo",
    "Opponent",
    "Co-Op",
    "Swapped Co-Op"
];

var customValuesText;
var pbText;

var menuSong_Seekhead:Float = 0;
var menuSong_Tempo:Float = 0;
var menuSong_TimeSig:String = "4 4";

var inst:FlxSound;

var selectedDiff = 0;
function changeDiff(delta, reference) {
    if (delta == 0 || reference == null) return;
    selectedDiff += delta;
    if (selectedDiff > reference.length - 1) selectedDiff = 0;
    if (selectedDiff < 0) selectedDiff = reference.length - 1;

    CoolUtil.playMenuSFX(0);
}

function create() {
    trace("NewFreeplayState custom: create -> category hub");
    inCategoryMenu = true;
    categoryIndex = 0;
    isSelected = false;
    selectedDiff = 0;
    selectorInputLock = 0;
    categoryInputLock = 0.25;
    pendingSelectorOpen = false;
    pendingSelectorTarget = null;

    if (!FlxG.sound.music.playing) CoolUtil.playMenuSong();
    loadFreeplayBGPorts();

    bg = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/freeplay/BG'));
    bg.setGraphicSize(FlxG.width);
    bg.updateHitbox();
    add(bg);

    songBG = new FlxSprite(0, 0).makeGraphic(1, 1, 0xFF000000);
    songBG.alpha = 0;
    add(songBG);

    dotsTop = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/freeplay/dot_up'));
    dotsTop.setGraphicSize(FlxG.width);
    dotsTop.updateHitbox();
    dotsTop.antialiasing = Options.antialiasing;
    add(dotsTop);

    dotsBottom = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/freeplay/dot_down'));
    dotsBottom.setGraphicSize(FlxG.width);
    dotsBottom.updateHitbox();
    dotsBottom.y = FlxG.height - dotsBottom.height;
    dotsBottom.antialiasing = Options.antialiasing;
    add(dotsBottom);

    freeplayTitle = new FunkinText(0, -5, 0, "FREEPLAY", 64, true);
    freeplayTitle.font = Paths.font("vcr.ttf");
    freeplayTitle.borderStyle = FlxTextBorderStyle.OUTLINE;
    freeplayTitle.borderColor = 0xFF000000;
    freeplayTitle.borderSize = 4;
    freeplayTitle.antialiasing = Options.antialiasing;
    freeplayTitle.x = FlxG.width - freeplayTitle.width - 8;
    add(freeplayTitle);

    visBar = makeRect(1, 1, visualizerBarWidth, visualizerBarThickness, 0x95ffffff);
    visBar.origin.set(visualizerBarWidth, 0);
    add(visBar);

    customValuesText = new FunkinText(16, 16, FlxG.width * 0.33, "", 16, true);
    customValuesText.antialiasing = Options.antialiasing;
    customValuesText.alignment = "right";
    add(customValuesText);

    pbText = new FunkinText(16, 16, FlxG.width * 0.16, "", 16, true);
    pbText.antialiasing = Options.antialiasing;
    pbText.alignment = "right";
    add(pbText);

    songList = FreeplaySonglist.get();

    diffText = makeText(32, 96, "", 20);
    add(diffText);

    for (i in 0...songList.songs.length) {
        var back = makeSongBack(false);
        var selectedBack = makeSongBack(true);
        groupBacks.push(back);
        groupSelectedBacks.push(selectedBack);
        add(back);
        add(selectedBack);

        var text = makeSongText(0, i * gap, (songList.songs[i] == null ? "Random" : songList.songs[i].displayName));
        group.push(text);
        add(text);
    }

    spect = new AudioAnalyzer(FlxG.sound.music, 512);

    setFreeplayVisible(false);
    createCategoryMenu();
}

function setFreeplayVisible(visible:Bool) {
    for (item in group) item.visible = visible;
    for (item in groupBacks) item.visible = visible;
    for (item in groupSelectedBacks) item.visible = visible;
    diffText.visible = visible;
    customValuesText.visible = visible;
    pbText.visible = visible;
    freeplayTitle.visible = visible;
}

function createCategoryMenu() {
    clearCategoryMenu();

    for (i in 0...categoryNames.length) {
        var t = new FlxText(0, 220 + i * 60, 0, categoryNames[i]);
        t.setFormat(Paths.font("Electrolize.ttf"), 52, FlxColor.WHITE);
        t.screenCenter(FlxAxes.X);
        t.scrollFactor.set();
        add(t);
        categoryTexts.push(t);
    }

    skipCategoryText = new FlxText(0, FlxG.height - 86, FlxG.width, "Presiona E para cerrar este menu e ir directo al selector");
    skipCategoryText.setFormat(Paths.font("Electrolize.ttf"), 22, FlxColor.WHITE, "center");
    skipCategoryText.alpha = 0.75;
    skipCategoryText.scrollFactor.set();
    add(skipCategoryText);

    updateCategoryVisuals();
}

function returnToCategoryMenu() {
    trace("FreeplayState custom: returning to category hub");
    inCategoryMenu = true;
    isSelected = false;
    selectedDiff = 0;
    selectorInputLock = 0;
    categoryInputLock = 0.25;
    pendingSelectorOpen = false;
    pendingSelectorTarget = null;
    setFreeplayVisible(false);
    createCategoryMenu();
}

function clearCategoryMenu() {
    for (t in categoryTexts) {
        remove(t);
        t.kill();
    }
    categoryTexts = [];

    if (skipCategoryText != null) {
        remove(skipCategoryText);
        skipCategoryText.kill();
        skipCategoryText = null;
    }
}

function updateCategoryVisuals() {
    for (i in 0...categoryTexts.length) {
        categoryTexts[i].alpha = (i == categoryIndex) ? 1 : 0.35;
        categoryTexts[i].scale.set((i == categoryIndex) ? 1.15 : 1, (i == categoryIndex) ? 1.15 : 1);
        categoryTexts[i].screenCenter(FlxAxes.X);
    }
}

function enterSongSelector(targetCategory:String = null) {
    trace("FreeplayState custom: entering selector -> " + targetCategory);
    inCategoryMenu = false;
    isSelected = false;
    selectedDiff = 0;
    selectorInputLock = 0.35;
    categoryInputLock = 0;
    pendingSelectorOpen = false;
    pendingSelectorTarget = null;
    clearCategoryMenu();
    setFreeplayVisible(true);

    if (targetCategory != null) {
        for (i in 0...songList.songs.length) {
            if (songList.songs[i] != null && songList.songs[i].displayName == targetCategory) {
                selection = i;
                selectionY = selection * gap;
                return;
            }
        }

        trace("Categoria no encontrada en songList: " + targetCategory);
    }
}

var levels = [];
var cache:Array<Float> = [];
var analyzerTimeCache:Float = -1;
var numBars = 256;

function postDraw() {
    if (spect != null && FlxG.sound.music.playing) drawFourier();

    for (i in 0...levels.length - 1) {
        visBar.y = i * visualizerBarThickness;
        visBar.scale.x = Math.max(0.08, levels[i] * 4.75);
        visBar.x = FlxG.width - 18;
        visBar.origin.set(visualizerBarWidth, 0);
        visBar.draw();
    }
}

function drawFourier() {
    var time = FlxG.sound.music.time;
    if (analyzerTimeCache != time) {
        levels = spect.getLevels(analyzerTimeCache = time, 1, numBars, cache, CoolUtil.getFPSRatio(0.2), -30, 0, 100, 24000);
    }
}

function getSongBGPort(song) {
    if (song == null) return "";

    var jsonPort = getFreeplayBGPort(song.name);
    if (jsonPort != null) return jsonPort;

    if (song.customValues != null) {
        for (field in ["port", "bgPort", "freeplayBG", "background"]) {
            if (Reflect.hasField(song.customValues, field)) {
                var value = Std.string(Reflect.field(song.customValues, field));
                if (value != null && value.length > 0) return value;
            }
        }
    }

    return song.name;
}

function updateSongBackground() {
    if (songList == null || songList.songs[selection] == null) {
        songBG.alpha = 0;
        return;
    }

    var port = getSongBGPort(songList.songs[selection]);
    if (lastLoadedSongBG == port) return;

    lastLoadedSongBG = port;
    if (Assets.exists(Paths.image("freeplayBGs/" + port))) {
        songBG.loadGraphic(Paths.image("freeplayBGs/" + port));
        songBG.setGraphicSize(FlxG.width);
        songBG.updateHitbox();
        songBG.alpha = 0.55;
    } else {
        songBG.alpha = 0;
    }
}

function formatCaps(input) {
    var caps = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
    var temp = input.substring(1);

    for (c in caps) {
        temp = StringTools.replace(temp, c, " " + c);
    }

    return input.charAt(0).toUpperCase() + temp;
}

var playingInst = false;

var randomPeak = 0;
var randomDelta = 0;
var delayRandom = 0;
function preUpdate(elapsed:Float) {
    if (categoryInputLock > 0) categoryInputLock -= elapsed;
    if (selectorInputLock > 0) selectorInputLock -= elapsed;

    if (inCategoryMenu || selectorInputLock > 0 || pendingSelectorOpen) {
        controls.ACCEPT = false;
    }

    if (inCategoryMenu || selectorInputLock > 0 || pendingSelectorOpen) {
        controls.UP_P = false;
        controls.DOWN_P = false;
        controls.LEFT_P = false;
        controls.RIGHT_P = false;
        controls.BACK = false;
        controls.RESET = false;
        controls.SWITCHMOD = false;
    }

    if (!inCategoryMenu && (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.B || FlxG.keys.justPressed.BACKSPACE)) {
        trace("FreeplayState custom: raw ESC/BACKSPACE intercepted -> category hub");
        controls.BACK = false;
        controls.ACCEPT = false;
        CoolUtil.playMenuSFX(2);
        returnToCategoryMenu();
    }
}

function update(elapsed:Float) {
    if (!inCategoryMenu) {
        controls.BACK = false;

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.B || FlxG.keys.justPressed.BACKSPACE) {
            trace("FreeplayState custom: ESC/B in selector -> category hub");
            controls.ACCEPT = false;
            controls.BACK = false;
            CoolUtil.playMenuSFX(2);
            returnToCategoryMenu();
        }

        return;
    }

    var realAccept = controls.ACCEPT;
    controls.ACCEPT = false;
    controls.UP_P = false;
    controls.DOWN_P = false;
    controls.LEFT_P = false;
    controls.RIGHT_P = false;
    controls.BACK = false;

    if (categoryInputLock > 0) return;

    if (pendingSelectorOpen) {
        controls.ACCEPT = false;
        if (!FlxG.keys.pressed.ENTER && !FlxG.keys.pressed.SPACE && !FlxG.keys.pressed.E) {
            enterSongSelector(pendingSelectorTarget);
        }
        return;
    }

    if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W) {
        categoryIndex = (categoryIndex - 1 + categoryNames.length) % categoryNames.length;
        updateCategoryVisuals();
        CoolUtil.playMenuSFX(0);
    }

    if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S) {
        categoryIndex = (categoryIndex + 1) % categoryNames.length;
        updateCategoryVisuals();
        CoolUtil.playMenuSFX(0);
    }

    if (realAccept || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) {
        trace("FreeplayState custom: category accept queued -> " + categoryNames[categoryIndex]);
        CoolUtil.playMenuSFX(1);
        pendingSelectorOpen = true;
        pendingSelectorTarget = categoryNames[categoryIndex];
        categoryInputLock = 0.05;
        controls.ACCEPT = false;
        return;
    }

    if (FlxG.keys.justPressed.E) {
        trace("FreeplayState custom: category skip queued with E");
        CoolUtil.playMenuSFX(2);
        pendingSelectorOpen = true;
        pendingSelectorTarget = null;
        categoryInputLock = 0.05;
        controls.ACCEPT = false;
        return;
    }

    if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
        CoolUtil.playMenuSFX(2);
        FlxG.switchState(new MainMenuState());
    }
}

function postUpdate(delta) {
    if (inCategoryMenu) {
        return;
    }

    numBars = Std.int(FlxG.height / visualizerBarThickness);

    if (selectorInputLock > 0) {
        controls.ACCEPT = false;
        controls.BACK = false;
        return;
    }

    if (!isSelected) changeSelection((controls.DOWN_P ? 1 : 0) + (controls.UP_P ? -1 : 0) - FlxG.mouse.wheel, group);

    selectionY -= clefInterp(delta, selectionY, selection * gap - (isSelected ? FlxG.height / 2 * -1 + 10 : 0), 10);

    for (i in 0...group.length) {
        if (!transitioningOut) group[i].y = (FlxG.height / 2) + (i * gap) - selectionY;
        group[i].x -= clefInterp(delta, group[i].x, (selection == i ? (isSelected ? 32 : 64) : (isSelected ? 0 : 16)), 10);
        group[i].alpha = group[i].x / 32;

        groupBacks[i].x = group[i].x - 150;
        groupBacks[i].y = group[i].y;
        groupBacks[i].alpha = (selection == i ? 0 : 0.85) * Math.min(1, group[i].alpha);

        groupSelectedBacks[i].x = Math.min(-50, group[i].x - 150);
        groupSelectedBacks[i].y = groupBacks[i].y + ((groupBacks[i].height / 2) - (groupSelectedBacks[i].height / 2));
        groupSelectedBacks[i].alpha += ((selection == i ? 1 : 0) - groupSelectedBacks[i].alpha) * Math.min(1, delta * 10);
    }

    bg.color = (songList.songs[selection] == null ? 0xffffffff : songList.songs[selection].color);
    updateSongBackground();

    if (controls.RESET) {
        randomPeak = randomDelta = FlxG.random.int(0 - songList.songs.length - 2, songList.songs.length - 2);
        isSelected = true;
    }

    if (controls.SWITCHMOD && isSelected) {
        if (!playingInst) {
            menuSong_Seekhead = Conductor.songPosition;
            menuSong_Tempo = Conductor.bpm;
            menuSong_TimeSig = Conductor.beatsPerMeasure + " " + Conductor.stepsPerBeat;

            FlxG.sound.music.stop();
            FlxG.sound.music = FlxG.sound.load(Paths.inst(songList.songs[selection].name));
            FlxG.sound.music.play();
            Conductor.changeBPM(songList.songs[selection].bpm, songList.songs[selection].beatsPerMeasure, songList.songs[selection].stepsPerBeat);

            spect = new AudioAnalyzer(FlxG.sound.music, 512);
            analyzerTimeCache = -1;
        } else {
            FlxG.sound.music.stop();
            CoolUtil.playMenuSong();
            FlxG.sound.music.time = Conductor.songPosition = menuSong_Seekhead;
            Conductor.changeBPM(menuSong_Tempo, menuSong_TimeSig.split(" ")[0], menuSong_TimeSig.split(" ")[1]);

            spect = new AudioAnalyzer(FlxG.sound.music, 512);
            analyzerTimeCache = -1;
        }
        playingInst = !playingInst;
    }

    if (controls.ACCEPT) {
        CoolUtil.playMenuSFX(1);
        if (!isSelected) {
            if (songList.songs[selection] == null) {
                randomPeak = randomDelta = FlxG.random.int(0 - songList.songs.length - 2, songList.songs.length - 2);
                isSelected = true;
            } else {
                isSelected = true;
            }
        } else {
            PlayState.loadSong(songList.songs[selection].name, (songList.songs[selection].difficulties == null ? null : songList.songs[selection].difficulties[selectedDiff]), (modeNum == 1 || modeNum == 3), modeNum > 1);
            FlxG.switchState(new PlayState());
        }
    }

    if (randomDelta != 0) {
        delayRandom -= delta;
    }

    if (randomDelta != 0) {
        changeSelection(randomDelta, group);
        randomDelta = 0;
    }

    if (controls.BACK) {
        CoolUtil.playMenuSFX(2);
        returnToCategoryMenu();
        return;
    }

    if (group.length == 1) isSelected = true;

    if (isSelected && (songList.songs[selection] != null)) {
        if (songList.songs[selection].difficulties != null) changeDiff((controls.DOWN_P ? 1 : 0) + (controls.UP_P ? -1 : 0) - FlxG.mouse.wheel, songList.songs[selection].difficulties);

        if (selectedDiff > songList.songs[selection].difficulties.length - 1) selectedDiff = (songList.songs[selection].difficulties.length - 1);

        if (controls.LEFT_P) modeNum--;
        if (controls.RIGHT_P) modeNum++;

        if (songList.songs[selection].opponentModeAllowed && songList.songs[selection].coopAllowed) {
            if (modeNum > 3) modeNum = 0;
            if (modeNum < 0) modeNum = 3;
        } else if (songList.songs[selection].opponentModeAllowed && !songList.songs[selection].coopAllowed) {
            if (modeNum > 1) modeNum = 0;
            if (modeNum < 0) modeNum = 1;
        } else if (!songList.songs[selection].opponentModeAllowed && songList.songs[selection].coopAllowed) {
            if (modeNum == 1) modeNum = (lastModeNum < 1 ? 2 : 0);
            if (modeNum > 2) modeNum = 0;
            if (modeNum < 0) modeNum = 2;
        } else {
            modeNum = 0;
        }

        lastModeNum = modeNum;

        if (songList.songs[selection].difficulties != null && isSelected) {
            diffText.text = currentMode[modeNum] + "\n\n";
            for (i in songList.songs[selection].difficulties) {
                diffText.text += (songList.songs[selection].difficulties[selectedDiff] == i ? "> " : "| ") + i + "\n";
            }
        } else {
            diffText.text = "Normal";
        }
    }

    diffText.x -= clefInterp(delta, diffText.x, (isSelected ? 32 : 0), 10);
    diffText.alpha = (diffText.x / 32);

    if (songList.songs[selection] != null) {
        var hs = FunkinSave.getSongHighscore(songList.songs[selection].name, (songList.songs[selection].difficulties == null ? "normal" : songList.songs[selection].difficulties[selectedDiff]));
        pbText.text = "Personal Best\n" + (hs.score > 0 ? hs.score + "\n" + FlxStringUtil.formatMoney(hs.accuracy * 100, true, true) + "%\n" + (hs.misses == 0 ? "Full Combo" : hs.misses + (hs.misses > 1 ? " misses" : " miss")) +
                      "\n" + hs.date : "Unplayed");

        customValuesText.text = "Tempo\n" + songList.songs[selection].bpm +
                                "\n\nTime Signature\n" + songList.songs[selection].beatsPerMeasure + "/" + songList.songs[selection].stepsPerBeat +
                                "\n\n" + (songList.songs[selection].coopAllowed || songList.songs[selection].opponentModeAllowed ? (songList.songs[selection].opponentModeAllowed ? "Opponent Mode" : "\n\n") + (songList.songs[selection].coopAllowed ? "\nCo-op Mode" : "\n") : "") + "\n\n";
        if (songList.songs[selection].customValues != null) {
            var fields = Reflect.fields(songList.songs[selection].customValues);

            for (f in fields) {
                customValuesText.text += formatCaps(f) + "\n" + Reflect.field(songList.songs[selection].customValues, f) + "\n\n";
            }
        }
    } else {
        pbText.text = "";
    }

    customValuesText.x = FlxG.width - (diffText.alpha * 16) - customValuesText.width;
    customValuesText.alpha = diffText.alpha;

    pbText.x = FlxG.width - (diffText.alpha * 150) - 16 - pbText.width;
}

function destroy() {
    if (inst != null) inst.stop();
    if (!FlxG.sound.music.playing) CoolUtil.playMenuSong();
}
