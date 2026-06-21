import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.game.PlayState;

var disabledSongs = [
	"final destination vip",
	"rejected vip"
];

var hudVisible:Bool = true;
var hudBase:FlxText;
var hudRating:FlxText;
var ratingCounterTxt:FlxText;
var msTxt:FlxText;

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
	return disabledSongs.contains(getSongName());
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
	if (isDisabledSong()) {
		disableScript();
		return;
	}

	var ps = PlayState.instance;
	if (ps == null) return;

	hideVanillaScore(ps);

	var scoreSize = saveBool("voiidBiggerScoreText", false) ? 22 : 18;
	var infoSize = saveBool("voiidBiggerInfoText", false) ? 20 : 16;

	hudBase = makeHudText(0, FlxG.height - 30, 0, scoreSize);
	add(hudBase);

	hudRating = makeHudText(0, FlxG.height - 30, 0, scoreSize);
	add(hudRating);

	ratingCounterTxt = makeHudText(20, (FlxG.height / 2) - 70, 220, infoSize);
	ratingCounterTxt.visible = saveBool("voiidSideRatings", false);
	ratingCounterTxt.alpha = ratingCounterTxt.visible ? 0.8 : 0;
	add(ratingCounterTxt);

	msTxt = makeHudText(0, getMsY(), FlxG.width, infoSize);
	msTxt.alignment = "center";
	msTxt.visible = saveBool("voiidDisplayMs", false);
	msTxt.alpha = 0;
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

	if (ratingCounterTxt != null && saveBool("voiidSideRatings", false)) {
		ratingCounterTxt.visible = true;
		ratingCounterTxt.alpha = 0.8;
	} else if (fadeTimer > 0 && ratingCounterTxt != null) {
		fadeTimer -= elapsed;
		if (fadeTimer <= 0)
			FlxTween.tween(ratingCounterTxt, {alpha: 0}, 0.4);
	}
}

function updateScoreHud(ps:PlayState) {
	if (hudBase == null || hudRating == null) return;

	var scoreStr = "Score: " + ps.songScore;
	var missesStr = "Combo Breaks: " + ps.misses;
	var baseText:String;
	var ratingStr:String = "";

	if (ps.accuracy >= 0) {
		var accPercent = Math.round(ps.accuracy * 10000) / 100.0;
		baseText = scoreStr + " | " + missesStr + " | Accuracy: " + accPercent + "% | ";
		ratingStr = getRating(ps.accuracy);
		hudRating.visible = hudVisible;
	} else {
		baseText = scoreStr + " | " + missesStr;
		hudRating.visible = false;
	}

	hudBase.text = baseText;
	hudRating.text = ratingStr;
	hudRating.color = getRatingColor(ratingStr);

	var totalWidth = hudBase.width + hudRating.width;
	var startX = (FlxG.width - totalWidth) / 2;
	hudBase.x = startX;
	hudRating.x = startX + hudBase.width;
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
	if (isDisabledSong() || e == null || e.event == null || e.event.name != "Toggle Custom HUD")
		return;

	var ps = PlayState.instance;
	if (ps == null || hudBase == null || hudRating == null) return;

	var params:Array = e.event.params;
	hudVisible = params[0];
	var duration:Float = (Conductor.stepCrochet / 1000) * params[1];
	var targetAlpha:Float = hudVisible ? 1 : 0;

	if (hudVisible) {
		hudBase.visible = true;
		hudRating.visible = true;
		ps.healthBar.visible = true;
		ps.healthBarBG.visible = true;
		ps.iconP1.visible = true;
		ps.iconP2.visible = true;
	}

	FlxTween.tween(hudBase, {alpha: targetAlpha}, duration, {ease: FlxEase.quadOut});
	FlxTween.tween(hudRating, {alpha: targetAlpha}, duration, {ease: FlxEase.quadOut});
	FlxTween.tween(ps.healthBar, {alpha: targetAlpha}, duration, {ease: FlxEase.quadOut});
	FlxTween.tween(ps.healthBarBG, {alpha: targetAlpha}, duration, {ease: FlxEase.quadOut});
	FlxTween.tween(ps.iconP1, {alpha: targetAlpha}, duration, {ease: FlxEase.quadOut});
	FlxTween.tween(ps.iconP2, {alpha: targetAlpha}, duration, {
		ease: FlxEase.quadOut,
		onComplete: function(twn) {
			if (!hudVisible) {
				hudBase.visible = false;
				hudRating.visible = false;
				ps.healthBar.visible = false;
				ps.healthBarBG.visible = false;
				ps.iconP1.visible = false;
				ps.iconP2.visible = false;
			}
		}
	});
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
	syncResultStats();
	showCounter();
}

function onPlayerMiss(e) {}

function getShaderFloat(shader:Dynamic, name:String, fallback:Float = 0):Float {
	if (shader == null) return fallback;

	try {
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

	var showRating = saveBool("voiidRatingPopup", true);
	var showComboPopup = saveBool("voiidComboPopup", true);
	if (!showRating && !showComboPopup)
		return;

	var centerX = FlxG.width * 0.5;

	if (showRating) {
		var ratingSprite:FlxSprite = new FlxSprite();
		ratingSprite.loadGraphic(Paths.image("game/score/" + rating));
		applyPopupCamera(ratingSprite);
		ratingSprite.scale.set(popupScale * 1.2, popupScale * 1.2);
		ratingSprite.updateHitbox();
		ratingSprite.x = centerX - (ratingSprite.width * 0.5);
		ratingSprite.y = centerY - (ratingSprite.height * 0.5);
		ratingSprite.alpha = 0;
		add(ratingSprite);

		FlxTween.tween(ratingSprite, {
			alpha: 1,
			'scale.x': popupScale,
			'scale.y': popupScale
		}, 0.08, {ease: FlxEase.backOut});

		FlxTween.tween(ratingSprite, {
			y: ratingSprite.y - 20,
			alpha: 0
		}, 0.25, {
			startDelay: 0.4,
			ease: FlxEase.quadIn,
			onComplete: function(twn) {
				ratingSprite.destroy();
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
		var s = new FlxSprite();
		s.loadGraphic(Paths.image("game/score/num" + d));
		applyPopupCamera(s);
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
		n.alpha = 0;
		add(n);

		FlxTween.tween(n, {alpha: 1}, 0.08);
		FlxTween.tween(n, {
			y: n.y + 20,
			alpha: 0
		}, 0.25, {
			startDelay: 0.4,
			ease: FlxEase.quadIn,
			onComplete: function(twn) {
				n.destroy();
			}
		});

		startX += n.width + popupSpacing;
	}
}

function showMsText(diffMs:Float) {
	if (msTxt == null || !saveBool("voiidDisplayMs", false))
		return;

	FlxTween.cancelTweensOf(msTxt);
	var rounded = Math.round(diffMs * 10) / 10;
	msTxt.text = (rounded > 0 ? "+" : "") + rounded + "ms";
	msTxt.color = Math.abs(diffMs) <= krazyWindowMs ? FlxColor.fromRGB(190, 70, 255) : FlxColor.WHITE;
	msTxt.visible = true;
	msTxt.alpha = 1;
	applyPopupCamera(msTxt);
	msTxt.y = getMsY();

	FlxTween.tween(msTxt, {y: msTxt.y + 22, alpha: 0}, 0.45, {
		startDelay: 0.2,
		ease: FlxEase.quadIn
	});
}

function updateRatingCounter() {
	if (ratingCounterTxt == null) return;

	ratingCounterTxt.text =
		"Krazy: " + countKrazy + "\n" +
		"Sick:  " + countSick + "\n" +
		"Good:  " + countGood + "\n" +
		"Bad:   " + countBad + "\n" +
		"Shit:  " + countShit + "\n" +
		"Skill Issues:  " + (PlayState.instance != null ? PlayState.instance.misses : 0);
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

function showCounter() {
	if (ratingCounterTxt == null) return;

	if (!saveBool("voiidSideRatings", false)) {
		ratingCounterTxt.visible = false;
		return;
	}

	ratingCounterTxt.visible = true;
	ratingCounterTxt.alpha = 0.8;
}
