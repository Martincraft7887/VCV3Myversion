import funkin.backend.scripting.ModState;
import funkin.backend.utils.CoolUtil;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.options.Options;
import funkin.options.OptionsMenu;
import funkin.backend.chart.Chart;
import funkin.backend.MusicBeatGroup;
import funkin.backend.utils.AudioAnalyzer;
import funkin.editors.ui.UIState;
import funkin.savedata.FunkinSave;
import funkin.game.HealthIcon;
import funkin.game.PlayState;
import haxe.Json;
import openfl.ui.MouseCursor;
import openfl.ui.Mouse;
import VCSongText;
using StringTools;

class SongItem extends FlxSprite {
	public var song:Dynamic;
	public var text:Dynamic;
	public var icon:HealthIcon;
	public var back:FlxSprite;
	public var selectedBack:FlxSprite;
	public var port:String;
	public var loadingScreen:String = "default";
	public var selected:Bool = false;
	public var lock:FlxSprite;
	public var locked:Bool = false;
	public var lockable:Bool = false;
	public var openingTimer:Float = 0;
	public var unlockFade:Float = 1;
	var cachedTextStyle:Bool = false;
	var originalTextShader:Dynamic = null;
	var originalTextColor:FlxColor = 0xFFFFFFFF;
	var originalTextBorder1:FlxColor = 0xFFFFFFFF;
	var originalTextBorder2:FlxColor = 0xFFFFFFFF;
	var originalTextString:String = null;
	var lockedTextShader:Dynamic = null;
	var originalChildShader:Dynamic = null;
	var originalChildColor:FlxColor = 0xFFFFFFFF;
	var originalChildBorder1:FlxColor = 0xFFFFFFFF;
	var originalChildBorder2:FlxColor = 0xFFFFFFFF;
	var originalChildString:String = null;
	var lockedChildShader:Dynamic = null;
	var scrambleTimer:Float = 0;
	var lastScrambleSeed:Int = -1;
	var scrambledTextFrames:Array<String> = null;
	var scrambledChildFrames:Array<String> = null;
	var lockedTextStyleApplied:Bool = false;
	var unlockedTextRestored:Bool = false;
	var hasLockAnchor:Bool = false;
	var lockAnchorOffsetX:Float = 0;
	var lockAnchorOffsetY:Float = 0;

	public var gmAlt:SongItem;
	public var showAlt:Bool = false;

	public var skipLerp = false;

	function cacheTextStyle() {
		if (cachedTextStyle || text == null) return;
		cachedTextStyle = true;
		originalTextShader = text.shader;
		originalTextColor = text.color;
		originalTextBorder1 = text.border1Color;
		originalTextBorder2 = text.border2Color;
		originalTextString = text.text;
		if (lock != null) {
			lockAnchorOffsetX = Math.min(text.width * 0.5, 310) - lock.width * 0.5;
			lockAnchorOffsetY = text.height * 0.5 - lock.height * 0.5;
			hasLockAnchor = true;
		}
		if (text.childText != null) {
			originalChildShader = text.childText.shader;
			originalChildColor = text.childText.color;
			originalChildBorder1 = text.childText.border1Color;
			originalChildBorder2 = text.childText.border2Color;
			originalChildString = text.childText.text;
		}
	}

	function makeLockedTextShader():Dynamic {
		var shader = new CustomShader("TextShader");
		shader.outerColorTop = [1.0, 1.0, 1.0];
		shader.outerColorBot = [1.0, 1.0, 1.0];
		shader.midColorTop = [1.0, 1.0, 1.0];
		shader.midColorBot = [1.0, 1.0, 1.0];
		shader.innerColorTop = [0.0, 0.0, 0.0];
		shader.innerColorBot = [0.0, 0.0, 0.0];
		shader.leftOuterColorTop = [1.0, 1.0, 1.0];
		shader.leftOuterColorBot = [1.0, 1.0, 1.0];
		shader.leftMidColorTop = [1.0, 1.0, 1.0];
		shader.leftMidColorBot = [1.0, 1.0, 1.0];
		shader.leftInnerColorTop = [0.0, 0.0, 0.0];
		shader.leftInnerColorBot = [0.0, 0.0, 0.0];
		shader.rightOuterColorTop = [1.0, 1.0, 1.0];
		shader.rightOuterColorBot = [1.0, 1.0, 1.0];
		shader.rightMidColorTop = [1.0, 1.0, 1.0];
		shader.rightMidColorBot = [1.0, 1.0, 1.0];
		shader.rightInnerColorTop = [0.0, 0.0, 0.0];
		shader.rightInnerColorBot = [0.0, 0.0, 0.0];
		shader.diagonalSplit = 0;
		shader.splitAngle = 45;
		shader.splitSoftness = 0.015;
		shader.splitOffset = 0;
		shader.strength = 0;
		shader.intensity = 0;
		shader.mixGap = 2.0;
		return shader;
	}

	function setLockedTextStyle(t:Dynamic, child:Bool = false) {
		if (t == null) return;
		if (child) {
			if (lockedChildShader == null) lockedChildShader = makeLockedTextShader();
			t.shader = lockedChildShader;
		} else {
			if (lockedTextShader == null) lockedTextShader = makeLockedTextShader();
			t.shader = lockedTextShader;
		}
		t.color = 0xFF00FF00;
		t.border1Color = 0xFFFFFFFF;
		t.border2Color = 0xFFFFFFFF;
	}

	function restoreTextStyle(t:Dynamic, shader:Dynamic, color:FlxColor, border1:FlxColor, border2:FlxColor) {
		if (t == null) return;
		t.shader = shader;
		t.color = color;
		t.border1Color = border1;
		t.border2Color = border2;
	}

	function scrambleText(src:String, seed:Int):String {
		if (src == null || src.length <= 1) return src;
		var chars = [];
		var letters = [];
		var positions = [];
		var fixed = [];
		var upper = src.toUpperCase();
		for (i in 0...src.length) fixed.push(false);
		var vipAt = upper.indexOf("VIP");
		while (vipAt >= 0) {
			for (i in vipAt...vipAt + 3) if (i >= 0 && i < fixed.length) fixed[i] = true;
			vipAt = upper.indexOf("VIP", vipAt + 3);
		}
		for (i in 0...src.length) {
			var ch = src.charAt(i);
			chars.push(ch);
			if (ch != " " && !fixed[i]) {
				positions.push(i);
				letters.push(ch);
			}
		}
		if (letters.length <= 1) return src;
		for (i in 0...letters.length) {
			var remaining = letters.length - i;
			var noise = Math.sin((seed + 1) * 12.9898 + (i + 3) * 78.233 + letters.length * 4.177) * 43758.5453;
			var j = i + (Std.int(Math.abs(noise)) % remaining);
			var tmp = letters[i];
			letters[i] = letters[j];
			letters[j] = tmp;
		}
		for (i in 0...positions.length) chars[positions[i]] = letters[i];
		return chars.join("");
	}

	function buildScrambleFrames(src:String, seedOffset:Int):Array<String> {
		var frames:Array<String> = [];
		if (src == null) return frames;
		var count = src.length > 28 ? 8 : (src.length > 16 ? 12 : 18);
		for (i in 0...count) frames.push(scrambleText(src, seedOffset + i));
		return frames;
	}

	function ensureScrambleFrames() {
		if (scrambledTextFrames == null)
			scrambledTextFrames = buildScrambleFrames(originalTextString, ID * 11);
		if (scrambledChildFrames == null && originalChildString != null && originalChildString != originalTextString)
			scrambledChildFrames = buildScrambleFrames(originalChildString, ID * 11 + 9);
	}

	function getScrambleFrame(frames:Array<String>, fallback:String, seed:Int):String {
		if (frames == null || frames.length <= 0) return fallback;
		return frames[Std.int(Math.abs(seed)) % frames.length];
	}

	function updateLockedTextScramble(elapsed:Float) {
		if (!lockable || !cachedTextStyle) return;
		if (!exists || !visible || !active || alpha <= 0.001) return;
		if (unlockFade > 0.01) {
			unlockedTextRestored = false;
			ensureScrambleFrames();
			scrambleTimer += elapsed;
			var seed = Std.int(scrambleTimer * (selected ? 13 : 8));
			if (seed == lastScrambleSeed) return;
			lastScrambleSeed = seed;
			var mainFrame = getScrambleFrame(scrambledTextFrames, originalTextString, seed);
			if (text != null) text.text = mainFrame;
			if (text != null && text.childText != null)
				text.childText.text = originalChildString == originalTextString ? mainFrame : getScrambleFrame(scrambledChildFrames, originalChildString, seed + 9);
		} else {
			if (unlockedTextRestored) return;
			lastScrambleSeed = -1;
			unlockedTextRestored = true;
			if (text != null && originalTextString != null) text.text = originalTextString;
			if (text != null && text.childText != null && originalChildString != null) text.childText.text = originalChildString;
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		text.update(elapsed);
		if (icon != null) icon.update(elapsed);
		if (lock != null) lock.update(elapsed);
		back.update(elapsed);
		selectedBack.update(elapsed);
		if (gmAlt != null) gmAlt.update(elapsed);
		if (openingTimer > 0) openingTimer -= elapsed;
		unlockFade = CoolUtil.fpsLerp(unlockFade, locked ? 1 : 0, 0.12);
		updateLockedTextScramble(elapsed);
	}
	override public function draw() {
		if (gmAlt != null) {
			gmAlt.y = y;
			gmAlt.selected = selected;
			gmAlt.draw();
		}

		text.scale.set(0.6, 0.6); text.updateHitbox();
		back.scale.set(0.7, 0.7); back.updateHitbox();
		selectedBack.scale.set(0.7, 0.7); selectedBack.updateHitbox();

		if (icon != null) {
			icon.scale.y = icon.scale.x = CoolUtil.fpsLerp(icon.scale.x, 0.7, skipLerp ? 1.0 : 0.06);
			icon.updateHitbox();
		}


		text.x = x - 36;
		text.y = y + 5;
		if (icon != null) {
			icon.x = -36 + x - icon.width;
			icon.y = y + ((back.height/2) - (icon.height/2));
		}
		if (lock != null) {
			lock.x = text.x + (hasLockAnchor ? lockAnchorOffsetX : Math.min(text.width * 0.5, 310) - lock.width * 0.5);
			lock.y = text.y + (hasLockAnchor ? lockAnchorOffsetY : text.height * 0.5 - lock.height * 0.5);
			lock.alpha = text.alpha;
			if (locked && openingTimer <= 0 && lock.animation.curAnim != null && lock.animation.curAnim.name != "idle")
				lock.animation.play("idle", true);
		}

		if (lockable) {
			cacheTextStyle();
			if (unlockFade > 0.01) {
				if (!lockedTextStyleApplied) {
					setLockedTextStyle(text);
					setLockedTextStyle(text.childText, true);
					lockedTextStyleApplied = true;
				}
			} else {
				if (lockedTextStyleApplied) {
					restoreTextStyle(text, originalTextShader, originalTextColor, originalTextBorder1, originalTextBorder2);
					restoreTextStyle(text.childText, originalChildShader, originalChildColor, originalChildBorder1, originalChildBorder2);
					lockedTextStyleApplied = false;
				}
				if (!unlockedTextRestored) {
					if (originalTextString != null) text.text = originalTextString;
					if (text.childText != null && originalChildString != null) text.childText.text = originalChildString;
					unlockedTextRestored = true;
				}
			}
		}
		if (icon != null)
			icon.color = lockable ? FlxColor.interpolate(0xFFFFFFFF, 0xFF000000, unlockFade) : 0xFFFFFFFF;

		back.x = x - 150;
		back.y = y;

		selectedBack.alpha = CoolUtil.fpsLerp(selectedBack.alpha, selected ? 1.0 : 0.0, skipLerp ? 1.0 : 0.1);
		back.alpha = CoolUtil.fpsLerp(back.alpha, selected ? 0.0 : 1.0, skipLerp ? 1.0 : 0.1);
		selectedBack.y = y + ((back.height/2) - (selectedBack.height/2));
		selectedBack.x = Math.min(-50, x);

		back.draw();
		selectedBack.draw();
		text.draw();
		if (lock != null && (locked || openingTimer > 0)) lock.draw();
		if (icon != null) icon.draw();

		skipLerp = false;

	}
	override public function destroy() {
		back.destroy();
		selectedBack.destroy();
		text.destroy();
		if (icon != null) icon.destroy();
		if (lock != null) lock.destroy();
		super.destroy();
		if (gmAlt != null) gmAlt.destroy();
	}
}

//list of all metadata
var songList = [];
var songCatData = [];
//list of text objects
var songItems = [];
//group of currently shown text objects
var songGroup:MusicBeatGroup;
var iconGroup:MusicBeatGroup;

var categories = ["" => []];
var catList:Array<String> = [];
var currentCategory:Int = 0;
var selectingCategory:Bool = true;
var categoryGroup:MusicBeatGroup;

static var lastCategory = -1;

var audioAnalyzer:AudioAnalyzer;
var audioBars = [];
var audioBarsTimer:Float = 0;
var audioBarsBaseY:Float = 720;
var bg:FlxSprite;
var songs = [];
var curSelected:Int = 0;
var curDifficulty:Int = 0;
var canSelect:Bool = false;
var songInstPlaying:Bool = true;
var autoplayElapsed:Float = 0;
var curPlayingInst:String = null;
var __coopMode:Bool = false;
var __opponentMode:Bool = false;
var inputLock:Float = 0.25;
var enableMouseSongHover:Bool = true;
var restoringSongSelectorOnCreate:Bool = false;
var pendingInstPreview:Bool = false;
var pendingInstPreviewTimer:Float = 0;
var instPreviewDelay:Float = 1.1;
var difficultySpriteAvailable:Bool = true;
var gloveHudWhite:FlxSprite = null;
var gloveHudPurple:FlxSprite = null;
var gloveHudWhiteText:VCSongText = null;
var gloveHudPurpleText:VCSongText = null;
var priceIcon:FlxSprite = null;
var priceText:VCSongText = null;
var priceIconCurrency:String = "";
var lockedReasonText:VCSongText = null;
var lastWhiteGloveText:String = "";
var lastPurpleGloveText:String = "";
var lastLockedReason:String = "";
var lockStaticTime:Float = 0;
var lockStaticStrength:Float = 0;
var unlockCache:Array<Dynamic> = [];
var priceCache:Array<Dynamic> = [];
var nextOfCache:Array<Dynamic> = [];
var gloveSaveField = "voiidGloveSave";
var whiteGloveField = "voiidWhiteGloves";
var purpleGloveField = "voiidPurpleGloves";

function create() {
	categories.clear();
	//var freeplaySongs = Json.parse(Assets.getText(Paths.getPath("data/freeplaySongs.json")));

	for (lib in Paths.assetsTree.libraries) {
		if (lib.exists(Paths.getPath("data/freeplaySongs.json"), "TEXT")) {
			var freeplaySongs = Json.parse(lib.getText(Paths.getPath("data/freeplaySongs.json")));
			loadFreeplaySongsJson(freeplaySongs);
		}
	}	

	buildPortFreeState();
}

function loadFreeplaySongsJson(freeplaySongs) {
	for (cat in freeplaySongs.categories) {
		for (song in cat.songs) {
			songList.push(Chart.loadChartMeta(song.name, "normal", true));
			songCatData.push(song);

			if (!categories.exists(cat.name)) {
				categories.set(cat.name, []);
				catList.push(cat.name);
			}

			categories.get(cat.name).push(songList.length-1);
		}
	}
}

var defaultSong = '
{
	"composer": "",
	"charter": "",
	"originalComposer": "",
	"startTime": 0,
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

var curScroll:Float = 0.0;

var dotsTop = null;
var dotsBottom = null;

var backButton = null;
var settingsButton = null;

var lastLoadedBGPort = "";
var bgSprite = null;
var emptyBGSprite = null;
var bgFade = null;
var bgFadeShader = null;
var bgFadeValue = 1;

var lastDiffLoaded = "";
var difficultySprite = null;
var diffArrowL = null;
var diffArrowR = null;
var difficultyText = null;

public static var SONG_SPEED = 1.0;
var selectedSongSpeed = 1;
var speedText = null;
var speedArrowL = null;
var speedArrowR = null;
var speedNameText = null;

var freeplayText = null;
var freeplayInfoText = null;

var highscoreNameText = null;
var highscoreTotalText = null;
var highscoreInfoText = null;

var currentHighscoreData = null;
var targetScore = ["", "", "", "", "", ""];
var currentScore = ["", "", "", "", "", ""];
var scoreTmr = 0.0;
var scoreIndex = 0;

function normalSongKey(name:String):String {
	if (name == null) return "";
	var key = Std.string(name).toLowerCase().trim();
	key = key.replace(" ", "");
	key = key.replace("-", "");
	key = key.replace("_", "");
	key = key.replace("'", "");
	key = key.replace("\"", "");
	return key;
}

function getGloveSave():Dynamic {
	var data = Reflect.field(FlxG.save.data, gloveSaveField);
	if (data == null) {
		data = {};
		Reflect.setField(FlxG.save.data, gloveSaveField, data);
	}
	for (field in [whiteGloveField, purpleGloveField, "voiidWhiteGlovesEarnedTotal", "voiidPurpleGlovesEarnedTotal"]) {
		var oldValue = Reflect.field(FlxG.save.data, field);
		if (oldValue != null && Reflect.field(data, field) == null)
			Reflect.setField(data, field, oldValue);
	}
	return data;
}

function getGloveInt(field:String):Int {
	var value = Reflect.field(getGloveSave(), field);
	if (value == null) return 0;
	var parsed = Std.parseInt(Std.string(value));
	return parsed == null ? 0 : parsed;
}

function setGloveInt(field:String, value:Int) {
	Reflect.setField(getGloveSave(), field, value);
	FlxG.save.flush();
}

function unlockField(songName:String):String {
	return "song_" + normalSongKey(songName);
}

function songCompleteField(songName:String):String {
	return "voiid_song_complete_" + normalSongKey(songName);
}

function getSongNameFromList(songName:String):String {
	var key = normalSongKey(songName);
	for (song in songList) {
		if (song == null) continue;
		if (normalSongKey(song.name) == key) return song.name;
		if (normalSongKey(song.displayName) == key) return song.name;
	}
	return songName;
}

function getSongDiffsFromList(songName:String) {
	var key = normalSongKey(songName);
	for (song in songList) {
		if (song == null) continue;
		if (normalSongKey(song.name) == key || normalSongKey(song.displayName) == key) {
			if (song.difficulties != null && song.difficulties.length > 0)
				return song.difficulties;
			break;
		}
	}
	return ["voiid", "normal", "hard"];
}

function isSongCompletedForUnlock(songName:String):Bool {
	if (songName == "") return true;
	if (Reflect.field(FlxG.save.data, songCompleteField(songName)) == true)
		return true;
	var metaName = getSongNameFromList(songName);
	if (Reflect.field(FlxG.save.data, songCompleteField(metaName)) == true)
		return true;
	if (Reflect.field(FlxG.save.data, "voiid_award_fc_" + Std.string(songName).toLowerCase()) == true)
		return true;
	if (Reflect.field(FlxG.save.data, "voiid_award_fc_" + normalSongKey(songName)) == true)
		return true;

	for (diff in getSongDiffsFromList(songName)) {
		var hs = FunkinSave.getSongHighscore(metaName, diff);
		if (hs != null && hs.score > 0)
			return true;
	}
	return false;
}

function parsePrice(song:Dynamic, fields:Array<String>):Int {
	if (song == null) return 0;
	var directFields = Reflect.fields(song);
	for (field in fields) {
		for (actual in directFields) {
			if (normalSongKey(actual) == normalSongKey(field)) {
				var parsed = Std.parseInt(Std.string(Reflect.field(song, actual)));
				if (parsed != null) return parsed;
			}
		}
	}
	return 0;
}

function freeplayMusicAutoPlay():Bool {
	return Reflect.field(FlxG.save.data, "voiidFreeplayMusic") != false;
}

function getGlobalSongIndex(index:Int):Int {
	try {
		if (songGroup != null && songGroup.members != null && index >= 0 && index < songGroup.members.length && songGroup.members[index] != null)
			return songGroup.members[index].ID;
	} catch(e:Dynamic) {}
	return index;
}

function getPriceData(index:Int):Dynamic {
	index = getGlobalSongIndex(index);
	if (index >= 0 && index < priceCache.length && priceCache[index] != null)
		return priceCache[index];
	if (index < 0 || index >= songCatData.length) return {price: 0, currency: "white"};
	var data = songCatData[index];
	var whitePrice = parsePrice(data, ["wg price", "white price", "white gloves", "white glove"]);
	var purplePrice = parsePrice(data, ["pg price", "pw glove", "purple price", "purple gloves", "purple glove"]);
	var result = {price: 0, currency: "white"};
	if (purplePrice > 0) result = {price: purplePrice, currency: "purple"};
	else if (whitePrice > 0) result = {price: whitePrice, currency: "white"};
	priceCache[index] = result;
	return result;
}

function getNextOf(index:Int):String {
	index = getGlobalSongIndex(index);
	if (index >= 0 && index < nextOfCache.length && nextOfCache[index] != null)
		return Std.string(nextOfCache[index]);
	if (index < 0 || index >= songCatData.length || songCatData[index] == null) return "";
	var data = songCatData[index];
	for (actual in Reflect.fields(data)) {
		if (normalSongKey(actual) == normalSongKey("next of")) {
			var result = Std.string(Reflect.field(data, actual));
			nextOfCache[index] = result;
			return result;
		}
	}
	nextOfCache[index] = "";
	return "";
}

function hasPendingNextOf(index:Int):Bool {
	var nextOf = getNextOf(index);
	return nextOf != "" && !isSongCompletedForUnlock(nextOf);
}

function isSongUnlockedByIndex(index:Int):Bool {
	var globalIndex = getGlobalSongIndex(index);
	if (globalIndex >= 0 && globalIndex < unlockCache.length && unlockCache[globalIndex] != null)
		return unlockCache[globalIndex] == true;

	if (hasPendingNextOf(index)) {
		if (globalIndex >= 0) unlockCache[globalIndex] = false;
		return false;
	}
	var priceData = getPriceData(index);
	if (priceData.price <= 0) {
		if (globalIndex >= 0) unlockCache[globalIndex] = true;
		return true;
	}
	if (globalIndex < 0 || globalIndex >= songList.length || songList[globalIndex] == null) return true;
	var save = getGloveSave();
	var unlocked = Reflect.field(save, unlockField(songList[globalIndex].name)) == true || Reflect.field(save, unlockField(songList[globalIndex].displayName)) == true;
	unlockCache[globalIndex] = unlocked;
	return unlocked;
}

function isStoryLockedByIndex(index:Int):Bool {
	return hasPendingNextOf(index);
}

function canBuySong(index:Int):Bool {
	if (hasPendingNextOf(index)) return false;
	var priceData = getPriceData(index);
	if (priceData.price <= 0 || isSongUnlockedByIndex(index)) return false;
	var field = priceData.currency == "purple" ? purpleGloveField : whiteGloveField;
	return getGloveInt(field) >= priceData.price;
}

function buySong(index:Int):Bool {
	if (!canBuySong(index)) return false;
	var visibleIndex = index;
	var globalIndex = getGlobalSongIndex(index);
	var priceData = getPriceData(index);
	var field = priceData.currency == "purple" ? purpleGloveField : whiteGloveField;
	setGloveInt(field, getGloveInt(field) - Std.int(priceData.price));
	Reflect.setField(getGloveSave(), unlockField(songList[globalIndex].name), true);
	Reflect.setField(getGloveSave(), unlockField(songList[globalIndex].displayName), true);
	if (globalIndex >= 0) unlockCache[globalIndex] = true;
	FlxG.save.flush();
	updateGloveHud();

	if (songGroup != null && songGroup.members[visibleIndex] != null) {
		var item:SongItem = songGroup.members[visibleIndex];
		item.locked = false;
		item.openingTimer = 1.25;
		if (item.lock != null) {
			item.lock.visible = true;
			item.lock.alpha = 1;
			item.lock.animation.play("open", true);
		}
	}
	CoolUtil.playMenuSFX(1, 0.7);
	return true;
}

function makeLockSprite(gold:Bool, ?story:Bool = false):FlxSprite {
	var lock = new FlxSprite();
	lock.frames = Paths.getSparrowAtlas(story ? "main menu/freeplay/Story" : (gold ? "main menu/freeplay/lockGold" : "main menu/freeplay/lock"));
	lock.animation.addByPrefix("idle", "lock0", 24, false);
	lock.animation.addByPrefix("open", "lock open", 30, false);
	lock.animation.play("idle", true);
	lock.setGraphicSize(58, 58);
	lock.updateHitbox();
	lock.antialiasing = true;
	return lock;
}

function makeGloveText(x:Float, y:Float, text:String, size:Int):VCSongText {
	var t = new VCSongText(x, y, 0, text);
	t.size = size;
	t.border1Size = 0;
	t.border2Size = 5;
	t.borderIterations = 8;
	t.border2Color = 0xFF000000;
	t.font = Paths.font("vcr.ttf");
	return t;
}

function createGloveHud() {
	var x = 82;
	var y = 70;

	gloveHudWhite = new FlxSprite(x, y).loadGraphic(Paths.image("main menu/freeplay/glove_white"));
	gloveHudWhite.setGraphicSize(42, 42);
	gloveHudWhite.updateHitbox();
	gloveHudWhite.antialiasing = true;
	add(gloveHudWhite);

	gloveHudWhiteText = makeGloveText(x + 46, y + 4, "0", 32);
	add(gloveHudWhiteText);

	gloveHudPurple = new FlxSprite(x + 150, y).loadGraphic(Paths.image("main menu/freeplay/glove_lean"));
	gloveHudPurple.setGraphicSize(42, 42);
	gloveHudPurple.updateHitbox();
	gloveHudPurple.antialiasing = true;
	add(gloveHudPurple);

	gloveHudPurpleText = makeGloveText(x + 196, y + 4, "0", 32);
	add(gloveHudPurpleText);

	priceIcon = new FlxSprite(1030, 182).loadGraphic(Paths.image("main menu/freeplay/glove_white"));
	priceIcon.setGraphicSize(58, 58);
	priceIcon.updateHitbox();
	priceIcon.color = 0xFF000000;
	priceIcon.antialiasing = true;
	insert(1001, priceIcon);

	priceText = makeGloveText(1092, 190, "", 36);
	priceText.color = 0xFF000000;
	priceText.border2Color = 0xFFFFFFFF;
	insert(1002, priceText);

	lockedReasonText = new VCSongText(0, 590, 0, "");
	lockedReasonText.color = 0xFFFFFFFF;
	lockedReasonText.border1Size = 0;
	lockedReasonText.border2Size = 5;
	lockedReasonText.borderIterations = 8;
	lockedReasonText.border2Color = 0xFF000000;
	lockedReasonText.font = Paths.font("vcr.ttf");
	lockedReasonText.size = 24;
	lockedReasonText.visible = false;
	insert(1002, lockedReasonText);

	updateGloveHud();
}

function updateGloveHud() {
	var whiteText = Std.string(getGloveInt(whiteGloveField));
	var purpleText = Std.string(getGloveInt(purpleGloveField));
	if (gloveHudWhiteText != null) {
		if (lastWhiteGloveText != whiteText) {
			lastWhiteGloveText = whiteText;
			gloveHudWhiteText.text = whiteText;
			gloveHudWhiteText.updateHitbox();
			if (gloveHudWhite != null) gloveHudWhiteText.y = gloveHudWhite.y + (gloveHudWhite.height * 0.5) - (gloveHudWhiteText.height * 0.5) - 1;
		}
	}
	if (gloveHudPurpleText != null) {
		if (lastPurpleGloveText != purpleText) {
			lastPurpleGloveText = purpleText;
			gloveHudPurpleText.text = purpleText;
			gloveHudPurpleText.updateHitbox();
			if (gloveHudPurple != null) gloveHudPurpleText.y = gloveHudPurple.y + (gloveHudPurple.height * 0.5) - (gloveHudPurpleText.height * 0.5) - 1;
		}
	}
}

function buildPortFreeState() {
	trace("PortFreeState: postCreate");
	FlxG.camera.scroll.set(0, 0);
	FlxG.camera.zoom = 1;
	FlxG.camera.angle = 0;

	if (lastCategory != -1) {
		currentCategory = lastCategory;
		selectingCategory = false;
		restoringSongSelectorOnCreate = true;
	}

	if (FlxG.sound.music == null || !FlxG.sound.music.playing) CoolUtil.playMenuSong();

	bg = new FlxSprite(0, 0);
	bg.loadGraphic(Paths.image('menus/freeplay/BG'));
	bg.setGraphicSize(1280); bg.updateHitbox();
	add(bg);

	var totalBars = 64;
	for (i in 0...totalBars) {
		var spr = new FlxSprite(((FlxG.width/totalBars)+5) * i, audioBarsBaseY);
		spr.makeGraphic(1,1);
		spr.setGraphicSize((FlxG.width/totalBars)-5, 1);
		spr.updateHitbox();
		spr.scrollFactor.set();
		audioBars.push(spr);
		add(spr);
	}

	////////////////////////////////////////

	bgFade = new FlxSprite(0, 156);
	bgFade.loadGraphic(Paths.image('menus/freeplay/bgfade')); add(bgFade);
	bgFade.scale.set(1280/1920,1280/1920); bgFade.updateHitbox();
	bgFade.x = 1280-bgFade.width;
	bgFade.shader = bgFadeShader = new CustomShader("BGFade");
	bgFadeShader.lockStaticTime = 0;
	bgFadeShader.lockStaticStrength = 0;

	bgSprite = new FlxSprite();
	//bgSprite.loadGraphic(Paths.image("menus/freeplay/bgs/Wiik1"));
	bgSprite.alpha = 0.001;
	add(bgSprite);

	emptyBGSprite = new FlxSprite();
	emptyBGSprite.makeGraphic(1,1,0xFF000000);
	emptyBGSprite.alpha = 0.001;
	add(emptyBGSprite);

	bgFadeShader.bg = emptyBGSprite.graphic.bitmap;
	bgFadeShader.prevBG = emptyBGSprite.graphic.bitmap;

	/////////////////////////////////////

	dotsTop = new FlxSprite();
	dotsTop.loadGraphic(Paths.image('menus/freeplay/dot_up')); add(dotsTop);
	dotsTop.setGraphicSize(1280); dotsTop.updateHitbox();

	dotsBottom = new FlxSprite();
	dotsBottom.loadGraphic(Paths.image('menus/freeplay/dot_down')); add(dotsBottom);
	dotsBottom.setGraphicSize(1280); dotsBottom.updateHitbox();

	///////////////////////////////////////////

	freeplayText = new VCSongText(0, -5, 0, "FREEPLAY");
	freeplayText.size = 64;
	freeplayText.border1Size = 0;
	freeplayText.border2Size = 5;
	freeplayText.borderIterations = 8;
	freeplayText.border2Color = 0xFF000000;
	freeplayText.font = Paths.font("vcr.ttf");

	freeplayText.x = 1280 - (freeplayText.width+5);
	add(freeplayText);

	freeplayInfoText = new VCSongText(150, 5, 0, "- LEFT and RIGHT to change difficulty | SHIFT + LEFT and RIGHT to change song speed");
	freeplayInfoText.size = 16;
	freeplayInfoText.border1Size = 0;
	freeplayInfoText.border2Size = 2;
	freeplayInfoText.borderIterations = 8;
	freeplayInfoText.border2Color = 0xFF000000;
	freeplayInfoText.font = Paths.font("vcr.ttf");
	add(freeplayInfoText);

	backButton = new FlxSprite(5, 0);
	backButton.loadGraphic(Paths.image('menus/freeplay/back_button'));
	backButton.scale.set(0.7,0.7); backButton.updateHitbox();
	add(backButton); backButton.antialiasing = true;

	settingsButton = null;
	createGloveHud();

	highscoreTotalText = new VCSongText(0, 0, 0, "000000");
	highscoreTotalText.border1Size = 0;
	highscoreTotalText.border2Size = 4;
	highscoreTotalText.borderIterations = 8;
	highscoreTotalText.border2Color = 0xFF000000;
	highscoreTotalText.font = Paths.font("digitalix.ttf");
	highscoreTotalText.size = 51;
	add(highscoreTotalText);
	highscoreTotalText.x = 1280 - highscoreTotalText.width;
	highscoreTotalText.y = 720 - highscoreTotalText.height;

	highscoreTotalText.shader = new CustomShader("FreeplayScoreText");

	highscoreNameText = new VCSongText(0, 0, 0, "HIGHSCORE");
	highscoreNameText.color = 0xFFFFFFFF;
	highscoreNameText.border1Size = 0;
	highscoreNameText.border2Size = 5;
	highscoreNameText.borderIterations = 8;
	highscoreNameText.border2Color = 0xFF000000;
	highscoreNameText.font = Paths.font("digitalix.ttf");
	highscoreNameText.size = 25;
	highscoreNameText.scale.set(0.72, 0.72); highscoreNameText.updateHitbox();
	add(highscoreNameText);

	highscoreNameText.x = 1280 - highscoreNameText.width;
	highscoreNameText.y = highscoreTotalText.y - highscoreNameText.height;
	highscoreNameText.y += 10;


	highscoreInfoText = new VCSongText(25, 568, 0, "[asdhjk]");
	highscoreInfoText.color = 0xFF6d4e80;
	highscoreInfoText.border1Size = 0;
	highscoreInfoText.border2Size = 5;
	highscoreInfoText.borderIterations = 8;
	highscoreInfoText.border2Color = 0xFF000000;
	highscoreInfoText.font = Paths.font("digitalix.ttf");
	highscoreInfoText.size = 25;
	highscoreInfoText.scale.set(0.72, 0.72); highscoreInfoText.updateHitbox();
	add(highscoreInfoText);
	highscoreInfoText.x = 1280 - highscoreInfoText.width;

	////////////////////////////////////////////

	songGroup = new MusicBeatGroup();
	insert(999,songGroup);

	categoryGroup = new MusicBeatGroup();
	insert(999,categoryGroup);
	for (obj in [priceIcon, priceText, lockedReasonText]) {
		if (obj != null) {
			remove(obj, true);
			add(obj);
		}
	}

	function createSongItem(index, songName, songIcon, metaData, port, loadingScreen, alt) {
		var data = null;
		if (Assets.exists("songs/"+songName+"/credits"+alt+".json")) {
			data = Json.parse(Assets.getText("songs/"+songName+"/credits"+alt+".json"));
		} else {
			data = Json.parse(defaultSong);
		}

		var songText = createSongText(songName, data.songFontSize, 16, data);
		
		songText.ID = index;
		var icon:HealthIcon = new HealthIcon(songIcon);
		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image("menus/freeplay/square_song"));
		bg.scale.set(0.9, 0.9); bg.updateHitbox();

		var selectedBG:FlxSprite = new FlxSprite();
		selectedBG.loadGraphic(Paths.image("menus/freeplay/square_song_selected"));
		selectedBG.scale.set(0.9, 0.9); selectedBG.updateHitbox();
		selectedBG.alpha = 0;

		songText.scale.set(0.6, 0.6);
		songText.updateHitbox();
		songText.centerOffsets();

		if (songText.width > 650) {
			songText.setGraphicSize(650);
			songText.updateHitbox();
			songText.centerOffsets();
		}

		var songItem = new SongItem();
		songItem.ID = index;
		songItem.song = metaData;
		songItem.text = songText;
		songItem.icon = icon;
		songItem.back = bg;
		songItem.selectedBack = selectedBG;
		songItem.port = port;
		var priceData = getPriceData(index);
		var storyLocked = getNextOf(index) != "" && priceData.price <= 0;
		if (priceData.price > 0 || storyLocked) {
			songItem.lock = makeLockSprite(priceData.currency == "purple", storyLocked);
			songItem.lockable = true;
			songItem.locked = !isSongUnlockedByIndex(index);
			songItem.unlockFade = songItem.locked ? 1 : 0;
		}
		if (loadingScreen != null) songItem.loadingScreen = loadingScreen;
		return songItem;
	}

	for (i in 0...songList.length)
	{
		var songItem = createSongItem(i, songList[i].displayName, songList[i].icon, songList[i], songCatData[i].port, songCatData[i].loadingScreen, "");

		if (songList[i].displayName == "Final Destination") {
			songItem.gmAlt = createSongItem(i, songList[i].displayName, "VoiidGodShagXMatt-icons", songList[i], "FDGOD", "default", "-god");
			songItem.gmAlt.x = -1280;
		}

		songItems.push(songItem);
	}

	//////////////////////////

	difficultySprite = new FlxSprite(0, 720);
	difficultySprite.loadGraphic(Paths.image("menus/freeplay/difficulties/voiid"));
	difficultySprite.scale.set(0.7, 0.7); difficultySprite.updateHitbox();
	difficultySprite.antialiasing = true;
	insert(999, difficultySprite);
	difficultySprite.y -= difficultySprite.height;
	difficultySprite.x = 25;

	difficultyText = new VCSongText(25, difficultySprite.y-24, 0, "DIFFICULTY");
	difficultyText.color = 0xFF6d4e80;
	difficultyText.border1Size = 0;
	difficultyText.border2Size = 5;
	difficultyText.borderIterations = 8;
	difficultyText.border2Color = 0xFF000000;
	difficultyText.font = Paths.font("digitalix.ttf");
	difficultyText.size = 25;
	difficultyText.scale.set(0.72, 0.72); difficultyText.updateHitbox();
	insert(999, difficultyText);

	difficultyText.x = difficultySprite.x + (difficultySprite.width/2) - (difficultyText.width/2);

	diffArrowL = new FlxSprite(0,0);
	diffArrowL.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	diffArrowL.antialiasing = true;
	diffArrowL.scale.set(0.85, 0.85); diffArrowL.updateHitbox();
	diffArrowL.x = difficultySprite.x - (diffArrowL.width/2);
	diffArrowL.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowL.height/2);
	insert(999, diffArrowL);

	diffArrowR = new FlxSprite(0,0);
	diffArrowR.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	diffArrowR.antialiasing = true;
	diffArrowR.flipX = true;
	diffArrowR.scale.set(0.85, 0.85); diffArrowR.updateHitbox();
	diffArrowR.x = (difficultySprite.width + difficultySprite.x) - (diffArrowR.width/2);
	diffArrowR.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowR.height/2);
	insert(999, diffArrowR);

	////////////////////////////////////

	speedNameText = new VCSongText(50+200, difficultyText.y, 0, "SONG SPEED");
	speedNameText.color = 0xFF6d4e80;
	speedNameText.border1Size = 0;
	speedNameText.border2Size = 5;
	speedNameText.borderIterations = 8;
	speedNameText.border2Color = 0xFF000000;
	speedNameText.font = Paths.font("digitalix.ttf");
	speedNameText.size = 25;
	speedNameText.scale.set(0.72, 0.72); speedNameText.updateHitbox();
	insert(999, speedNameText);


	speedText = new VCSongText(50, 0, 0, "1.0");
	speedText.color = 0xffffffff;
	speedText.border1Size = 0;
	speedText.border2Size = 5;
	speedText.borderIterations = 8;
	speedText.border2Color = 0xFF000000;
	speedText.font = Paths.font("digitalix.ttf");
	speedText.size = 25;
	speedText.scale.set(1, 1); speedText.updateHitbox();
	insert(999, speedText);

	speedText.x = 215 + difficultySprite.x + (difficultySprite.width/2) - (speedText.width/2);
	speedText.y = difficultySprite.y + (difficultySprite.height/2) - (speedText.height/2);
	speedNameText.x = speedText.x + (speedText.width/2) - (speedNameText.width/2);

	speedArrowL = new FlxSprite(0,0);
	speedArrowL.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	speedArrowL.antialiasing = true;
	speedArrowL.scale.set(0.85, 0.85); speedArrowL.updateHitbox();
	speedArrowL.x = -32 + speedText.x - (speedArrowL.width/2);
	speedArrowL.y = speedText.y + (speedText.height/2) - (speedArrowL.height/2);
	insert(999, speedArrowL);

	speedArrowR = new FlxSprite(0,0);
	speedArrowR.loadGraphic(Paths.image("menus/freeplay/left_arrow"));
	speedArrowR.antialiasing = true;
	speedArrowR.flipX = true;
	speedArrowR.scale.set(0.85, 0.85); speedArrowR.updateHitbox();
	speedArrowR.x = 32 + (speedText.width + speedText.x) - (speedArrowR.width/2);
	speedArrowR.y = speedText.y + (speedText.height/2) - (speedArrowR.height/2);
	insert(999, speedArrowR);



	///////////////////////////////////

	
	for (i => cat in catList) {
		var data = null;
		if (Assets.exists("data/freeplayCategories/"+cat+".json")) {
			data = Json.parse(Assets.getText("data/freeplayCategories/"+cat+".json"));
		} else {
			data = Json.parse(defaultSong);
		}

		var songText = createSongText(cat, data.songFontSize, 16, data);
		songText.ID = i;

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image("menus/freeplay/square_song"));
		bg.scale.set(0.9, 0.9); bg.updateHitbox();

		var selectedBG:FlxSprite = new FlxSprite();
		selectedBG.loadGraphic(Paths.image("menus/freeplay/square_song_selected"));
		selectedBG.scale.set(0.9, 0.9); selectedBG.updateHitbox();
		selectedBG.alpha = 0;

		songText.scale.set(0.6, 0.6);
		songText.updateHitbox();
		songText.centerOffsets();
		if (songText.width > 650) {
			songText.setGraphicSize(650);
			songText.updateHitbox();
			songText.centerOffsets();
		}

		var songItem = new SongItem();
		songItem.ID = i;
		songItem.text = songText;
		songItem.back = bg;
		songItem.selectedBack = selectedBG;
		songItem.port = "";
		
		categoryGroup.add(songItem);
	}

	loadCategory(catList[currentCategory]);

	for(k=>s in songs) {
		if (s.name == Options.freeplayLastSong) {
			curSelected = k;
		}
	}
	if (songs[curSelected] != null) {
		for(k=>diff in songs[curSelected].difficulties) {
			if (diff == Options.freeplayLastDifficulty) {
				curDifficulty = k;
			}
		}
	}
	curScroll = curSelected;
	if (curScroll < 1) curScroll = 1;
	if (curScroll > songGroup.members.length-2) curScroll = songGroup.members.length-2;
	changeDiff(0, true);
	updateSongGroup(curSelected);
	if (freeplayMusicAutoPlay()) playCurrentInstPreview();
	if (restoringSongSelectorOnCreate) {
		prepareSongIntroPositions();
		firstFrame = false;
	} else {
		// Only snap on a fresh state creation. Normal category/song navigation keeps its slide animation.
		snapMenuPositions();
	}
}

function loadCategory(name:String) {
	for (song in songGroup.members) {
		songGroup.remove(song);
	}
	songGroup.clear();
	songs = [];

	lastCategory = currentCategory;

	if (categories.exists(name)) {
		var list = categories.get(name);
		for (id in list) {
			songs.push(songList[id]);
			songGroup.add(songItems[id]);
			//songItems[id].x = 1280;
			songItems[id].selected = false;
		}
	}
	curSelected = FlxMath.wrap(curSelected, 0, songs.length-1);
	curScroll = curSelected;
	if (curScroll < 1) curScroll = 1;
	if (curScroll > songGroup.members.length-2) curScroll = songGroup.members.length-2;
	changeDiff(0, true);
	updateSongGroup(curSelected);
}

function playCurrentInstPreview() {
	if (songs == null || songs.length <= 0 || songs[curSelected] == null) return;
	if (!isSongUnlockedByIndex(curSelected)) {
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		curPlayingInst = null;
		audioAnalyzer = null;
		return;
	}

	var meta = songs[curSelected];
	var nextInst = meta.name + ":" + selectedSongSpeed;
	if (curPlayingInst == nextInst && FlxG.sound.music != null && FlxG.sound.music.playing) return;

	curPlayingInst = nextInst;
	if (FlxG.sound.music != null) FlxG.sound.music.stop();
	FlxG.sound.music = FlxG.sound.load(Paths.inst(meta.name));
	if (FlxG.sound.music != null) {
		FlxG.sound.music.play();
		FlxG.sound.music.pitch = selectedSongSpeed;
		Conductor.changeBPM(meta.bpm, meta.beatsPerMeasure, meta.stepsPerBeat);
		audioAnalyzer = new AudioAnalyzer(FlxG.sound.music);
	}
}

function queueInstPreview(?delay:Float = 0.55) {
	if (!freeplayMusicAutoPlay()) {
		pendingInstPreview = false;
		return;
	}
	if (!isSongUnlockedByIndex(curSelected)) {
		pendingInstPreview = false;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		return;
	}
	pendingInstPreview = true;
	pendingInstPreviewTimer = delay;
}

function changeSelection(change:Int = 0, ?force:Bool = false) {
	if (songs == null || songs.length <= 0) return;
	if (change == 0 && !force) return;

	curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
	curScroll = curSelected;
	if (curScroll < 1) curScroll = 1;
	if (curScroll > songGroup.members.length - 2) curScroll = songGroup.members.length - 2;
	if (change != 0) CoolUtil.playMenuSFX(0);

	changeDiff(0, true);
	updateSongGroup(curSelected);
	queueInstPreview(instPreviewDelay);
}

function changeDiff(change:Int = 0, ?force:Bool = false) {
	if (songs == null || songs.length <= 0 || songs[curSelected] == null) return;
	var diffs = songs[curSelected].difficulties;
	if (diffs == null || diffs.length <= 0) return;
	if (change == 0 && !force) {
		return;
	}

	curDifficulty = FlxMath.wrap(curDifficulty + change, 0, diffs.length - 1);
	if (change != 0) CoolUtil.playMenuSFX(0);
	refreshDifficultyVisual(curDifficulty);
	updateScores(curDifficulty);
}

function select() {
	if (songs == null || songs.length <= 0 || songs[curSelected] == null) return;

	var song = songs[curSelected];
	var diff = (song.difficulties == null || song.difficulties.length <= 0) ? "normal" : song.difficulties[curDifficulty];
	Options.freeplayLastSong = song.name;
	Options.freeplayLastDifficulty = diff;
	PlayState.loadSong(song.name, diff, __opponentMode, __coopMode);
	FlxG.switchState(new PlayState());
}

function openConfigMenu() {
	CoolUtil.playMenuSFX(1, 0.7);
	FlxG.switchState(new OptionsMenu(function(_) {
		FlxG.switchState(new ModState("PortFreeState"));
	}));
}

var songXPos = 2000;
var reloadCategory = false;
var firstFrame = true;

function getMinSongIndex() {return Math.max(0, curSelected-3);}
function getMaxSongIndex() {return songGroup == null ? 0 : Math.min(songGroup.members.length, curSelected+3);}

function snapMenuPositions() {
	if (songGroup != null) {
		songXPos = selectingCategory ? -1280 : 0;
		for (i in 0...songGroup.members.length) {
			var t = songGroup.members[i];
			if (t == null) continue;

			var p = (curScroll - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(curScroll - i) > 1) targetX = -1280;
			else if (curSelected - i == 0) targetX = 200;

			t.x = songXPos + targetX;
			t.y = targetY;
			t.selected = curSelected - i == 0;
		}
	}

	if (categoryGroup != null) {
		for (i in 0...categoryGroup.members.length) {
			var t = categoryGroup.members[i];
			if (t == null) continue;

			var p = (currentCategory - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(currentCategory - i) > 1) targetX = -1280;
			else if (currentCategory - i == 0) targetX = 200;
			if (!selectingCategory) targetX -= 1280;

			t.x = targetX;
			t.y = targetY;
			t.selected = currentCategory - i == 0;
		}
	}

	if (bgFade != null) bgFade.x = (1280 - bgFade.width) - songXPos;
}

function prepareSongIntroPositions() {
	songXPos = 2000;

	if (songGroup != null) {
		for (i in 0...songGroup.members.length) {
			var t = songGroup.members[i];
			if (t == null) continue;

			var p = (curScroll - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(curScroll - i) > 1) targetX = -1280;
			else if (curSelected - i == 0) targetX = 200;

			t.x = songXPos + targetX;
			t.y = targetY;
			t.selected = curSelected - i == 0;
		}
	}

	if (categoryGroup != null) {
		for (i in 0...categoryGroup.members.length) {
			var t = categoryGroup.members[i];
			if (t == null) continue;

			var p = (currentCategory - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			if (Math.abs(currentCategory - i) > 1) targetX = -1280;
			else if (currentCategory - i == 0) targetX = 200;

			t.x = targetX - 1280;
			t.y = targetY;
			t.selected = currentCategory - i == 0;
		}
	}

	if (bgFade != null) bgFade.x = (1280 - bgFade.width) - songXPos;
}

function postUpdate(elapsed) {
	updateSongInfoVisibility();

	if (pendingInstPreview) {
		pendingInstPreviewTimer -= elapsed;
		if (pendingInstPreviewTimer <= 0) {
			pendingInstPreview = false;
			playCurrentInstPreview();
		}
	}

	var skipLerp = firstFrame && !selectingCategory;

	songXPos = CoolUtil.fpsLerp(songXPos, selectingCategory ? -1280 : 0, skipLerp ? 60.0 : 0.07);
	if (bgFade != null) bgFade.x = (1280-bgFade.width)-songXPos;

	bgFadeValue = CoolUtil.fpsLerp(bgFadeValue, 0, 0.05);
	if (bgFadeShader != null) bgFadeShader.fade = bgFadeValue;

	for (i in getMinSongIndex()...getMaxSongIndex()) {
		var p = (curScroll - i) - 2;
		if (p < -3) p = -3;
		if (p > -1) p = -1;

		var t = songGroup.members[i];
		if (t == null) continue;

		var targetY = (-p * 136) + 38;
		var targetX = 150.0;
		var lerpSpeed = 0.2;
		if (Math.abs(curScroll - i) > 1) {
			targetX = -1280;
			lerpSpeed = 0.05;
		} else if (curSelected - i == 0) {
			targetX = 200;
		}

		var altTargetX = -1280;
		if (curSelected - i == 0 && (lastDiffLoaded.toLowerCase() == "god" || lastDiffLoaded.toLowerCase() == "god mania")) {
			t.showAlt = true;
			targetX = -1280;
			altTargetX = 200;
		} else {
			t.showAlt = false;
		}

		if (t.gmAlt != null) {
			t.gmAlt.x = CoolUtil.fpsLerp(t.gmAlt.x, songXPos + altTargetX, skipLerp ? 60.0 : lerpSpeed);
		}

		t.y = CoolUtil.fpsLerp(t.y, targetY, skipLerp ? 60.0 : 0.12);
		t.x = CoolUtil.fpsLerp(t.x, songXPos + targetX, skipLerp ? 60.0 : lerpSpeed);
		t.selected = curSelected - i == 0;
		t.locked = !isSongUnlockedByIndex(i);

		

	}

	updateLockAndPriceVisuals(elapsed);

	if (categoryGroup != null) {
		for (i in 0...categoryGroup.members.length) {
			var p = (currentCategory - i) - 2;
			if (p < -3) p = -3;
			if (p > -1) p = -1;

			var t = categoryGroup.members[i];
			if (t == null) continue;

			var targetY = (-p * 136) + 38;
			var targetX = 150.0;
			var lerpSpeed = 0.2;
			if (Math.abs(currentCategory - i) > 1) {
				targetX = -1280;
				lerpSpeed = 0.05;
			} else if (currentCategory - i == 0) {
				targetX = 200;
			}

			if (!selectingCategory) {
				targetX -= 1280;
			}

			
			t.y = CoolUtil.fpsLerp(t.y, targetY, skipLerp ? 60.0 : 0.12);
			t.x = CoolUtil.fpsLerp(t.x, targetX, skipLerp ? 60.0 : lerpSpeed);
			t.selected = currentCategory - i == 0;
		}
	}

	if (scoreIndex < targetScore.length) {
		scoreTmr += elapsed;
		if (scoreTmr > 0.05) {
			scoreTmr = 0;

			currentScore[scoreIndex] = targetScore[scoreIndex];

			var str = "";
			for (i in 0...currentScore.length) {
				str = str + currentScore[i];
			}

			if (highscoreTotalText != null) {
				highscoreTotalText.text = str;
				highscoreTotalText.x = 1280 - highscoreTotalText.width;
			}
			//var str = highscoreTotalText.text;

			//str[scoreIndex] = targetScore[scoreIndex];

			//highscoreTotalText.text = str;

			scoreIndex++;
		}
	}

	

	if (curPlayingInst != lastPlayedInst) {
		audioAnalyzer = null;
		if (FlxG.sound.music != null && FlxG.sound.music.playing && songs != null && songs.length > 0 && songs[curSelected] != null) {
			audioAnalyzer = new AudioAnalyzer(FlxG.sound.music);
			lastPlayedInst = curPlayingInst;
			var meta = songs[curSelected]; //update the bpm
			lastPlayedSongInst = meta.displayName;
			Conductor.changeBPM(meta.bpm, meta.beatsPerMeasure, meta.stepsPerBeat);
		}
	}
	if (FlxG.sound.music != null && FlxG.sound.music.playing) {
		FlxG.sound.music.pitch = selectedSongSpeed;
	}


	audioBarsTimer -= elapsed;
	var canAnalyzeAudio = audioAnalyzer != null && !selectingCategory && songs != null && songs.length > 0 && curSelected >= 0 && curSelected < songs.length && isSongUnlockedByIndex(curSelected);
	if (audioBarsTimer <= 0) {
		audioBarsTimer = 0.05;
		var l = 0;
		var n = 0;
		var time = (FlxG.sound.music != null) ? Math.floor(FlxG.sound.music.time/10)*10 : 0;
		for (i in 0...audioBars.length) {
			var spr = audioBars[i];
			
			n += 10 / audioBars.length;
			var v = canAnalyzeAudio ? audioAnalyzer.analyze(time + l, time + n) : 0;
			spr.scale.y = CoolUtil.fpsLerp(spr.scale.y, v * 250, 0.35);
			spr.y = audioBarsBaseY - spr.height;
			l = n;
		}
	}
		//var shit = Math.log(1 + (audioAnalyzer.analyze(Conductor.songPosition, Conductor.songPosition+1))) / Math.log(10);
		//var targetZoom = 1.0 + (shit);
		//FlxG.camera.zoom = CoolUtil.fpsLerp(FlxG.camera.zoom, targetZoom, 0.2);
		//trace(Conductor.songPosition + " : " + audioAnalyzer.analyze(Conductor.songPosition, Conductor.songPosition+1));

	if (reloadCategory) {
		loadCategory(catList[currentCategory]);
		reloadCategory = false;
	}

	firstFrame = false;
}

function updateLockAndPriceVisuals(elapsed:Float) {
	updateGloveHud();

	var locked = !selectingCategory && songs != null && songs.length > 0 && curSelected >= 0 && curSelected < songs.length && !isSongUnlockedByIndex(curSelected);
	var priceData = getPriceData(curSelected);
	var nextOf = getNextOf(curSelected);
	var storyLocked = locked && hasPendingNextOf(curSelected);

	if (lockedReasonText != null) {
		lockedReasonText.visible = storyLocked;
		if (storyLocked) {
			var reason = "Beat " + nextOf + " to unlock";
			if (lastLockedReason != reason) {
				lastLockedReason = reason;
				lockedReasonText.text = reason;
				lockedReasonText.updateHitbox();
				lockedReasonText.x = FlxG.width - lockedReasonText.width - 26;
			}
		} else {
			lastLockedReason = "";
		}
	}

	if (priceIcon != null && priceText != null) {
		priceIcon.visible = locked && priceData.price > 0;
		priceText.visible = priceIcon.visible;
		if (priceIcon.visible) {
			if (priceIconCurrency != priceData.currency) {
				priceIconCurrency = priceData.currency;
				priceIcon.loadGraphic(Paths.image(priceData.currency == "purple" ? "main menu/freeplay/glove_lean" : "main menu/freeplay/glove_white"));
				priceIcon.setGraphicSize(48, 48);
				priceIcon.updateHitbox();
			}
			priceIcon.color = 0xFFFFFFFF;
			priceText.text = Std.string(priceData.price);
			priceText.updateHitbox();
			var item:SongItem = songGroup != null && songGroup.members[curSelected] != null ? songGroup.members[curSelected] : null;
			if (storyLocked && lockedReasonText != null && lockedReasonText.visible) {
				var totalWidth = priceIcon.width + 8 + priceText.width;
				priceIcon.x = FlxG.width - totalWidth - 26;
				priceIcon.y = lockedReasonText.y + lockedReasonText.height + 8;
				priceText.x = priceIcon.x + priceIcon.width + 8;
				priceText.y = priceIcon.y + 5;
			} else if (item != null && item.lock != null) {
				priceIcon.x = Math.min(item.lock.x + item.lock.width + 10, FlxG.width - 170);
				priceIcon.y = item.lock.y + item.lock.height * 0.5 - priceIcon.height * 0.5;
				priceText.x = priceIcon.x + priceIcon.width + 8;
				priceText.y = priceIcon.y + 5;
			}
		}
	}

	if (bgFadeShader != null) {
		lockStaticTime += elapsed;
		var targetStrength = locked ? 1.0 : 0;
		lockStaticStrength = CoolUtil.fpsLerp(lockStaticStrength, targetStrength, locked ? 0.11 : 0.045);
		bgFadeShader.lockStaticTime = lockStaticTime;
		bgFadeShader.lockStaticStrength = lockStaticStrength;
	}
}

var lastPlayedInst:String = null;
var lastPlayedSongInst:String = "";

var hoveringThisFrame = false;

function updateSongInfoVisibility() {
	var showSongInfo = !selectingCategory;
	var lockedSong = showSongInfo && songs != null && songs.length > 0 && curSelected >= 0 && curSelected < songs.length && !isSongUnlockedByIndex(curSelected);
	showSongInfo = showSongInfo && !lockedSong;

	if (difficultySprite != null) difficultySprite.visible = showSongInfo && difficultySpriteAvailable;
	if (difficultyText != null) difficultyText.visible = showSongInfo;
	if (diffArrowL != null) diffArrowL.visible = showSongInfo && songs != null && songs.length > 0 && songs[curSelected] != null && songs[curSelected].difficulties != null && songs[curSelected].difficulties.length > 1;
	if (diffArrowR != null) diffArrowR.visible = diffArrowL != null && diffArrowL.visible;

	if (speedNameText != null) speedNameText.visible = showSongInfo;
	if (speedText != null) speedText.visible = showSongInfo;
	if (speedArrowL != null) speedArrowL.visible = showSongInfo;
	if (speedArrowR != null) speedArrowR.visible = showSongInfo;

	if (highscoreNameText != null) highscoreNameText.visible = showSongInfo;
	if (highscoreTotalText != null) highscoreTotalText.visible = showSongInfo;
	if (highscoreInfoText != null) highscoreInfoText.visible = showSongInfo;
}

function update(elapsed) {
	if (subState != null) {
		controls.ACCEPT = false;
		controls.BACK = false;
		return;
	}

	hoveringThisFrame = false;
	if (inputLock > 0) inputLock -= elapsed;

	if (songGroup == null || categoryGroup == null || catList == null || catList.length <= 0) {
		controls.ACCEPT = false;
		controls.BACK = false;
		return;
	}

	var freeplayAutoMusic = freeplayMusicAutoPlay();
	var pressedBack = controls.getJustPressed("back") || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.B || FlxG.mouse.justPressedRight;
	var pressedManualPreview = !freeplayAutoMusic && FlxG.keys.justPressed.SPACE;
	var pressedAccept = controls.getJustPressed("accept") || FlxG.keys.justPressed.ENTER || (freeplayAutoMusic && FlxG.keys.justPressed.SPACE);
	var pressedUp = controls.getJustPressed("up") || FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W;
	var pressedDown = controls.getJustPressed("down") || FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S;
	var pressedLeft = controls.getJustPressed("left") || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A;
	var pressedRight = controls.getJustPressed("right") || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D;

	var actualBACK = inputLock <= 0 && pressedBack;
	controls.BACK = false;
	var actualACCEPT = inputLock <= 0 && pressedAccept && !pressedManualPreview;
	controls.ACCEPT = false;

	canSelect = false;
	if (FlxG.mouse.justMoved) FlxG.mouse.visible = true;

	if (!selectingCategory) {
		changeSelection((pressedUp ? -1 : 0) + (pressedDown ? 1 : 0) - FlxG.mouse.wheel);
		if (FlxG.keys.pressed.SHIFT)
			changeSongSpeed((pressedLeft ? -0.1 : 0) + (pressedRight ? 0.1 : 0));
		else
			changeDiff((pressedLeft ? -1 : 0) + (pressedRight ? 1 : 0));

		if (enableMouseSongHover) for (i in getMinSongIndex()...getMaxSongIndex()) {
			var t = songGroup.members[i];

			if (t == null || t.back == null || t.text == null) continue;

			if (isMouseOverSprite(t.back) || isMouseOverSprite(t.text)) {

				hoveringThisFrame = true;
				if (FlxG.mouse.justPressed) {
					if (curSelected != i) {
						curSelected = i;
						var lastCurScroll = curScroll;
						changeSelection(0, true);
						curScroll = lastCurScroll;
					} else {
						actualACCEPT = true;
					}
				} 
			}
		}

		if (isClicked(diffArrowL)) changeDiff(-1);
		if (isClicked(diffArrowR)) changeDiff(1);
		if (isClicked(speedArrowL)) changeSongSpeed(-0.1);
		if (isClicked(speedArrowR)) changeSongSpeed(0.1);
		if (inputLock <= 0 && pressedManualPreview) {
			if (isSongUnlockedByIndex(curSelected)) {
				playCurrentInstPreview();
				inputLock = 0.12;
			} else {
				CoolUtil.playMenuSFX(2, 0.7);
				inputLock = 0.12;
			}
		}

	} else {
		var change = (pressedUp ? -1 : 0) + (pressedDown ? 1 : 0) - FlxG.mouse.wheel;
		if (change != 0) {
			currentCategory = FlxMath.wrap(currentCategory + change, 0, catList.length-1);
			CoolUtil.playMenuSFX(0, 0.7);
		}

		if (categoryGroup != null) for (i in 0...categoryGroup.members.length) {
			var t = categoryGroup.members[i];
			if (t == null || t.back == null || t.text == null) continue;

			if (isMouseOverSprite(t.back) || isMouseOverSprite(t.text)) {
				hoveringThisFrame = true;
				if (FlxG.mouse.justPressed) {
					if (currentCategory != i) {
						currentCategory = i;
						CoolUtil.playMenuSFX(0, 0.7);
					} else {
						actualACCEPT = true;
					}
				}
			}
		}
	}

	if (isClicked(backButton)) actualBACK = true;
	if (settingsButton != null && isClicked(settingsButton)) {
		openConfigMenu();
		return;
	}

	if (actualBACK) {
		if (selectingCategory) {
			trace("PortFreeState: BACK from categories -> MainMenu");
			CoolUtil.playMenuSFX(2, 0.7);
			FlxG.switchState(new MainMenuState());
		} else {
			trace("PortFreeState: BACK from songs -> categories");
			CoolUtil.playMenuSFX(2, 0.7);
			selectingCategory = true;
			songInstPlaying = true;
			lastCategory = -1;
			inputLock = 0.18;
		}
	}
	if (actualACCEPT) {
		if (selectingCategory) {
			trace("PortFreeState: ACCEPT category -> songs: " + catList[currentCategory]);
			CoolUtil.playMenuSFX(1, 0.7);
			selectingCategory = false;
			loadCategory(catList[currentCategory]);
			reloadCategory = false;
			autoplayElapsed = 0;
			songInstPlaying = false;
			inputLock = 0.18;
		} else {
			trace("PortFreeState: ACCEPT song -> PlayState");
			if (!isSongUnlockedByIndex(curSelected)) {
				if (!buySong(curSelected))
					CoolUtil.playMenuSFX(2, 0.7);
				inputLock = 0.18;
				return;
			}
			SONG_SPEED = selectedSongSpeed;
			if (songGroup != null && songGroup.members[curSelected] != null) CURRENT_LOADING_SCREEN = songGroup.members[curSelected].loadingScreen;
			select();
		}
	}

	Mouse.cursor = hoveringThisFrame ? MouseCursor.BUTTON : MouseCursor.ARROW;
}
function destroy() {
	Mouse.cursor = MouseCursor.ARROW;
}


function onChangeSelection(e) {
	

	updateSongGroup(e.value);
	curScroll = e.value;
	if (curScroll < 1) curScroll = 1;
	if (songGroup == null) return;
	if (curScroll > songGroup.members.length-2) curScroll = songGroup.members.length-2; 
}
var wasGM = false;
function getDifficultyImagePath(diffName:String):String {
	var cleanDiff = diffName == null ? "" : StringTools.trim(diffName).toLowerCase();
	var compactDiff = StringTools.replace(cleanDiff, " ", "");
	var basePath = "menus/freeplay/difficulties/";

	if (Paths.assetsTree.exists(Paths.getPath("images/" + basePath + cleanDiff + ".png"), "IMAGE") || Assets.exists(Paths.image(basePath + cleanDiff))) return basePath + cleanDiff;
	if (compactDiff != cleanDiff && (Paths.assetsTree.exists(Paths.getPath("images/" + basePath + compactDiff + ".png"), "IMAGE") || Assets.exists(Paths.image(basePath + compactDiff)))) return basePath + compactDiff;
	return null;
}

function reloadDifficultyGraphic(diffName:String) {
	var path = getDifficultyImagePath(diffName);

	if (path != null) {
		difficultySprite.loadGraphic(Paths.image(path));
		difficultySprite.scale.set(0.7, 0.7);
		difficultySprite.updateHitbox();
		difficultySpriteAvailable = true;
		difficultySprite.visible = !selectingCategory;

		diffArrowL.x = difficultySprite.x - (diffArrowL.width/2);
		diffArrowL.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowL.height/2);
		diffArrowR.x = (difficultySprite.width + difficultySprite.x) - (diffArrowR.width/2);
		diffArrowR.y = difficultySprite.y + (difficultySprite.height/2) - (diffArrowR.height/2);
		difficultyText.x = difficultySprite.x + (difficultySprite.width/2) - (difficultyText.width/2);
	} else {
		trace("PortFreeState: difficulty image not found -> " + diffName);
		difficultySpriteAvailable = false;
		difficultySprite.visible = false;
	}
}

function refreshDifficultyVisual(diffIndex:Int) {
	if (difficultySprite == null) return;

	var diffs = songs[curSelected].difficulties;
	if (diffs == null || diffs.length <= 0) return;
	diffIndex = FlxMath.wrap(diffIndex, 0, diffs.length - 1);

	if (lastDiffLoaded != diffs[diffIndex]) {
		lastDiffLoaded = diffs[diffIndex];
		reloadDifficultyGraphic(lastDiffLoaded);

		var isGod = (lastDiffLoaded.toLowerCase() == "god" || lastDiffLoaded.toLowerCase() == "god mania");
		if (wasGM != isGod) {
			wasGM = isGod;
			autoplayElapsed = 0;
			songInstPlaying = false;
			updateSongGroup(curSelected, isGod);
		}
	}

	updateSongInfoVisibility();
}

function onChangeDiff(e) {
	refreshDifficultyVisual(e.value);

	updateScores(e.value);
}
function updateSongGroup(v, ?doAlt = false) {
	if (doAlt == null) doAlt = false;

	if (songGroup == null) return;
	for (i in 0...songGroup.members.length) {
		var p = (v - i);
		
		var t = songGroup.members[i];
		if (t == null) continue;
		t.active = t.visible = true;
		if (p < -2) {
			t.selected = false;
			t.active = t.visible = false;
			t.x = -1280;
		} else if (p > 2) {
			t.selected = false;
			t.active = t.visible = false;
			t.x = -1280;
		}
	}

	if (songGroup.members[v] == null) return;
	var bgPort = songGroup.members[v].port;
	if (doAlt && songGroup.members[v].gmAlt != null) {
		bgPort = songGroup.members[v].gmAlt.port;
	}
	if (lastLoadedBGPort != bgPort) {
		lastLoadedBGPort = bgPort;
		if (bgFadeShader == null) return;
		bgFadeShader.prevBG = bgFadeShader.bg;
		bgFadeValue = 1;
		if (Assets.exists(Paths.image('freeplayBGs/'+bgPort))) {
			bgSprite.loadGraphic(Paths.image("freeplayBGs/"+bgPort));
			bgFadeShader.bg = bgSprite.graphic.bitmap;
		} else {
			bgFadeShader.bg = emptyBGSprite.graphic.bitmap;
		}
	}
}

function changeSongSpeed(change:Float) {
	if (change == 0) return;

	selectedSongSpeed += change;
	if (selectedSongSpeed < 0.5) selectedSongSpeed = 0.5;
	if (selectedSongSpeed > 2) selectedSongSpeed = 2;
	selectedSongSpeed = FlxMath.roundDecimal(selectedSongSpeed, 2);
	var display = selectedSongSpeed+"";
	if (display.indexOf(".") == -1) display += ".0";
	speedText.text = display;
}

function updateScores(diffValue) {
	if (songs == null || songs.length <= 0 || curSelected < 0 || curSelected >= songs.length || songs[curSelected] == null)
		return;

	var diffs = songs[curSelected].difficulties;
	if (diffs == null || diffs.length <= 0)
		return;
	if (diffValue < 0 || diffValue >= diffs.length)
		diffValue = 0;

	var changes:Array<HighscoreChange> = [];
	if (__coopMode) changes.push(HighscoreChange.CCoopMode);
	if (__opponentMode) changes.push(HighscoreChange.COpponentMode);
	currentHighscoreData = FunkinSave.getSongHighscore(songs[curSelected].name, diffs[diffValue], null, changes);
	//trace(saveData);

	var str = Std.string(currentHighscoreData.score);
	if (currentHighscoreData.score <= 0) str = "0";
	var visibleScore = highscoreTotalText != null ? highscoreTotalText.text : "";
	currentScore = [];
	var scoreLen:Int = Std.int(Math.max(targetScore.length, visibleScore.length));
	for (i in 0...scoreLen)
		currentScore.push("");
	var startDiff = currentScore.length - visibleScore.length;
	for (i in 0...visibleScore.length)
		currentScore[i + startDiff] = visibleScore.charAt(i);

	for (i in 0...targetScore.length) {
		targetScore[i] = "";
	}

	var diff = targetScore.length - str.length;
	for (i in 0...str.length) {
		if (diff > 0) {
			targetScore[i+diff] = str.charAt(i);
		} else {
			targetScore[i] = str.charAt(i);
		}
	}

	while (targetScore.length > currentScore.length) {
		currentScore.insert(0, "");
	}

	for (i in 0...targetScore.length) {
		if (targetScore[i] == "" && targetScore.length-i <= 6) {
			targetScore[i] = "0";
		}
	}
	
	scoreTmr = 0;
	scoreIndex = 0;

	var infoText:String = "[ ";
	infoText += diffs[diffValue].toUpperCase() + " - ";
	if (currentHighscoreData.score > 0) {
		infoText += (currentHighscoreData.misses == 0 ? "FC" : "CLEAR") + " - ";
		infoText += getRank(currentHighscoreData.accuracy);
	} else {
		infoText += "NOT CLEARED";
	}

	infoText += " ]";
	highscoreInfoText.text = infoText;
	highscoreInfoText.updateHitbox();
	highscoreInfoText.x = 1280 - highscoreInfoText.width;

	curDifficulty = diffValue;
}
var ranks = [
	[0, "F"],
	[0.5, "E"],
	[0.7, "D"],
	[0.8, "C"],
	[0.85, "B"],
	[0.9, "A"],
	[0.95, "S"],
	[1.0, "S++"]
];

function getRank(acc) {
	var rank = "F";
	for(e in ranks)
		if (e[0] <= acc)
			rank = e[1];

	return rank;
}

function beatHit() {
	if (songGroup != null && (Conductor.bpm < 200 || curBeat % 2 == 0)) {
		for (i in 0...songGroup.members.length) {
			var t = songGroup.members[i];
			if (t == null || t.song == null || t.icon == null) continue;
			if (t.song.displayName == lastPlayedSongInst) {
				t.icon.scale.x = 0.7*1.2;
				t.icon.scale.y = 0.7*1.2;
				if (t.gmAlt != null && t.gmAlt.icon != null) {
					t.gmAlt.icon.scale.x = 0.7*1.2;
					t.gmAlt.icon.scale.y = 0.7*1.2;
				}
			}
		}
	}
	//if (curBeat % 4 == 0) {

	//}

}


function isMouseOverSprite(obj:FlxSprite) {
	if (obj == null) return false;
	if (!obj.visible || !obj.exists) return false;
	var mx = FlxG.mouse.x;
	var my = FlxG.mouse.y;
	return mx >= obj.x && mx <= obj.x + obj.width && my >= obj.y && my <= obj.y + obj.height;
}

function isClicked(obj:FlxSprite) {
	var overlapping = isMouseOverSprite(obj);
	if (overlapping) {
		hoveringThisFrame = true;
	}
	return overlapping && FlxG.mouse.justPressed;
}
