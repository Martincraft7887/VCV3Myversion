import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.game.PlayState;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

var hudVisible:Bool = true;
var hudBase:FlxText;
var hudRating:FlxText;
var ratingCounterTxt:FlxText;
var msTxt:FlxText;
var scoreSkinPrefix:String = "voiid/";
var scoreSkinChanges:Array<Dynamic> = [];
var scoreGraphicCache:StringMap<Dynamic> = new StringMap();
var ratingSpritePool:Array<FlxSprite> = [];
var numberSpritePool:Array<FlxSprite> = [];
var scoreSpriteAssets:ObjectMap<FlxSprite, String> = new ObjectMap();
var resultsDirty:Bool = false;
var resultsSyncTimer:Float = 0;
var maxStoredHitDiffs:Int = 256;
var lastPaperScoreLayout:Bool = false;
var lastHudBaseText:String = "";
var lastHudRatingText:String = "";
var lastRatingCounterText:String = "";
var lastHudRatingColor:Int = -1;
var lastHudScore:Int = -999999;
var lastHudMisses:Int = -999999;
var lastHudAccuracy:Float = -999999;
var lastHudSkin:String = "";
var lastHudVisible:Bool = true;
var lastHudDownscroll:Bool = false;

var popupCombo:Int = 0;
var popupScale:Float = 0.5;
var popupSpacing:Int = 5;
var krazyWindowMs:Float = 25;
var fadeTimer:Float = 0;
var centerY:Float = FlxG.height * 0.5;

var countKrazy:Int = 0;
var countSick:Int = 0;
var countGood:Int = 0;
var countBad:Int = 0;
var countShit:Int = 0;
var lastHitDiffMs:Float = 0;
var totalAbsHitDiffMs:Float = 0;
var hitDiffCount:Int = 0;
var hitDiffs:Array<Float> = [];
var lastEngineMisses:Int = -1;
var lastHandledNote:Dynamic = null;
var lastHandledTime:Float = -999999;
var lastHandledDirection:Int = -1;
var cachedSideRatings:Bool = false;
var cachedRatingPopup:Bool = true;
var cachedComboPopup:Bool = true;
var cachedDisplayMs:Bool = false;
var cachedBiggerScoreText:Bool = false;
var cachedBiggerInfoText:Bool = false;

function create() {
	for (event in events) {
		if (event.name == "Change UI Skin") {
			scoreSkinChanges.push({
				time: event.time,
				scoreSkinPrefix: normalizeScoreSkinPrefix(event.params[0])
			});
		}
	}

	if (scoreSkinChanges.length > 0) {
		scoreSkinChanges.sort(function(a, b) {
			if(a.time < b.time) return -1;
			else if(a.time > b.time) return 1;
			else return 0;
		});

		if (scoreSkinChanges[0].time <= 0)
			scoreSkinPrefix = scoreSkinChanges[0].scoreSkinPrefix;
	}
}

function normalizeScoreSkinPrefix(prefix:String):String {
	if (prefix == null || prefix == "" || prefix == "codename/")
		return "";
	return prefix;
}

function scoreAssetPath(asset:String):String {
	if (scoreSkinPrefix == "")
		return "game/codename/score/" + asset;
	if (scoreSkinPrefix == "voiid/")
		return "game/score/" + asset;
	return "game/" + scoreSkinPrefix + "score/" + asset;
}

function getSkinRatingAsset(rating:String):String {
	if ((scoreSkinPrefix == "" || scoreSkinPrefix == "paper/") && rating == "krazy")
		return "marvelous";
	return rating;
}

function getScoreGraphic(asset:String):Dynamic {
	var path = scoreAssetPath(asset);
	var graphic = scoreGraphicCache.get(path);
	if (graphic == null) {
		graphic = Paths.image(path);
		scoreGraphicCache.set(path, graphic);
	}
	return graphic;
}

function cacheScoreSkin(prefix:String) {
	var oldPrefix = scoreSkinPrefix;
	scoreSkinPrefix = normalizeScoreSkinPrefix(prefix);
	var assets = ["sick", "good", "bad", "shit", "combo", "num0", "num1", "num2", "num3", "num4", "num5", "num6", "num7", "num8", "num9"];
	if (scoreSkinPrefix != "")
		assets.push("krazy");
	if (scoreSkinPrefix == "" || scoreSkinPrefix == "paper/")
		assets.push("marvelous");
	for (asset in assets) {
		try {
			var graphic = getScoreGraphic(asset);
			graphicCache.cache(graphic);
		} catch(e:Dynamic) {}
	}
	scoreSkinPrefix = oldPrefix;
}

function getSongName():String {
	try {
		if (PlayState.SONG != null && PlayState.SONG.meta != null && PlayState.SONG.meta.name != null)
			return Std.string(PlayState.SONG.meta.name).toLowerCase();
	} catch(e:Dynamic) {}

	if (curSong != null)
		return Std.string(curSong).toLowerCase();

	return "";
}

function isDisabledSong():Bool {
	return false;
}

function makeHudText(x:Float, y:Float, width:Float, size:Int):FlxText {
	var text = new FlxText(x, y, width, "");
	text.setFormat(Paths.font("Contb___.ttf"), size, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	text.borderSize = 2;
	text.borderQuality = 2;
	text.scrollFactor.set();
	text.cameras = [camHUD];
	return text;
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

function getRatingCameras():Array<Dynamic> {
	var camName = saveString("voiidRatingCamera", "hud").toLowerCase();
	switch(camName) {
		case "game": return [camGame];
		case "other":
			try {
				if (camOther != null)
					return [camOther];
			} catch(e:Dynamic) {}
			return [camHUD];
		default: return [camHUD];
	}
}

function applyPopupCamera(sprite:Dynamic) {
	if (sprite == null) return;
	sprite.cameras = getRatingCameras();
	sprite.scrollFactor.set();
}

function acquireScoreSprite(pool:Array<FlxSprite>, asset:String):FlxSprite {
	for (sprite in pool) {
		if (sprite != null && !sprite.visible) {
			prepareScoreSprite(sprite, asset);
			return sprite;
		}
	}

	var sprite = new FlxSprite();
	pool.push(sprite);
	add(sprite);
	prepareScoreSprite(sprite, asset);
	return sprite;
}

function prepareScoreSprite(sprite:FlxSprite, asset:String) {
	FlxTween.cancelTweensOf(sprite);
	FlxTween.cancelTweensOf(sprite.scale);

	var path = scoreAssetPath(asset);
	if (!scoreSpriteAssets.exists(sprite) || scoreSpriteAssets.get(sprite) != path) {
		sprite.loadGraphic(getScoreGraphic(asset));
		scoreSpriteAssets.set(sprite, path);
	}

	sprite.alpha = 1;
	sprite.visible = true;
	sprite.active = true;
	applyPopupCamera(sprite);
}

function releaseScoreSprite(sprite:FlxSprite) {
	if (sprite == null) return;
	FlxTween.cancelTweensOf(sprite);
	FlxTween.cancelTweensOf(sprite.scale);
	sprite.visible = false;
	sprite.active = false;
	sprite.alpha = 1;
}

function punchCenterScreen():Bool {
	return saveBool("voiidPunchCenterScreen", false);
}

function getMsY():Float {
	return centerY + 125;
}

function hideVanillaScore(ps:PlayState) {
	if (ps == null) return;

	if (ps.scoreTxt != null) ps.scoreTxt.visible = false;
	if (ps.missesTxt != null) ps.missesTxt.visible = false;
	if (ps.accuracyTxt != null) ps.accuracyTxt.visible = false;
}

function cancelVanillaRating(e) {
	if (e == null) return;

	e.showRating = false;
	e.displayRating = false;
	e.displayCombo = false;
	e.rating = e.rating;
}

function postCreate() {
	var ps = PlayState.instance;
	if (ps == null) return;

	cacheScoreSkin("");
	cacheScoreSkin("voiid/");
	cacheScoreSkin("paper/");
	hideVanillaScore(ps);

	cachedSideRatings = saveBool("voiidSideRatings", false);
	cachedRatingPopup = saveBool("voiidRatingPopup", true);
	cachedComboPopup = saveBool("voiidComboPopup", true);
	cachedDisplayMs = saveBool("voiidDisplayMs", false);
	cachedBiggerScoreText = saveBool("voiidBiggerScoreText", false);
	cachedBiggerInfoText = saveBool("voiidBiggerInfoText", false);

	var scoreSize = cachedBiggerScoreText ? 22 : 18;
	var infoSize = cachedBiggerInfoText ? 20 : 16;

	hudBase = makeHudText(0, FlxG.height - 30, 0, scoreSize);
	add(hudBase);

	hudRating = makeHudText(0, FlxG.height - 30, 0, scoreSize);
	add(hudRating);

	ratingCounterTxt = makeHudText(20, (FlxG.height / 2) - 70, 220, infoSize);
	ratingCounterTxt.visible = cachedSideRatings;
	add(ratingCounterTxt);

	msTxt = makeHudText(0, getMsY(), FlxG.width, infoSize);
	msTxt.alignment = "center";
	msTxt.visible = cachedDisplayMs;
	add(msTxt);

	hitDiffs = [];
	syncResultStats();
	updateRatingCounter();
}

function update(elapsed:Float) {
	if (isDisabledSong()) return;

	var ps = PlayState.instance;
	if (ps == null) return;

	hideVanillaScore(ps);
	updateScoreHud(ps);
	updateRatingCounterFromMisses(ps);
	syncDirtyResults(elapsed);

	if (ratingCounterTxt != null && cachedSideRatings) {
		ratingCounterTxt.visible = hudVisible;
	} else if (fadeTimer > 0 && ratingCounterTxt != null) {
		fadeTimer -= elapsed;
		if (fadeTimer <= 0)
			ratingCounterTxt.visible = false;
	}
}

function updateScoreHud(ps:PlayState) {
	if (hudBase == null || hudRating == null) return;

	var isPaper = scoreSkinPrefix == "paper/";
	var layoutChanged = lastPaperScoreLayout != isPaper || lastHudDownscroll != downscroll || lastHudSkin != scoreSkinPrefix || lastHudVisible != hudVisible;
	var valuesChanged = ps.songScore != lastHudScore || ps.misses != lastHudMisses || ps.accuracy != lastHudAccuracy || layoutChanged;
	if (!valuesChanged) return;

	lastHudScore = ps.songScore;
	lastHudMisses = ps.misses;
	lastHudAccuracy = ps.accuracy;
	lastHudSkin = scoreSkinPrefix;
	lastHudVisible = hudVisible;
	lastHudDownscroll = downscroll;

	var scoreStr = scoreSkinPrefix == "paper/" ? "SCORE: " + ps.songScore : "Score: " + ps.songScore;
	var missesStr = scoreSkinPrefix == "paper/" ? "MISSES: " + ps.misses : "Combo Breaks: " + ps.misses;
	var baseText:String;
	var ratingStr:String = "";

	if (ps.accuracy >= 0) {
		var accPercent = Math.round(ps.accuracy * 10000) / 100.0;
		baseText = scoreSkinPrefix == "paper/" ?
			scoreStr + " | " + missesStr + " | ACCURACY: " + accPercent + "% | RANK: " :
			scoreStr + " | " + missesStr + " | Accuracy: " + accPercent + "% | ";
		ratingStr = getRating(ps.accuracy);
		hudRating.visible = hudVisible;
	} else {
		baseText = scoreStr + " | " + missesStr;
		hudRating.visible = false;
	}

	if (hudBase.text != baseText)
		hudBase.text = baseText;
	if (hudRating.text != ratingStr)
		hudRating.text = ratingStr;

	var ratingColor = getRatingColor(ratingStr);
	if (lastHudRatingColor != ratingColor) {
		hudRating.color = ratingColor;
		lastHudRatingColor = ratingColor;
	}

	var totalWidth = hudBase.width + hudRating.width;
	var startX = (FlxG.width - totalWidth) / 2;
	hudBase.x = startX;
	hudRating.x = startX + hudBase.width;

	if (isPaper) {
		if (!lastPaperScoreLayout) {
			hudBase.size = 16;
			hudRating.size = 16;
		}
		hudBase.y = downscroll ? FlxG.height - 122 - hudBase.height : FlxG.height - 25;
		hudRating.y = hudBase.y;
		if (ratingCounterTxt != null && !lastPaperScoreLayout) {
			ratingCounterTxt.size = 20;
			ratingCounterTxt.borderSize = 2.5;
			ratingCounterTxt.x = 16;
			ratingCounterTxt.fieldWidth = 250;
		}
	} else {
		var scoreSize = cachedBiggerScoreText ? 22 : 18;
		hudBase.y = FlxG.height - 30;
		hudRating.y = hudBase.y;
		if (lastPaperScoreLayout) {
			hudBase.size = scoreSize;
			hudRating.size = scoreSize;
		}
		if (ratingCounterTxt != null && lastPaperScoreLayout) {
			ratingCounterTxt.size = cachedBiggerInfoText ? 20 : 16;
			ratingCounterTxt.borderSize = 2;
			ratingCounterTxt.x = 20;
			ratingCounterTxt.fieldWidth = 220;
		}
	}

	lastPaperScoreLayout = isPaper;
}

function updateRatingCounterFromMisses(ps:PlayState) {
	if (lastEngineMisses < 0)
		lastEngineMisses = ps.misses;

	if (ps.misses > lastEngineMisses) {
		popupCombo = 0;
		updateRatingCounter();
		showCounter();
	} else if (ps.misses < lastEngineMisses || (ratingCounterTxt != null && ratingCounterTxt.text == "")) {
		updateRatingCounter();
	}

	if (ps.misses != lastEngineMisses)
		lastEngineMisses = ps.misses;
}

function getRatingColor(r:String):Int {
	switch(r) {
		case "S++": return FlxColor.fromRGB(160, 0, 255);
		case "S+": return FlxColor.fromRGB(255, 0, 200);
		case "S": return FlxColor.fromRGB(210, 0, 255);
		case "A": return FlxColor.fromRGB(80, 140, 255);
		case "B": return FlxColor.fromRGB(60, 110, 255);
		case "C": return FlxColor.fromRGB(40, 80, 220);
		case "D": return FlxColor.fromRGB(25, 60, 180);
		case "E": return FlxColor.fromRGB(100, 100, 100);
		default: return FlxColor.WHITE;
	}
}

function getRating(acc:Float):String {
	if (acc >= 1) return "S++";
	else if (acc >= 0.98) return "S+";
	else if (acc >= 0.95) return "S";
	else if (acc >= 0.90) return "A";
	else if (acc >= 0.85) return "B";
	else if (acc >= 0.80) return "C";
	else if (acc >= 0.70) return "D";
	return "E";
}

function onEvent(e) {
	if (isDisabledSong() || e == null || e.event == null)
		return;

	if (e.event.name == "Change UI Skin") {
		scoreSkinPrefix = normalizeScoreSkinPrefix(e.event.params[0]);
		updateRatingCounter();
		return;
	}

	if (e.event.name != "Toggle Custom HUD")
		return;

	var params:Array = e.event.params;
	setCustomHudVisible(params[0]);
}

function setCustomHudVisible(visible:Bool) {
	var ps = PlayState.instance;
	hudVisible = visible;
	lastHudVisible = !visible;
	if (hudBase != null) hudBase.visible = visible;
	if (hudRating != null) hudRating.visible = visible;
	if (ratingCounterTxt != null) ratingCounterTxt.visible = visible && cachedSideRatings;
	if (msTxt != null) msTxt.visible = false;
	if (ps == null) return;
	if (ps.healthBar != null) ps.healthBar.visible = visible;
	if (ps.healthBarBG != null) ps.healthBarBG.visible = visible;
	if (ps.iconP1 != null) ps.iconP1.visible = visible;
	if (ps.iconP2 != null) ps.iconP2.visible = visible;
}

function onPlayerHit(e) {
	handleScoreHit(e);
}

function onNoteHit(e) {
	if (e == null || e.player != true) return;
	handleScoreHit(e);
}

function alreadyHandled(e):Bool {
	if (e == null || e.note == null) return false;
	if (lastHandledNote == e.note)
		return true;
	if (lastHandledTime == e.note.strumTime && lastHandledDirection == e.direction)
		return true;
	return false;
}

function markHandled(e) {
	if (e == null || e.note == null) return;
	lastHandledNote = e.note;
	lastHandledTime = e.note.strumTime;
	lastHandledDirection = e.direction;
}

function handleScoreHit(e) {
	if (isDisabledSong() || e == null) return;

	cancelVanillaRating(e);

	if (e.note != null && e.note.isSustainNote)
		return;
	if (alreadyHandled(e))
		return;
	markHandled(e);

	var rating:String = e.rating;
	if (rating == null)
		rating = "sick";

	var hitDiffMs:Float = 0;
	if (e.note != null) {
		hitDiffMs = Conductor.songPosition - e.note.strumTime;
		if (rating == "sick" && Math.abs(hitDiffMs) <= krazyWindowMs)
			rating = "krazy";
	}

	if (rating != "krazy" && rating != "sick" && rating != "good" && rating != "bad" && rating != "shit")
		rating = "sick";
	popupCombo++;
	lastHitDiffMs = hitDiffMs;
	totalAbsHitDiffMs += Math.abs(hitDiffMs);
	hitDiffCount++;
	hitDiffs.push(hitDiffMs);
	if (hitDiffs.length > maxStoredHitDiffs)
		hitDiffs.shift();
	showPopupRating(rating, popupCombo);
	showMsText(hitDiffMs);

	switch(rating) {
		case "krazy": countKrazy++;
		case "sick": countSick++;
		case "good": countGood++;
		case "bad": countBad++;
		case "shit": countShit++;
	}

	updateRatingCounter();
	resultsDirty = true;
	showCounter();
}

function onPlayerMiss(e) {}

function getShaderFloat(shader:Dynamic, name:String, fallback:Float = 0):Float {
	if (shader == null) return fallback;

	try {
		if (shader.data != null) {
			var parameter = Reflect.field(shader.data, name);
			if (parameter != null && parameter.value != null && parameter.value.length > 0) {
				var attributeValue = Std.parseFloat(Std.string(parameter.value[0]));
				if (!Math.isNaN(attributeValue)) return attributeValue;
			}
		}
		var value = Reflect.getProperty(shader, name);
		if (value == null) value = Reflect.field(shader, name);
		if (value == null) return fallback;

		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	} catch(e:Dynamic) {
		return fallback;
	}
}

function getVisualStrumCenterX(strum:Dynamic):Float {
	if (strum == null) return FlxG.width * 0.5;

	var center = strum.x + (strum.width * 0.5);
	var shader = Reflect.field(strum, "shader");

	if (shader != null) {
		var shaderCenter = getShaderFloat(shader, "screenX", Math.NaN);
		if (!Math.isNaN(shaderCenter))
			center = shaderCenter;

		try {
			var offset = scripts.call("getNoteModifierVisualOffsetX", [1, strum.ID, center]);
			if (offset != null)
				center += offset;
		} catch(e:Dynamic) {}
	}

	return center;
}

function getPlayerStrumlineCenterX():Float {
	try {
		var line = strumLines.members[1];
		if (line == null || line.members == null || line.members.length < 1)
			return FlxG.width * 0.5;

		var minX = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		for (strum in line.members) {
			if (strum == null) continue;

			var center = getVisualStrumCenterX(strum);
			var halfWidth = strum.width * 0.5;
			minX = Math.min(minX, center - halfWidth);
			maxX = Math.max(maxX, center + halfWidth);
		}

		if (minX != Math.POSITIVE_INFINITY && maxX != Math.NEGATIVE_INFINITY)
			return (minX + maxX) * 0.5;
	} catch(e:Dynamic) {}

	return FlxG.width * 0.5;
}

function showPopupRating(rating:String, combo:Int) {
	if (isDisabledSong()) return;

	var showRating = cachedRatingPopup;
	var showComboPopup = cachedComboPopup;
	if (!showRating && !showComboPopup)
		return;

	var centerX = FlxG.width * 0.5;

	if (showRating) {
		var ratingSprite:FlxSprite = acquireScoreSprite(ratingSpritePool, getSkinRatingAsset(rating));
		ratingSprite.scale.set(popupScale * 1.2, popupScale * 1.2);
		ratingSprite.updateHitbox();
		ratingSprite.x = centerX - (ratingSprite.width * 0.5);
		ratingSprite.y = centerY - (ratingSprite.height * 0.5);

		FlxTween.tween(ratingSprite, {
			'scale.x': popupScale,
			'scale.y': popupScale
		}, 0.08, {ease: FlxEase.backOut});

		FlxTween.tween(ratingSprite, {
			y: ratingSprite.y - 20
		}, 0.25, {
			startDelay: 0.4,
			ease: FlxEase.quadIn,
			onComplete: function(twn) {
				releaseScoreSprite(ratingSprite);
			}
		});
	}

	if (showComboPopup)
		showCombo(combo, centerY + 65, centerX);
}

function showCombo(value:Int, startY:Float, centerX:Float) {
	if (isDisabledSong()) return;

	var digits = Std.string(value).split("");
	var numbers:Array<FlxSprite> = [];

	for (d in digits) {
		var s = acquireScoreSprite(numberSpritePool, "num" + d);
		s.scale.set(popupScale, popupScale);
		s.updateHitbox();
		numbers.push(s);
	}

	var totalWidth:Float = 0;
	for (n in numbers)
		totalWidth += n.width + popupSpacing;
	totalWidth -= popupSpacing;

	var startX = centerX - (totalWidth * 0.5);
	for (n in numbers) {
		n.x = startX;
		n.y = startY;

		FlxTween.tween(n, {
			y: n.y + 20
		}, 0.25, {
			startDelay: 0.4,
			ease: FlxEase.quadIn,
			onComplete: function(twn) {
				releaseScoreSprite(n);
			}
		});

		startX += n.width + popupSpacing;
	}
}

function showMsText(diffMs:Float) {
	if (msTxt == null || !cachedDisplayMs || !hudVisible)
		return;

	FlxTween.cancelTweensOf(msTxt);
	var rounded = Math.round(diffMs * 10) / 10;
	msTxt.text = (rounded > 0 ? "+" : "") + rounded + "ms";
	msTxt.color = Math.abs(diffMs) <= krazyWindowMs ? FlxColor.fromRGB(190, 70, 255) : FlxColor.WHITE;
	msTxt.visible = true;
	applyPopupCamera(msTxt);
	msTxt.y = getMsY();

	FlxTween.tween(msTxt, {y: msTxt.y + 22}, 0.45, {
		startDelay: 0.2,
		ease: FlxEase.quadIn,
		onComplete: function(twn) {
			msTxt.visible = false;
		}
	});
}

function updateRatingCounter() {
	if (ratingCounterTxt == null) return;

	var nextText =
		(scoreSkinPrefix == "paper/" ?
			"SUPERB: " + countKrazy + "\n" +
			"SICK:  " + countSick + "\n" +
			"GOOD:  " + countGood + "\n" +
			"BAD:   " + countBad + "\n" +
			"SHOOT: " + countShit + "\n" +
			"MISSES: " + (PlayState.instance != null ? PlayState.instance.misses : 0)
		:
			"Krazy: " + countKrazy + "\n" +
			"Sick:  " + countSick + "\n" +
			"Good:  " + countGood + "\n" +
			"Bad:   " + countBad + "\n" +
			"Shit:  " + countShit + "\n" +
			"Skill Issues:  " + (PlayState.instance != null ? PlayState.instance.misses : 0));

	if (lastRatingCounterText != nextText) {
		ratingCounterTxt.text = nextText;
		lastRatingCounterText = nextText;
	}
}

function syncResultStats() {
	Reflect.setField(FlxG.save.data, "voiidResultSong", getSongName());
	Reflect.setField(FlxG.save.data, "voiidResultKrazy", countKrazy);
	Reflect.setField(FlxG.save.data, "voiidResultSick", countSick);
	Reflect.setField(FlxG.save.data, "voiidResultGood", countGood);
	Reflect.setField(FlxG.save.data, "voiidResultBad", countBad);
	Reflect.setField(FlxG.save.data, "voiidResultShit", countShit);
	Reflect.setField(FlxG.save.data, "voiidResultLastMs", lastHitDiffMs);
	Reflect.setField(FlxG.save.data, "voiidResultAvgMs", hitDiffCount <= 0 ? 0 : totalAbsHitDiffMs / hitDiffCount);
	Reflect.setField(FlxG.save.data, "voiidResultHitDiffs", hitDiffs);
}

function syncDirtyResults(elapsed:Float) {
	if (!resultsDirty) return;

	resultsSyncTimer += elapsed;
	if (resultsSyncTimer < 0.5) return;

	resultsSyncTimer = 0;
	resultsDirty = false;
	syncResultStats();
}

function destroy() {
	if (resultsDirty)
		syncResultStats();

	for (sprite in ratingSpritePool)
		releaseScoreSprite(sprite);
	for (sprite in numberSpritePool)
		releaseScoreSprite(sprite);
}

function showCounter() {
	if (ratingCounterTxt == null) return;

	if (!cachedSideRatings) {
		ratingCounterTxt.visible = false;
		return;
	}

	ratingCounterTxt.visible = true;
}
