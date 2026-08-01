import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

var opponentAnimLocked:Bool = false;
var fistThrowTimer:FlxTimer = null;
var dadStartX:Float = 0;
var dadMoveTween:FlxTween = null;
var parryStrumsPrepared:Bool = false;
var parries:Array<Dynamic> = [];
var deadParries:Array<Dynamic> = [];
var parriesDirty:Bool = false;
var storedParryTimes:StringMap<Bool> = new StringMap();
var noteTypeCache:ObjectMap<Dynamic, Dynamic> = new ObjectMap();
var hasCachedNoteTypeVisuals:Bool = false;
var activeParry:Dynamic = null;
var parryAttack:FunkinSprite = null;
var flamePunch:FunkinSprite = null;
var parryAttackTween:FlxTween = null;
var flamePunchTween:FlxTween = null;
var dadParryAlpha:Float = 1;
var dadParryCharacter:String = "";
var parryAnimTime:Float = 583;
var punchLateHitTiming:Float = 150;
var bulletTracerCount:Int = 0;
var dadBulletShootTimer:FlxTimer = null;
var bulletTracerOffsetX:Float = 225;
var bulletTracerOffsetY:Float = -315;
public var noteTypeData = [
	"none" => null
];

function saveBool(name:String, fallback:Bool):Bool {
	var value = Reflect.field(FlxG.save.data, name);
	if (value == null) {
		Reflect.setField(FlxG.save.data, name, fallback);
		FlxG.save.flush();
		return fallback;
	}
	return value == true;
}

function noMechanicsEnabled():Bool {
	return saveBool("voiidNoMechanics", false);
}

function create() {
	if (noMechanicsEnabled()) return;

	scripts.call("registerNoteTypes", []);
	
	
}


function getNoteTypeWithoutCharacter(noteType) {
	if (noteType == null) return "";
	if (!StringTools.contains(noteType, "char[")) return noteType;
	return noteType.substring(0, noteType.indexOf("char["));
}

function isParryNoteData(data:Dynamic) {
	return data != null && Reflect.hasField(data, "parry") && data.parry == true;
}

function isBulletNoteData(data:Dynamic) {
	return data != null && Reflect.hasField(data, "bullet") && data.bullet == true;
}

function getNoteTypeSkin(data:Dynamic):String {
	if (data == null) return "";
	if (Reflect.field(FlxG.save.data, "voiidAltNoteTypeTextures") == true) {
		var altSkin = getAltNoteTypeSkin(data);
		if (altSkin != null && Std.string(altSkin) != "")
			return Std.string(altSkin);
	}
	return Std.string(data.skin);
}

function getAltNoteTypeSkin(data:Dynamic):Dynamic {
	var altSkin = Reflect.field(data, "skin-alt");
	if (altSkin == null)
		altSkin = Reflect.field(data, "skinAlt");
	if (altSkin == null)
		altSkin = Reflect.field(data, "skinalt");
	return altSkin;
}

function isUsingAltNoteTypeSkin(data:Dynamic):Bool {
	if (data == null || Reflect.field(FlxG.save.data, "voiidAltNoteTypeTextures") != true)
		return false;

	var altSkin = getAltNoteTypeSkin(data);
	return altSkin != null && Std.string(altSkin) != "";
}

function getNoteTypeOffsetArray(data:Dynamic, field:String):Dynamic {
	if (isUsingAltNoteTypeSkin(data)) {
		var value = Reflect.field(data, "alt" + field);
		if (value != null)
			return value;
	}

	return Reflect.field(data, field);
}

function getBoolField(data:Dynamic, field:String, fallback:Bool = false):Bool {
	var value = Reflect.field(data, field);
	return value == null ? fallback : value == true;
}

function shouldRotateNoteType(data:Dynamic):Bool {
	if (data == null || !getBoolField(data, "rotate")) return false;

	if (isUsingAltNoteTypeSkin(data)) {
		var rotateAlt = Reflect.field(data, "rotate-alt");
		if (rotateAlt == null)
			rotateAlt = Reflect.field(data, "rotateAlt");
		return rotateAlt == true;
	}

	return true;
}

function getNoteSingDirection(note):Int {
	var lane:Int = note.strumID;
	var kc:Int = getKeyCountIndex(note.strumLine.ID);

	if (multikeySingDirs != null && kc >= 0 && kc < multikeySingDirs.length) {
		var dirs = multikeySingDirs[kc];
		if (dirs != null && lane >= 0 && lane < dirs.length && dirs[lane] != null)
			return dirs[lane];
	}

	return lane % 4;
}

function getNoteRotationAngle(note):Float {
	return switch(getNoteSingDirection(note)) {
		case 0: 90;
		case 1: 0;
		case 2: 180;
		case 3: -90;
		default: 0;
	}
}

function applyNoteTypeRotation(note, data:Dynamic) {
	if (!shouldRotateNoteType(data) || note.isSustainNote) return;
	note.angle = getNoteRotationAngle(note);
}

function getArrayValue(values:Dynamic, index:Int):Dynamic {
	if (values == null || index < 0) return null;
	if (Reflect.hasField(values, "length") && index >= values.length) return null;
	return values[index];
}

function getCachedNoteData(note:Dynamic, fallbackNoteType:Dynamic = null):Dynamic {
	if (note != null && noteTypeCache.exists(note))
		return noteTypeCache.get(note).data;

	var noteType = fallbackNoteType;
	if (noteType == null && note != null)
		noteType = note.noteType;
	noteType = getNoteTypeWithoutCharacter(noteType);
	return noteTypeData.exists(noteType) ? noteTypeData.get(noteType) : null;
}

function cacheNoteTypeForNote(note:Dynamic, noteType:Dynamic) {
	if (note == null) return;

	var cleanType = getNoteTypeWithoutCharacter(noteType);
	if (!noteTypeData.exists(cleanType)) return;

	var data = noteTypeData.get(cleanType);
	var dir = getNoteSingDirection(note);
	var offsetX = getArrayValue(getNoteTypeOffsetArray(data, "offsetsX"), dir);
	var offsetY = getArrayValue(getNoteTypeOffsetArray(data, "offsetsY"), dir);
	var offsetYDS = getArrayValue(getNoteTypeOffsetArray(data, "offsetsYDS"), dir);
	var rotate = shouldRotateNoteType(data);
	if (offsetX != null || offsetY != null || offsetYDS != null || rotate)
		hasCachedNoteTypeVisuals = true;

	noteTypeCache.set(note, {
		data: data,
		dir: dir,
		offsetX: offsetX,
		offsetY: offsetY,
		offsetYDS: offsetYDS,
		rotate: rotate
	});

	if (isParryNoteData(data))
		storeParry(note.strumTime);
}

function applyCachedNoteTypeVisual(note:Dynamic) {
	if (note == null || note.isSustainNote || !noteTypeCache.exists(note)) return;

	var cached = noteTypeCache.get(note);
	if (cached.offsetX != null)
		note.x += cached.offsetX * 1.4285 * note.scale.x;

	var offsetY = downscroll ? cached.offsetYDS : cached.offsetY;
	if (offsetY != null)
		note.y += offsetY * 1.4285 * note.scale.y;

	if (cached.rotate == true)
		note.angle = getNoteRotationAngle(note);
}

function hasStoredParry(time:Float) {
	if (storedParryTimes.exists(getParryKey(time)))
		return true;
	for (parry in parries)
		if (Math.abs(parry.time - time) < 1)
			return true;
	for (parry in deadParries)
		if (Math.abs(parry.time - time) < 1)
			return true;
	return false;
}

function getParryKey(time:Float):String {
	return Std.string(Math.round(time));
}

function storeParry(time:Float) {
	if (hasStoredParry(time)) return;
	storedParryTimes.set(getParryKey(time), true);

	parries.push({
		time: time,
		started: false,
		punched: false,
		closed: false,
		baseStrums: []
	});
	parriesDirty = true;
}

function sortParriesIfNeeded() {
	if (!parriesDirty) return;
	parriesDirty = false;
	parries.sort(function(a, b) {
		if (a.time < b.time) return -1;
		else if (a.time > b.time) return 1;
		else return 0;
	});
}

function getPlayerKeyCount() {
	if (strumLineKeyCounts != null && strumLineKeyCounts.length > 1)
		return strumLineKeyCounts[1];
	return strumLines.members[1].members.length;
}

function getParryCenterID(keyCount:Int) {
	return keyCount == 5 ? 2 : (keyCount == 7 ? 3 : -1);
}




function setupParrySprites() {
	if (noMechanicsEnabled()) return;
	if (parries.length < 1 || parryAttack != null) return;

	flamePunch = new FunkinSprite();
	flamePunch.frames = Paths.getSparrowAtlas("FireGlove");
	flamePunch.animation.addByPrefix("FireGlove", "FireGlove", 24, true);
	flamePunch.animation.play("FireGlove");
	flamePunch.antialiasing = true;
	flamePunch.alpha = 0;
	flamePunch.shader = dad.shader;
	insert(members.indexOf(dad) + 1, flamePunch);

	parryAttack = new FunkinSprite();
	parryAttack.frames = Paths.getSparrowAtlas("characters/WIIK_3_THROW");
	parryAttack.animation.addByPrefix("fistThrow", "Matt Attack FistThrow", 24, false);
	parryAttack.antialiasing = true;
	parryAttack.alpha = 0;
	parryAttack.shader = dad.shader;
	insert(members.indexOf(dad) + 1, parryAttack);

}

function getMattParryX() {
	return dad.x - 420;
}

function getMattParryY() {
	return dad.y - 440;
}


function startParry(parry:Dynamic) {
	if (noMechanicsEnabled()) return;
	if (activeParry != null || parry.started || parryAttack == null) return;
	activeParry = parry;
	parry.started = true;
	opponentAnimLocked = true;

	parryAttack.animation.play("fistThrow", true);
	parryAttack.alpha = 1;
	parryAttack.x = getMattParryX();
	parryAttack.y = getMattParryY();
	dadParryAlpha = dad.alpha;
	dadParryCharacter = dad.curCharacter;
	if (dad.curCharacter == "Wiik3VoiidMatt")
		dad.alpha = 0.5;
	else
		parryAttack.alpha = 0.5;

	if (parryAttackTween != null) parryAttackTween.cancel();
	parryAttackTween = FlxTween.tween(parryAttack, {x: getMattParryX() - 450}, parryAnimTime * 0.001, {ease: FlxEase.cubeOut});
}

function punchParry(parry:Dynamic) {
	if (noMechanicsEnabled()) return;
	if (parry.punched || flamePunch == null || parryAttack == null) return;
	parry.punched = true;

	flamePunch.alpha = 1;
	flamePunch.x = parryAttack.x - 150;
	flamePunch.y = parryAttack.y + 40;

	if (parryAttackTween != null) parryAttackTween.cancel();
	if (flamePunchTween != null) flamePunchTween.cancel();
	parryAttackTween = FlxTween.tween(parryAttack, {x: getMattParryX()}, parryAnimTime * 0.001, {ease: FlxEase.cubeIn});
	flamePunchTween = FlxTween.tween(flamePunch, {x: flamePunch.x + 10000}, punchLateHitTiming * 0.001 * 15, {ease: FlxEase.linear});
}

function closeParry(parry:Dynamic) {
	if (parry.closed) return;
	parry.closed = true;
}

function finishParry(parry:Dynamic) {
	parries.remove(parry);
	deadParries.push(parry);
	activeParry = null;
	opponentAnimLocked = false;
	if (parryAttack != null) parryAttack.alpha = 0;
	if (flamePunch != null) flamePunch.alpha = 0;
	if (dad.curCharacter == dadParryCharacter && dad.curCharacter == "Wiik3VoiidMatt")
		dad.alpha = dadParryAlpha;
}

function updateParryNotes() {
	if (noMechanicsEnabled()) return;
	if (parries.length < 1) return;
	sortParriesIfNeeded();
	setupParrySprites();
	if (parryAttack == null) return;

	var parry = parries[0];
	var songPos = Conductor.songPosition;

	if (songPos > parry.time - parryAnimTime)
		startParry(parry);
	if (songPos > parry.time - 100 && songPos < parry.time + (punchLateHitTiming * 1.5))
		punchParry(parry);
	if (songPos > parry.time + 144)
		closeParry(parry);
	if (songPos > parry.time + parryAnimTime)
		finishParry(parry);
}

function refreshParriesFromNotes() {
	if (noMechanicsEnabled()) return;
	if (strumLines == null || strumLines.members == null || strumLines.members.length < 2) return;

	strumLines.members[1].notes.forEach(function(note) {
		var noteType = getNoteTypeWithoutCharacter(note.noteType);
		if (!noteTypeData.exists(noteType)) return;

		var data = noteTypeData.get(noteType);
		if (isParryNoteData(data))
			storeParry(note.strumTime);
	});
}

function onNoteCreation(event) {
	if (noMechanicsEnabled()) return;

	var noteType = getNoteTypeWithoutCharacter(event.noteType);
	if (noteTypeData.exists(noteType)) {
		var data = noteTypeData.get(noteType);
		cacheNoteTypeForNote(event.note, noteType);

		event.noteSprite = "game/voiid/notes/"+getNoteTypeSkin(data);

		if (!data.mustPress) {
			event.note.earlyPressWindow = 0.2;
			event.note.latePressWindow = 0.2;
			event.note.avoid = true;
		}

		if (data.echo != null && data.echo != "" && event.note.strumLine.ID == 1) {
			scripts.call("onEchoCreate", [event.note.strumTime, data.echo]);
		}
	}
}

function onPostNoteCreation(event) {
	if (noMechanicsEnabled()) return;

	var noteType = getNoteTypeWithoutCharacter(event.noteType);
	if (noteTypeData.exists(noteType)) {
		cacheNoteTypeForNote(event.note, noteType);
		applyNoteTypeRotation(event.note, noteTypeData.get(noteType));
	}
}

function onDeleteNote(event) {
	if (event != null && event.note != null && noteTypeCache.exists(event.note))
		noteTypeCache.remove(event.note);
}

function triggerFistThrow() {
	if (noMechanicsEnabled()) return;

	setupParrySprites();
	if (parries.length > 0)
		startParry(parries[0]);
	return;

	if (opponentAnimLocked) return;
	opponentAnimLocked = true;

	
	dadStartX = dad.x;

	
	dad.playAnim("fistThrow", true);

	
	var anim = dad.animation.curAnim;
	var duration:Float = 0.6;
	if (anim != null && anim.frameRate > 0)
		duration = anim.numFrames / anim.frameRate;

	
	if (dadMoveTween != null)
		dadMoveTween.cancel();

	
	dadMoveTween = FlxTween.tween(
		dad,
		{ x: dadStartX - 450 },
		duration * 0.5,
		{
			ease: FlxEase.cubeOut,
			onComplete: function(_) {
				
				FlxTween.tween(
					dad,
					{ x: dadStartX },
					duration * 0.5,
					{ ease: FlxEase.cubeIn }
				);
			}
		}
	);

	
	if (fistThrowTimer != null)
		fistThrowTimer.cancel();

	fistThrowTimer = new FlxTimer().start(duration, function(_) {
		opponentAnimLocked = false;
		dad.dance();
	});
}
function onNoteHit(event) 
{
	if (noMechanicsEnabled()) return;

	var data = getCachedNoteData(event.note, event.noteType);
	if (data == null) return;

	if (isBulletNoteData(data))
		handleBulletNoteHit(event);

	if (!data.mustPress)
		event.healthGain = -data.health;

	if (data.animSuffix != null)
		event.animSuffix = data.animSuffix;

	if (data.triggerFistThrow != null && data.triggerFistThrow == true) {
		triggerFistThrow();
	}
}
function onPlayerMiss(event)
{
	if (noMechanicsEnabled()) return;

	var data = getCachedNoteData(event.note, event.noteType);
	if (data != null) {
		if (isBulletNoteData(data))
			handleBulletPlayerMiss(event, data);

		if (!data.mustPress) {
			event.cancel();
			event.animCancelled = true;
			strumLines.members[event.playerID].deleteNote(event.note);
		} else {
			event.healthGain = -data.health;
			applyEffect(data.effect);
		}
	}
}

function handleBulletNoteHit(event) {
	if (noMechanicsEnabled()) return;

	if (event.note.strumLine.ID == 1) {
		playDadBulletShoot();
		makeBulletTracer();
	} else {
		playRandomShoot(boyfriend);
	}
}

function handleBulletPlayerMiss(event, data) {
	if (noMechanicsEnabled()) return;

	playDadBulletShoot();
	makeBulletTracer();
}

function playDadBulletShoot() {
	if (noMechanicsEnabled()) return;
	if (dad == null) return;
	playIfExists(dad, "shoot");
	opponentAnimLocked = true;

	if (dadBulletShootTimer != null) dadBulletShootTimer.cancel();
	dadBulletShootTimer = new FlxTimer().start(getAnimDuration(dad, 0.45), function(_) {
		opponentAnimLocked = false;
		if (dad != null) dad.dance();
	});
}

function playRandomShoot(char) {
	if (char == null) return;
	if (FlxG.random.bool())
		playIfExists(char, "shootLEFT");
	else
		playIfExists(char, "shootRIGHT");
}

function playIfExists(char, animName:String) {
	if (char == null) return;
	if (char.hasAnimation(animName))
		char.playAnim(animName, true, "SING");
	else if (animName != "shoot" && char.hasAnimation("shoot"))
		char.playAnim("shoot", true, "SING");
}

function getAnimDuration(char, fallback:Float):Float {
	if (char == null || char.animation == null || char.animation.curAnim == null)
		return fallback;

	var anim = char.animation.curAnim;
	if (anim.frameRate <= 0) return fallback;
	return anim.numFrames / anim.frameRate;
}

function makeBulletTracer() {
	if (noMechanicsEnabled()) return;
	if (dad == null || boyfriend == null) return;

	var tracer = new FlxSprite(dad.x + bulletTracerOffsetX, dad.y + bulletTracerOffsetY);
	tracer.makeGraphic(5000, 5, 0xFFFFFFFF);
	tracer.antialiasing = true;
	tracer.angle = 10 + FlxG.random.float(0, 2);
	tracer.origin.x = 0;
	tracer.origin.y = tracer.height * 0.5;
	tracer.alpha = 1;

	var dadIndex = members.indexOf(dad);
	if (dadIndex >= 0)
		insert(dadIndex + 1, tracer);
	else
		add(tracer);

	remove(boyfriend, true);
	insert(members.indexOf(tracer) + 1, boyfriend);

	FlxTween.tween(tracer, {alpha: 0}, 1, {
		ease: FlxEase.cubeOut,
		onComplete: function(_) {
			remove(tracer, true);
			tracer.destroy();
		}
	});

	bulletTracerCount++;
	if (bulletTracerCount > 30)
		bulletTracerCount = 0;
}
function onDadDance(event) {
	if (noMechanicsEnabled()) return;

	if (opponentAnimLocked) {
		event.cancel();
	}
}
var blurShaderV:CustomShader = null;
var blurShaderH:CustomShader = null;
var bleedShader:CustomShader = null;
function postCreate() {
	if (noMechanicsEnabled()) return;

	bleedShader = new CustomShader("VignetteEffect");
	bleedShader.strength = 25;
	bleedShader.size = 0;
	bleedShader.red = 200;
	if (camOther != null)
		camOther.addShader(bleedShader);

	blurShaderV = new CustomShader("blur");
    blurShaderV.strength = 3;
    blurShaderV.dirX = 0.0;
    blurShaderV.dirY = 1.0;
    FlxG.game.addShader(blurShaderV);

    blurShaderH = new CustomShader("blur");
    blurShaderH.strength = 3;
    blurShaderH.dirX = 1.0;
    blurShaderH.dirY = 0.0;
	FlxG.game.addShader(blurShaderH);

	graphicCache.cache(Paths.image("glasscrack"));
}
function destroy() {
	if (blurShaderV != null) FlxG.game.removeShader(blurShaderV);
	if (blurShaderH != null) FlxG.game.removeShader(blurShaderH);
	if (parryAttackTween != null) parryAttackTween.cancel();
	if (flamePunchTween != null) flamePunchTween.cancel();
	if (dadBulletShootTimer != null) dadBulletShootTimer.cancel();
	if (parryAttack != null) remove(parryAttack, true);
	if (flamePunch != null) remove(flamePunch, true);
}

public var drainHPBar:FlxSprite;
public var lostHPBar:FlxSprite;
function onPostChangeHealthBar(t) {
	if (noMechanicsEnabled()) return;

	maxHealth = actualMaxHealth-lostHealth;
	healthBar.setRange(healthBar.min, actualMaxHealth);

	if (drainHPBar == null) {
		drainHPBar = new FlxSprite();
		drainHPBar.makeGraphic(1,1,0xFFFF0000);
		drainHPBar.cameras = [camHUD];
	} else {
		remove(drainHPBar, true);
	}
	if (lostHPBar == null) {
		lostHPBar = new FlxSprite();
		lostHPBar.makeGraphic(1,1,0xFF000000);
		lostHPBar.cameras = [camHUD];
	} else {
		remove(lostHPBar, true);
	}

	insert(members.indexOf(healthBar)+1, drainHPBar);
	insert(members.indexOf(healthBar)+1, lostHPBar);

	lostHPBar.x = drainHPBar.x = healthBar.x;
	lostHPBar.y = drainHPBar.y = healthBar.y;
	
	drainHPBar.setGraphicSize(healthBar.width, healthBar.height);
	drainHPBar.updateHitbox();

	lostHPBar.setGraphicSize(healthBar.width, healthBar.height);
	lostHPBar.updateHitbox();

	if (t == "voiid/") {
		if (!downscroll) {
			drainHPBar.offset.y += 15;
			lostHPBar.offset.y += 15;
		} else {
			drainHPBar.offset.y -= 18;
			lostHPBar.offset.y -= 18;
		}
	}

	drainHPBar.scale.x = 0;

	scripts.call("onPostChangeMechanicBars", [t]);
}

var drainTime:Float = 0.0;
var blurTime:Float = 0.0;
var lostHealth:Float = 0.0;
var blurStrength:Float = 0.0;
public var actualMaxHealth:Float = 2;
public function applyEffect(effect) {
	if (noMechanicsEnabled()) return;

	switch(effect) {
		case "blur":
			blurStrength = 6;
			camGame.shake(0.03, 0.1);
			camHUD.shake(0.03, 0.1);

			var crack = new FlxSprite(0,0);
			crack.loadGraphic(Paths.image("glasscrack"));
			crack.antialiasing = true;
			crack.scale.set(0.6,0.6);
			crack.updateHitbox();
			crack.screenCenter();
			crack.alpha = 0.7;
			crack.x += FlxG.random.float(-200, 200);
			crack.y += FlxG.random.float(-200, 200);
			crack.angle += FlxG.random.float(-360, 360);
			crack.colorTransform.blueOffset = crack.colorTransform.greenOffset = crack.colorTransform.redOffset = 255;

			FlxG.sound.play(Paths.sound("glass"+FlxG.random.int(0,3)), 0.6);

			crack.cameras = [camOther != null ? camOther : camHUD];
			add(crack);
			new FlxTimer().start(3.0, function(tmr){
				FlxTween.tween(crack, {alpha: 0.0}, 1.0, {ease:FlxEase.cubeOut, onComplete:function(twn) {
					if (members.indexOf(crack) >= 0)
						remove(crack, true);
					crack.destroy();
				}});
			});
		case "blurSmall":
			blurStrength = 2;
		case "maxHealth":
			lostHealth += 0.25;
			maxHealth = actualMaxHealth-lostHealth;
			healthBar.setRange(healthBar.min, actualMaxHealth);
		case "drain":
			drainTime = 5.0;
	}
}
function updateEffects(elapsed) {
	if (noMechanicsEnabled()) {
		drainTime = 0;
		blurTime = 0;
		lostHealth = 0;
		blurStrength = 0;
		if (bleedShader != null) bleedShader.size = 0;
		if (blurShaderH != null) blurShaderH.strength = 0;
		if (blurShaderV != null) blurShaderV.strength = 0;
		if (drainHPBar != null) drainHPBar.scale.x = 0;
		if (lostHPBar != null) lostHPBar.scale.x = 0;
		return;
	}

	if (drainHPBar == null || lostHPBar == null) {
		if (bleedShader != null) bleedShader.size = 0;
		blurStrength = CoolUtil.fpsLerp(blurStrength, 0, 0.02);
		if (blurShaderH != null) blurShaderH.strength = blurStrength;
		if (blurShaderV != null) blurShaderV.strength = blurStrength;
		return;
	}

	if (drainTime > 0.0) {
		bleedShader.size = CoolUtil.fpsLerp(bleedShader.size, FlxMath.bound(drainTime, 0, 0.3), 0.1);
		drainTime -= elapsed;
		drainHPBar.scale.x = (drainTime/3)*drainHPBar.width;
		if (drainHPBar.scale.x >= healthBar.width * FlxMath.remapToRange(healthBar.percent, 0, 100, 0, 1))
			drainHPBar.scale.x = healthBar.width * FlxMath.remapToRange(healthBar.percent, 0, 100, 0, 1);

		drainHPBar.x = (healthBar.x + healthBar.width * FlxMath.remapToRange(healthBar.percent, 0, 100, 1, 0)) + (drainHPBar.scale.x/2) - (drainHPBar.width/2);

		if (health > elapsed)
			health -= elapsed/3;
	} else {
		drainTime = 0.0;
		bleedShader.size = 0;
		drainHPBar.scale.x = 0;
	}
	lostHPBar.scale.x = FlxMath.remapToRange(lostHealth, 0, actualMaxHealth, 0, lostHPBar.width);
	lostHPBar.x = healthBar.x + (lostHPBar.scale.x/2) - (lostHPBar.width/2);
	blurStrength = CoolUtil.fpsLerp(blurStrength, 0, 0.02);
	if (blurShaderH != null) blurShaderH.strength = blurStrength;
	if (blurShaderV != null) blurShaderV.strength = blurStrength;
}
function postUpdate(elapsed) {
	if (noMechanicsEnabled()) {
		updateEffects(elapsed);
		return;
	}

	updateEffects(elapsed);
	updateParryNotes();

	if (hasCachedNoteTypeVisuals) {
		for (p in strumLines) {
			p.notes.forEach(function(note) {
				applyCachedNoteTypeVisual(note);
			});
		}
	}
}
