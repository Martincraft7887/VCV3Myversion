import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;
import haxe.ds.IntMap;
var skinChanges:Array<Dynamic> = [];
public var uiPath:String = "game/";
public var uiSkinPrefix:String = "voiid/";
public var noteSkinPrefix:String = "voiid/";
public var healthBarPrefix:String = "voiid/";
var paperNoteShaders:IntMap<CustomShader> = new IntMap();
var paperBlueRGB:Array<Int> = [0xFF0B8DFF, 0xFFFFFFFF, 0xFF003777];
var paperRedRGB:Array<Int> = [0xFF9D322A, 0xFFFFE1DC, 0xFF4A120F];
var paperCyanRGB:Array<Int> = [0xFF66D9FF, 0xFFFFFFFF, 0xFF11627A];
var paperPurpleRGB:Array<Int> = [0xFFA866FF, 0xFFFFFFFF, 0xFF3A1D78];
var paperGrayRGB:Array<Int> = [0xFF808080, 0xFFFFFFFF, 0xFF202020];
var paperGoldRGB:Array<Int> = [0xFFD6A15A, 0xFFFFF1D4, 0xFF704115];
var paperGreenRGB:Array<Int> = [0xFF3FD578, 0xFFFFFFFF, 0xFF0F6132];
var paperLightPurpleRGB:Array<Int> = [0xFF8F4CDA, 0xFFFFFFFF, 0xFF32125C];
var paperLightBlueRGB:Array<Int> = [0xFF8ECBFF, 0xFFFFFFFF, 0xFF2A5D82];
var paperFallbackRGB:Array<Array<Int>> = [
	paperBlueRGB, paperRedRGB, paperCyanRGB, paperPurpleRGB,
	paperGrayRGB, paperGoldRGB, paperGreenRGB, paperLightPurpleRGB, paperLightBlueRGB
];
var paperPunchRGB:Array<Int> = [0xFF00A8FF, 0xFFFFFFFF, 0xFF003B91];
var paperBoxingPunchRGB:Array<Int> = [0xFF0052C8, 0xFFFFFFFF, 0xFF001B58];
var paperIconScale:Float = 0.66;

function normalizeNoteSkinPrefix(prefix:String):String {
	if (prefix == null || prefix == "" || prefix == "codename/")
		return "";
	return prefix;
}

function noteSkinPath(prefix:String):String {
	prefix = normalizeNoteSkinPrefix(prefix);
	if (prefix == "")
		return uiPath + "codename/notes/default";
	return uiPath + prefix + "notes/default";
}

function isPaperNoteSkin(prefix:String):Bool {
	return normalizeNoteSkinPrefix(prefix) == "paper/";
}

function create() {
	for (event in events)
	{
		if (event.name == "Change UI Skin") 
		{
			skinChanges.push({
				time: event.time,
				uiSkinPrefix: event.params[0],
				noteSkinPrefix: normalizeNoteSkinPrefix(event.params[1]),
				healthBarPrefix: event.params[2]
			});
		}
	}
	if (skinChanges.length > 0) {
		skinChanges.sort(function(a, b) {
			if(a.time < b.time) return -1;
			else if(a.time > b.time) return 1;
			else return 0;
		});

		if (skinChanges[0].time <= 0) {
			uiSkinPrefix = skinChanges[0].uiSkinPrefix;
			noteSkinPrefix = skinChanges[0].noteSkinPrefix;
			healthBarPrefix = skinChanges[0].healthBarPrefix;
		}
	}
}


function postCreate() {
	updateUI();
	scripts.call("onChangeHealthBar", [healthBarPrefix]);
	scripts.call("onPostChangeHealthBar", [healthBarPrefix]);
}
function onStrumCreation(event) {
	event.sprite = noteSkinPath(noteSkinPrefix);
	if (isPaperNoteSkin(noteSkinPrefix))
		applyPaperRGBShader(event.strum, event.strumID, true, event.player);
}
function onNoteHit(event) {
	// scores.hx handles Paper ratings. Keeping Codename's vanilla prefix active here
	// makes the engine prepare an extra Paper popup on every player hit.
}
function onNoteCreation(event) {
	if (skinChanges.length == 0) {
		if (event.noteSprite == 'game/notes/default') event.noteSprite = noteSkinPath(noteSkinPrefix);
		if (isPaperNoteSkin(noteSkinPrefix))
			applyPaperNoteShader(event.note, event.strumID, event.noteType, event.strumLineID);
	} else {
		var change = {
			time: 0,
			uiSkinPrefix: uiSkinPrefix,
			noteSkinPrefix: normalizeNoteSkinPrefix(noteSkinPrefix),
			healthBarPrefix: healthBarPrefix
		};
		for (c in skinChanges) {
			if (event.note.strumTime >= c.time) {
				change = c;
			} else {
				break;
			}
		}
		if (event.noteSprite == 'game/notes/default') event.noteSprite = noteSkinPath(change.noteSkinPrefix);
		if (isPaperNoteSkin(change.noteSkinPrefix))
			applyPaperNoteShader(event.note, event.strumID, event.noteType, event.strumLineID);
	}
}

function getNoteTypeWithoutCharacter(noteType) {
	if (noteType == null) return "";
	var nt = Std.string(noteType);
	if (!StringTools.contains(nt, "char[")) return nt;
	return nt.substring(0, nt.indexOf("char["));
}

function getColorValue(color:Int, channel:String):Int {
	return switch(channel) {
		case "g": (Std.int(color) >> 8) & 0xFF;
		case "b": Std.int(color) & 0xFF;
		default: (Std.int(color) >> 16) & 0xFF;
	}
}

function getColorArray(color:Int):Array<Float> {
	return [
		getColorValue(color, "r") / 255,
		getColorValue(color, "g") / 255,
		getColorValue(color, "b") / 255
	];
}

function getPaperKeyCount(strumLineID:Int):Int {
	try {
		if (strumLineKeyCounts != null && strumLineID >= 0 && strumLineID < strumLineKeyCounts.length)
			return Std.int(strumLineKeyCounts[strumLineID]);
	} catch(e:Dynamic) {}
	return 4;
}

function getPaperLaneRGB(keyCount:Int, id:Int):Array<Int> {
	var dir = Std.int(Math.abs(id));
	var palette:Array<Array<Int>>;
	switch(keyCount) {
		case 5:
			palette = [paperBlueRGB, paperRedRGB, paperGrayRGB, paperCyanRGB, paperPurpleRGB];
		case 6:
			palette = [paperBlueRGB, paperCyanRGB, paperPurpleRGB, paperGoldRGB, paperRedRGB, paperLightBlueRGB];
		case 7:
			palette = [paperBlueRGB, paperCyanRGB, paperPurpleRGB, paperGrayRGB, paperGoldRGB, paperRedRGB, paperLightBlueRGB];
		case 9:
			palette = [paperBlueRGB, paperRedRGB, paperCyanRGB, paperPurpleRGB, paperGrayRGB, paperGoldRGB, paperGreenRGB, paperLightPurpleRGB, paperLightBlueRGB];
		default:
			palette = [paperBlueRGB, paperRedRGB, paperCyanRGB, paperPurpleRGB];
	}
	return palette[dir % palette.length];
}

function getPaperRGBShader(id:Int, keyCount:Int):CustomShader {
	var shaderKey = (keyCount * 100) + Std.int(Math.abs(id));
	var rgb = getPaperLaneRGB(keyCount, id);
	var shader = paperNoteShaders.get(shaderKey);
	if (shader == null) {
		shader = new CustomShader("rgbShad");
		shader.red = getColorArray(rgb[0]);
		shader.green = getColorArray(rgb[1]);
		shader.blue = getColorArray(rgb[2]);
		shader.visible = true;
		paperNoteShaders.set(shaderKey, shader);
	}
	return shader;
}

function getPaperPunchShader():CustomShader {
	var shader = paperNoteShaders.get(100);
	if (shader == null) {
		shader = new CustomShader("rgbShad");
		shader.red = getColorArray(paperPunchRGB[0]);
		shader.green = getColorArray(paperPunchRGB[1]);
		shader.blue = getColorArray(paperPunchRGB[2]);
		shader.visible = true;
		paperNoteShaders.set(100, shader);
	}
	return shader;
}

function getPaperBoxingPunchShader():CustomShader {
	var shader = paperNoteShaders.get(101);
	if (shader == null) {
		shader = new CustomShader("rgbShad");
		shader.red = getColorArray(paperBoxingPunchRGB[0]);
		shader.green = getColorArray(paperBoxingPunchRGB[1]);
		shader.blue = getColorArray(paperBoxingPunchRGB[2]);
		shader.visible = true;
		paperNoteShaders.set(101, shader);
	}
	return shader;
}

function applyPaperNoteShader(sprite:Dynamic, id:Int, noteType:Dynamic, strumLineID:Int) {
	if (sprite == null) return;

	var nt = getNoteTypeWithoutCharacter(noteType);
	if (nt == "" || nt == "Default Note") {
		applyPaperRGBShader(sprite, id, false, strumLineID);
	} else if (nt == "Wiik3Punch") {
		sprite.shader = getPaperPunchShader();
	} else if (nt == "BoxingMatchPunch") {
		sprite.shader = getPaperBoxingPunchShader();
	} else {
		sprite.shader = null;
	}
}

function getPaperSplashShader(id:Int, strumLineID:Int, noteType:Dynamic):CustomShader {
	var nt = getNoteTypeWithoutCharacter(noteType);
	if (nt == "Wiik3Punch")
		return getPaperPunchShader();
	if (nt == "BoxingMatchPunch")
		return getPaperBoxingPunchShader();
	if (nt == "" || nt == "Default Note")
		return getPaperRGBShader(id, getPaperKeyCount(strumLineID));
	return null;
}

function applyPaperRGBShader(sprite:Dynamic, id:Int, isStrum:Bool, strumLineID:Int) {
	if (sprite == null) return;

	var keyCount = getPaperKeyCount(strumLineID);
	var rgb = getPaperLaneRGB(keyCount, id);
	if (isStrum) {
		var shader = new CustomShader("rgbShad");
		shader.red = getColorArray(rgb[0]);
		shader.green = getColorArray(rgb[1]);
		shader.blue = getColorArray(rgb[2]);
		shader.visible = true;
		sprite.shader = shader;
		try {
			sprite.animation.onFrameChange.add(function(animName:String, frameNumber:Int, frameIndex:Int) {
				if (sprite.shader != null)
					sprite.shader.visible = animName != "static";
			});
		} catch(e:Dynamic) {}
		return;
	}

	sprite.shader = getPaperRGBShader(id, keyCount);
}

function updateUI() {
	introSprites = [null, uiPath+uiSkinPrefix+'ready', uiPath+uiSkinPrefix+"set", uiPath+uiSkinPrefix+"go"];
	introSounds = [uiSkinPrefix+'intro3', uiSkinPrefix+'intro2', uiSkinPrefix+"intro1", uiSkinPrefix+"introGo"];
}
function updateNoteSkin() {
	for (strumLine in strumLines.members) {
		for (strum in strumLine.members) {
			var kc = getKeyCountIndex(strumLine.ID);
			strum.frames = Paths.getFrames(noteSkinPath(noteSkinPrefix));
			strum.antialiasing = true;
			strum.setGraphicSize(Std.int((strum.width * strumLineNoteScales[strumLine.ID] * strumLines.members[strumLine.ID].strumScale)));

			strum.animation.addByPrefix('static', multikeyStrumAnims[kc][strum.ID][0]);
			strum.animation.addByPrefix('pressed', multikeyStrumAnims[kc][strum.ID][2], 24, false);
			strum.animation.addByPrefix('confirm', multikeyStrumAnims[kc][strum.ID][1], 24, false);
			strum.updateHitbox();
			strum.animation.play("static");
			if (isPaperNoteSkin(noteSkinPrefix))
				applyPaperRGBShader(strum, strum.ID, true, strumLine.ID);
			else
				strum.shader = null;
			
		}
	}
}

function getCurrentCharacter(strumlineID:Int):Character {
	if (strumLines == null || strumLines.members == null || strumlineID < 0 || strumlineID >= strumLines.members.length) return null;

	var strumline = strumLines.members[strumlineID];
	if (strumline == null || strumline.characters == null || strumline.characters.length < 1) return null;

	return strumline.characters[0];
}

function refreshHealthBarColors() {
	var curDad = getCurrentCharacter(0);
	var curBF = getCurrentCharacter(1);
	var leftColor:Int = curDad != null && curDad.iconColor != null && Options.colorHealthBar ? curDad.iconColor : (PlayState.opponentMode ? 0xFF66FF33 : 0xFFFF0000);
	var rightColor:Int = curBF != null && curBF.iconColor != null && Options.colorHealthBar ? curBF.iconColor : (PlayState.opponentMode ? 0xFFFF0000 : 0xFF66FF33);
	healthBar.createFilledBar(leftColor, rightColor);
}

function resetHealthBarBasePosition() {
	if (healthBarBG == null) return;
	healthBarBG.y = FlxG.height * 0.9;
	healthBarBG.offset.set(0, 0);
}

function resetIconBaseLayout() {
	if (healthBar == null) return;

	for (icon in [iconP1, iconP2]) {
		if (icon == null) continue;
		icon.scale.set(1, 1);
		icon.updateHitbox();
		icon.y = healthBar.y - (icon.height / 2);
		icon.offset.set(0, 0);
	}
}

function resetVanillaScoreLayout() {
	if (healthBarBG == null) return;

	for (text in [scoreTxt, missesTxt, accuracyTxt]) {
		if (text == null) continue;
		text.x = healthBarBG.x + 50;
		text.y = healthBarBG.y + 30;
		text.fieldWidth = Std.int(healthBarBG.width - 100);
		text.size = 16;
		text.borderSize = 2;
	}
}

function onChangeHealthBar(prefix) {
	if (prefix == "") {
		healthBarBG.loadGraphic(Paths.image('game/healthBar'));
		healthBarBG.screenCenter(FlxAxes.X);
		healthBarBG.updateHitbox();
		resetHealthBarBasePosition();
		remove(healthBar);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, 
			FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), 
			PlayState.instance, 'health', 0, maxHealth);

		healthBar.scrollFactor.set();
		healthBar.updateHitbox();
		healthBar.offset.set(0, 0);

		refreshHealthBarColors();
		healthBar.cameras = [camHUD];

		insert(members.indexOf(healthBarBG)+1, healthBar);
		resetIconBaseLayout();
		resetVanillaScoreLayout();
	} else if (prefix == "voiid/") {

		healthBarBG.loadGraphic(Paths.image('game/voiid/healthBar'));
		healthBarBG.updateHitbox();
		healthBarBG.screenCenter(FlxAxes.X);
		resetHealthBarBasePosition();
		remove(healthBar);

		healthBar = new FlxBar(healthBarBG.x + 13, healthBarBG.y + 15, 
			FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(healthBarBG.width - 25), 23, 
			PlayState.instance, 'health', 0, maxHealth);

		healthBar.scrollFactor.set();
		healthBar.updateHitbox();
		healthBar.offset.set(0, 0);
		

		if (!downscroll) {
			healthBar.offset.y += 15;
			healthBarBG.offset.y += 15;
		} else {
			healthBar.offset.y -= 18;
			healthBarBG.offset.y -= 18;
			healthBarBG.offset.y -= 15;
		}


		refreshHealthBarColors();
		healthBar.cameras = [camHUD];

		insert(members.indexOf(healthBarBG)-1, healthBar);
		resetIconBaseLayout();
		resetVanillaScoreLayout();

	} else if (prefix == "greed/") {

		if (!downscroll) {
			healthBarBG.loadGraphic(Paths.image('game/voiid/GreedHealthBarUp'));
		} else {
			healthBarBG.loadGraphic(Paths.image('game/voiid/GreedHealthBarDown'));
		}

		healthBarBG.updateHitbox();
		healthBarBG.screenCenter(FlxAxes.X);
		resetHealthBarBasePosition();
		remove(healthBar);

		healthBar = new FlxBar(healthBarBG.x + 27, healthBarBG.y + 25,
			FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(healthBarBG.width - 52), 23,
			PlayState.instance, 'health', 0, maxHealth);

		healthBar.scrollFactor.set();
		healthBar.updateHitbox();
		healthBar.offset.set(0, 0);

		if (!downscroll) {
			healthBar.offset.y += 25;
			healthBarBG.offset.y += 55;
			healthBarBG.offset.x += 2;
		} else {
			healthBar.offset.y -= 20;
			healthBarBG.offset.y -= 45;
			healthBarBG.offset.x -= 1;
		}

		refreshHealthBarColors();
		healthBar.cameras = [camHUD];

		insert(members.indexOf(healthBarBG)-1, healthBar);
		resetIconBaseLayout();
		resetVanillaScoreLayout();
	} else if (prefix == "paper/") {

		healthBarBG.loadGraphic(Paths.image('game/paper/healthBarOverlay'));
		healthBarBG.updateHitbox();
		healthBarBG.screenCenter(FlxAxes.X);
		healthBarBG.y = downscroll ? 16 : FlxG.height - healthBarBG.height + 4;
		healthBarBG.offset.set(0, 0);
		remove(healthBar);

		healthBar = new FlxBar(healthBarBG.x + 65, healthBarBG.y + 54,
			FlxBarFillDirection.RIGHT_TO_LEFT, 829, 36,
			PlayState.instance, 'health', 0, maxHealth);

		healthBar.scrollFactor.set();
		healthBar.updateHitbox();
		healthBar.offset.set(0, 0);

		refreshHealthBarColors();
		healthBar.cameras = [camHUD];

		insert(members.indexOf(healthBarBG), healthBar);
		applyPaperHUDLayout();
	}
}

function applyPaperHUDLayout() {
	if (healthBarPrefix != "paper/" || healthBarBG == null || healthBar == null) return;

	healthBarBG.screenCenter(FlxAxes.X);
	var targetBGY = downscroll ? 16 : FlxG.height - healthBarBG.height + 4;
	if (healthBarBG.y != targetBGY)
		healthBarBG.y = targetBGY;

	var targetHealthX = healthBarBG.x + 65;
	var targetHealthY = healthBarBG.y + 54;
	if (healthBar.x != targetHealthX) healthBar.x = targetHealthX;
	if (healthBar.y != targetHealthY) healthBar.y = targetHealthY;

	if (iconP1 != null) {
		if (iconP1.scale.x != paperIconScale || iconP1.scale.y != paperIconScale) {
			iconP1.scale.set(paperIconScale, paperIconScale);
			iconP1.updateHitbox();
		}
		var targetIconP1X = healthBar.x + healthBar.width - (iconP1.width / 2);
		var targetIconP1Y = healthBarBG.y + 67 - (iconP1.height / 2);
		if (iconP1.x != targetIconP1X) iconP1.x = targetIconP1X;
		if (iconP1.y != targetIconP1Y) iconP1.y = targetIconP1Y;
	}
	if (iconP2 != null) {
		if (iconP2.scale.x != paperIconScale || iconP2.scale.y != paperIconScale) {
			iconP2.scale.set(paperIconScale, paperIconScale);
			iconP2.updateHitbox();
		}
		var targetIconP2X = healthBar.x - (iconP2.width / 2);
		var targetIconP2Y = healthBarBG.y + 67 - (iconP2.height / 2);
		if (iconP2.x != targetIconP2X) iconP2.x = targetIconP2X;
		if (iconP2.y != targetIconP2Y) iconP2.y = targetIconP2Y;
	}

	var textY = healthBarBG.y + (downscroll ? 105 : 107);
	for (text in [scoreTxt, missesTxt, accuracyTxt]) {
		if (text == null) continue;
		var textX = healthBarBG.x + 210;
		var textWidth = Std.int(healthBarBG.width - 420);
		if (text.y != textY) text.y = textY;
		if (text.x != textX) text.x = textX;
		if (text.fieldWidth != textWidth) text.fieldWidth = textWidth;
		if (text.size != 16) text.size = 16;
		if (text.borderSize != 1.5) text.borderSize = 1.5;
	}
}
function postUpdate(elapsed:Float) {
	applyPaperHUDLayout();
}
function onCharactersChanged(id, chars) {
	var curDad = getCurrentCharacter(0);
	var curBF = getCurrentCharacter(1);
	if (id == 0) {
		if (curDad != null) iconP2.setIcon(curDad.getIcon());
	} else if (id == 1) {
		if (curBF != null) iconP1.setIcon(curBF.getIcon());
	}
	refreshHealthBarColors();
	applyPaperHUDLayout();
}

function onEvent(e) {
	var event = e.event;
	if (event.name == "Change UI Skin") {
		if (event.params[0] != uiSkinPrefix) {
			uiSkinPrefix = event.params[0];
			updateUI();
		}
		if (event.params[1] != noteSkinPrefix) {
			noteSkinPrefix = normalizeNoteSkinPrefix(event.params[1]);
			updateNoteSkin();
		}
		if (event.params[2] != healthBarPrefix) {
			healthBarPrefix = event.params[2];
			scripts.call("onChangeHealthBar", [healthBarPrefix]);
			scripts.call("onPostChangeHealthBar", [healthBarPrefix]);
		}
	}
}
function onPostChangeMechanicBars(t) {
	if (t == "greed/") {
		if (!downscroll) {
			drainHPBar.offset.y += 25;
			lostHPBar.offset.y += 25;
		} else {
			drainHPBar.offset.y -= 20;
			lostHPBar.offset.y -= 20;
		}
	}
}
