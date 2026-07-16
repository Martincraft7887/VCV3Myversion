import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.assets.Paths;
import StringTools;

var bfPunchOffsets:Array<Float> = [200, 220, 100, 150];
var mattPunchOffsets:Array<Float> = [190, 250, 110, 140];
var allowedSongs:Array<String> = [
	"fisticuffs",
	"blastout",
	"immortal",
	"king hit",
	"king hit wawa",
	"tko",
	"edgelord",
	"revenge",
	"tko vip",
	"flaming glove",
	"flaming glove iii",	
	"king hit vip",
	"immortal vip"
];

var enabled:Bool = true;
var punchingEnabled:Bool = false;
var firstFrame:Bool = true;
var dadSingSuffix:String = "";
var bfSingSuffix:String = "";
var dadIdleSuffix:String = "";
var bfIdleSuffix:String = "";
var dadPreviousIdleSuffix:String = "";
var bfPreviousIdleSuffix:String = "";

var state = {
	pushing: false,
	pushTrails: false,
	bfBlock: true,
	mattBlock: true,
	bfEchoTrail: false,
	mattEchoTrail: false,
	bfShieldVisible: false,
	mattShieldVisible: false,
	standPunches: false,
	mattParry: false,
	ranged: true,
	bfSplashes: false,
	mattSplashes: false,
	healthDrain: true
};

var mode:String = "custom";
var pushAmount:Float = 0;
var pushPower:Float = 5;
var maxPush:Float = 400;
var minPush:Float = -400;
var healthDrain:Float = 0.008;

var defaultBFX:Float = 0;
var defaultBFY:Float = 0;
var defaultMattX:Float = 0;
var defaultMattY:Float = 0;

var bfPunches:Array<FlxSprite> = [];
var mattPunches:Array<FlxSprite> = [];
var bfShield:FlxSprite;
var mattShield:FlxSprite;
var aura:FlxSprite;

var doingPowerup:Bool = false;
var powerupRising:Bool = false;
var powerupYTween:FlxTween = null;
var floatTime:Float = 0;
var songLower:String = "";

function postCreate() {
	songLower = getSongName();
	enabled = isAllowedSong(songLower);
	if (songLower == "revenge") enabled = false;
	if (songLower == "edgelord") {
		state.pushing = true;
		maxPush = 300;
		minPush = -300;
	}

	createPunchPool();
	createShieldSprites();
	createAura();
	refreshCharacters(true);
}

function getSongName():String {
	var song = PlayState.SONG;
	if (song != null && song.meta != null && song.meta.name != null)
		return StringTools.trim(song.meta.name).toLowerCase();
	return "";
}

function isAllowedSong(name:String):Bool {
	for (song in allowedSongs)
		if (name == song)
			return true;
	return false;
}

function createPunchPool() {
	for (i in 0...4) {
		var bf = new FlxSprite();
		bf.cameras = [camGame];
		bf.visible = false;
		add(bf);
		bfPunches.push(bf);

		var matt = new FlxSprite();
		matt.cameras = [camGame];
		matt.visible = false;
		add(matt);
		mattPunches.push(matt);
	}
}

function createShieldSprites() {
	bfShield = new FlxSprite();
	bfShield.frames = Paths.getSparrowAtlas("characters/ShieldStand_BF");
	bfShield.animation.addByPrefix("idle", "BF Shield0", 24, true);
	bfShield.animation.play("idle");
	bfShield.scale.set(1.5, 1.5);
	bfShield.updateHitbox();
	bfShield.alpha = 0;
	add(bfShield);
	remove(bfShield, true);
	insert(members.indexOf(boyfriend), bfShield);

	mattShield = new FlxSprite();
	mattShield.frames = Paths.getSparrowAtlas("characters/ShieldStand_Matt");
	mattShield.animation.addByPrefix("idle", "idle0", 24, true);
	mattShield.animation.play("idle");
	mattShield.scale.set(1.5, 1.5);
	mattShield.updateHitbox();
	mattShield.alpha = 0;
	add(mattShield);
	remove(mattShield, true);
	insert(members.indexOf(dad), mattShield);
}

function createAura() {
	aura = new FlxSprite(-300, -650);
	aura.frames = Paths.getSparrowAtlas("aura");
	aura.animation.addByPrefix("aura", "aura", 24, true);
	aura.animation.play("aura");
	aura.scale.set(4, 4);
	aura.updateHitbox();
	aura.alpha = 0;
	add(aura);
	remove(aura, true);
	insert(members.indexOf(dad), aura);
}

function refreshCharacters(resetPositions:Bool) {
	if (dad == null || boyfriend == null) return;
	punchingEnabled = enabled && (dad.hasAnimation("singLEFT-block") || boyfriend.hasAnimation("singLEFT-block"));
	if (!resetPositions) return;
	// TKO changes stage while Matt is rising. Keep the original stage
	// coordinates so that refreshCharacters does not turn an intermediate
	// tween position into the new base position.
	if (!doingPowerup) {
		defaultBFX = boyfriend.x - pushAmount;
		defaultBFY = boyfriend.y;
		defaultMattX = dad.x - pushAmount;
		defaultMattY = dad.y;
	}
	positionShields();
}

function positionShields() {
	if (state.bfShieldVisible && state.mattShieldVisible) {
		positionDoubleShields();
		return;
	}
	positionBFShield(state.bfShieldVisible);
	positionMattShield();
}

function positionBFShield(activeMode:Bool) {
	if (bfShield == null || boyfriend == null) return;
	// Same raw-character positioning used by new_BlockStuff.hx. Do not use
	// Character.offset here: it changes with every animation frame.
	bfShield.x = defaultBFX + pushAmount - (activeMode ? 100 : 50);
	bfShield.y = boyfriend.y - 375;
}

function positionMattShield() {
	if (mattShield == null || dad == null) return;
	mattShield.x = defaultMattX + pushAmount - 250;
	mattShield.y = dad.y - 375;
}

function positionDoubleShields() {
	if (bfShield != null) {
		bfShield.x = defaultBFX - 600;
		bfShield.y = boyfriend.y - 375;
	}
	if (mattShield != null) {
		mattShield.x = defaultMattX + 250;
		mattShield.y = dad.y - 375;
	}
}

function setShieldVisibility(showBF:Bool, showMatt:Bool) {
	state.bfShieldVisible = showBF;
	state.mattShieldVisible = showMatt;
	// Clear any previous custom owner first, then apply mic only to the
	// character whose shield is visible.
	syncShieldMicSuffixes(showBF, showMatt);

	if (showBF && showMatt) {
		positionDoubleShields();
		moveShieldCharacters(-500, 500);
	} else if (showBF) {
		positionBFShield(true);
		moveShieldCharacters(0, 500);
	} else if (showMatt) {
		positionMattShield();
		moveShieldCharacters(-500, 0);
	} else {
		moveShieldCharacters(0, 0);
	}

	if (bfShield != null) {
		FlxTween.cancelTweensOf(bfShield);
		bfShield.alpha = showBF ? 1 : 0;
	}
	if (mattShield != null) {
		FlxTween.cancelTweensOf(mattShield);
		mattShield.alpha = showMatt ? 1 : 0;
	}
}

function syncShieldMicSuffixes(showBF:Bool, showMatt:Bool) {
	setBFSuffix("", true);
	setDadSuffix("", true);
	if (showBF) setBFSuffix("-mic", true);
	if (showMatt) setDadSuffix("-mic", true);
}

function getVisualX(char):Float {
	return char.x - char.offset.x;
}

function getVisualY(char):Float {
	return char.y - char.offset.y;
}

function getBaseVisualX(char, baseX:Float):Float {
	return baseX + pushAmount - char.offset.x;
}

function getBaseVisualY(char, baseY:Float):Float {
	return baseY - char.offset.y;
}

function onStageChanged(name) {
	pushAmount = 0;
	refreshCharacters(true);
	if (name == "VoiidArena-Edgelord") {
		maxPush = 400;
		minPush = -400;
		state.pushing = false;
	} else if (name == "Arena-Voiid" || name == "Edgelord-Intro") {
		maxPush = 250;
		minPush = -250;
	}

	if (songLower == "revenge") {
		enabled = name != "VoiidBoxingRingFar";
		refreshCharacters(false);
	}
}

function onCharactersChanged(strumlineID, names) {
	refreshCharacters(false);
	if (strumlineID == 0) {
		if (!doingPowerup) {
			defaultMattX = dad.x - pushAmount;
			defaultMattY = dad.y;
		}
		if (dadIdleSuffix != "") {
			var currentSuffix = getCharacterIdleSuffix(dad);
			if (currentSuffix != dadIdleSuffix) dadPreviousIdleSuffix = currentSuffix;
			applyIdleSuffix(dad, dadIdleSuffix);
		}
	} else if (strumlineID == 1) {
		if (!doingPowerup) {
			defaultBFX = boyfriend.x - pushAmount;
			defaultBFY = boyfriend.y;
		}
		if (bfIdleSuffix != "") {
			var currentSuffix = getCharacterIdleSuffix(boyfriend);
			if (currentSuffix != bfIdleSuffix) bfPreviousIdleSuffix = currentSuffix;
			applyIdleSuffix(boyfriend, bfIdleSuffix);
		}
	}
	positionShields();
}

function update(elapsed) {
	if (firstFrame) {
		firstFrame = false;
		refreshCharacters(true);
	}

	if (stage != null && stage.stageSprites != null && stage.stageSprites.exists("tko-floorGlow"))
		stage.stageSprites.get("tko-floorGlow").alpha = aura.alpha;

	// Once the 16-beat rise is complete, retain Restored's floating motion.
	// This stays outside punchingEnabled because the powerup character may not
	// contain boxing/block animations.
	if (doingPowerup && !powerupRising) {
		floatTime += elapsed;
		dad.y = defaultMattY - 150 + Math.sin(floatTime) * 50;
	}

	if (!punchingEnabled) return;
}

function cancelPowerupYTween() {
	if (powerupYTween == null) return;
	powerupYTween.cancel();
	powerupYTween = null;
}

function beginPowerupRise() {
	cancelPowerupYTween();
	doingPowerup = true;
	powerupRising = true;
	floatTime = 0;
	if (dad == null) {
		powerupRising = false;
		return;
	}

	// Restored: tween dadCharacter0 to getMattY() - 150 over 16 beats.
	powerupYTween = FlxTween.tween(dad, {y: defaultMattY - 150}, Conductor.crochet * 0.016, {
		ease: FlxEase.cubeIn,
		onComplete: function(_) {
			powerupYTween = null;
			if (!doingPowerup) return;
			powerupRising = false;
			floatTime = 0;
			dad.y = defaultMattY - 150;
		}
	});
}

function postUpdate(elapsed) {
	// Empty means this script is not managing the idle. This lets built-in
	// events such as Alt Animation Toggle keep idleSuffix = "-alt".
	if (dadIdleSuffix != "") refreshIdleSuffix(dad, dadIdleSuffix);
	if (bfIdleSuffix != "") refreshIdleSuffix(boyfriend, bfIdleSuffix);
}

function setDadSuffix(suffix:String, affectIdle:Bool) {
	var previousManagedSuffix = dadIdleSuffix;
	var nextIdleSuffix = affectIdle ? suffix : "";
	dadSingSuffix = suffix;
	if (previousManagedSuffix == "" && nextIdleSuffix != "")
		dadPreviousIdleSuffix = getCharacterIdleSuffix(dad);
	dadIdleSuffix = nextIdleSuffix;
	if (dadIdleSuffix != "")
		applyIdleSuffix(dad, dadIdleSuffix);
	else if (previousManagedSuffix != "") {
		applyIdleSuffix(dad, dadPreviousIdleSuffix);
		dadPreviousIdleSuffix = "";
	}
}

function setBFSuffix(suffix:String, affectIdle:Bool) {
	var previousManagedSuffix = bfIdleSuffix;
	var nextIdleSuffix = affectIdle ? suffix : "";
	bfSingSuffix = suffix;
	if (previousManagedSuffix == "" && nextIdleSuffix != "")
		bfPreviousIdleSuffix = getCharacterIdleSuffix(boyfriend);
	bfIdleSuffix = nextIdleSuffix;
	if (bfIdleSuffix != "")
		applyIdleSuffix(boyfriend, bfIdleSuffix);
	else if (previousManagedSuffix != "") {
		applyIdleSuffix(boyfriend, bfPreviousIdleSuffix);
		bfPreviousIdleSuffix = "";
	}
}

function getCharacterIdleSuffix(char):String {
	if (char == null || char.idleSuffix == null) return "";
	return Std.string(char.idleSuffix);
}

function applyIdleSuffix(char, suffix:String) {
	if (char == null) return;
	char.idleSuffix = hasIdleSuffix(char, suffix) ? suffix : "";
	refreshIdleSuffix(char, char.idleSuffix);
}

function hasIdleSuffix(char, suffix:String):Bool {
	if (suffix == "") return true;
	return char.hasAnimation("idle" + suffix)
		|| (char.hasAnimation("danceLeft" + suffix) && char.hasAnimation("danceRight" + suffix));
}

function refreshIdleSuffix(char, suffix:String) {
	if (char == null || char.animation == null || char.animation.curAnim == null) return;
	var cur:String = char.animation.curAnim.name;
	if (StringTools.startsWith(cur, "idle")) {
		var idleName = "idle" + suffix;
		if (char.hasAnimation(idleName) && cur != idleName)
			char.playAnim(idleName);
	} else if (StringTools.startsWith(cur, "danceLeft") || StringTools.startsWith(cur, "danceRight")) {
		var danceName = (StringTools.startsWith(cur, "danceLeft") ? "danceLeft" : "danceRight") + suffix;
		if (char.hasAnimation(danceName) && cur != danceName)
			char.playAnim(danceName);
	}
}

function normalizePunchDirection(direction:Int):Int {
	if (direction == 4) return 2;
	return direction % 4;
}

function getPunchDirection(event):Int {
	if (event != null && event.note != null && event.note.strumLine != null) {
		var lane:Int = event.note.strumID;
		var kc:Int = getKeyCountIndex(event.note.strumLine.ID);
		if (multikeySingDirs != null && kc >= 0 && kc < multikeySingDirs.length) {
			var dirs = multikeySingDirs[kc];
			if (dirs != null && lane >= 0 && lane < dirs.length && dirs[lane] != null)
				return normalizePunchDirection(dirs[lane]);
		}
	}

	if (event != null && event.direction != null)
		return normalizePunchDirection(event.direction);

	if (event != null && event.note != null)
		return normalizePunchDirection(event.note.noteData);

	return 0;
}

function correctPunchDirection(event):Int {
	var direction = getPunchDirection(event);
	if (event != null)
		event.direction = direction;
	return direction;
}

function onNoteHit(event) {
	if (!punchingEnabled) return;
	var direction:Int = correctPunchDirection(event);
	var doPush:Bool = !event.note.isSustainNote;
	if (event.note.strumLine.ID == 0) {
		applyShieldAwareSingSuffix(event, false);
		onMattHit(direction, doPush);
		if (doPush && state.healthDrain && !bfShieldAbsorbsHit() && !mattShieldAbsorbsHit()) drainHealth();
	} else if (event.note.strumLine.ID == 1) {
		applyShieldAwareSingSuffix(event, true);
		if (!isDodgeNote(event))
			onBFHit(direction, doPush);
	}
}

function onDadHit(event) {
	correctPunchDirection(event);
	applyShieldAwareSingSuffix(event, false);
}

function onPlayerHit(event) {
	correctPunchDirection(event);
	applyShieldAwareSingSuffix(event, true);
}

function applyShieldAwareSingSuffix(event, isBF:Bool) {
	var ownsShield:Bool = isBF ? bfShieldAbsorbsHit() : mattShieldAbsorbsHit();
	var attacksShield:Bool = isBF ? mattShieldAbsorbsHit() : bfShieldAbsorbsHit();
	var suffix:String = isBF ? bfSingSuffix : dadSingSuffix;

	// Shield ownership is authoritative while a shield is active. This also
	// removes a stale -mic left by a previous shield/strumline before CNE
	// chooses the note animation, without discarding -dodge or -alt.
	if (ownsShield)
		suffix = "-mic";
	else if (attacksShield) {
		suffix = "";
		removeEventMicSuffix(event);
	}

	applyEventSingSuffix(event, suffix);
}

function removeEventMicSuffix(event) {
	if (event == null) return;
	var currentSuffix:String = event.animSuffix == null ? "" : Std.string(event.animSuffix);
	if (!StringTools.endsWith(currentSuffix, "-mic")) return;
	event.animSuffix = currentSuffix.substring(0, currentSuffix.length - 4);
}

function applyEventSingSuffix(event, suffix:String) {
	if (suffix == "" || event == null || event.character == null) return;
	var currentSuffix:String = event.animSuffix == null ? "" : event.animSuffix;
	if (isDodgeNote(event) && currentSuffix == "")
		currentSuffix = "-dodge";

	var combinedSuffix = currentSuffix + suffix;
	if (event.character.hasAnimation(singAnim(event.direction, combinedSuffix)))
		event.animSuffix = combinedSuffix;
	else if (currentSuffix == "" && event.character.hasAnimation(singAnim(event.direction, suffix)))
		event.animSuffix = suffix;
}

function getNoteTypeWithoutCharacter(noteType) {
	if (noteType == null) return "";
	if (!StringTools.contains(noteType, "char[")) return noteType;
	return noteType.substring(0, noteType.indexOf("char["));
}

function isDodgeNote(event):Bool {
	var noteType = getNoteTypeWithoutCharacter(event.noteType);
	return noteType == "Wiik3Punch" || noteType == "Wiik4Sword";
}

function bfShieldAbsorbsHit():Bool {
	return state.bfShieldVisible;
}

function mattShieldAbsorbsHit():Bool {
	// tko-powerup reuses this sprite as part of the transformation, not as
	// the regular blocking shield from shield/doubleshield/custom.
	return state.mattShieldVisible && mode != "tko-powerup";
}

function onMattHit(direction:Int, doPush:Bool) {
	// Matt is attacking BF. If BF's shield is visible, the hit ends at the
	// shield: show the impact splash and skip block/echo/ranged punch logic.
	var hitsBFShield:Bool = bfShieldAbsorbsHit();
	if (doPush && (state.mattSplashes || hitsBFShield)) makeSplash(dad, direction, true);
	if (hitsBFShield) return;
	// Matt is behind his own shield and is using mic animations, so his notes
	// must not create a ranged boxing attack against BF.
	if (mattShieldAbsorbsHit()) return;
	var bfCanBlock:Bool = state.bfBlock && !StringTools.endsWith(boyfriend.getAnimName(), "-dodge");

	if (bfCanBlock) {
		var blockAnim = singAnim(direction, "-block");
		if (boyfriend.hasAnimation(blockAnim)) {
			scripts.call("onDoubleNoteGhostScriptedAnim", [boyfriend, blockAnim]);
			boyfriend.playSingAnim(direction, "-block");
		}

		if (doPush) pushCharacters(pushPower);
	}

	if (bfCanBlock || state.standPunches) {
		showRangedPunch(dad, boyfriend, false, direction);
		putAbove(dad, boyfriend);
	}
	if (bfCanBlock && state.mattEchoTrail)
		scripts.call("onDoubleNoteGhostEchoTrail", [dad, boyfriend]);
}

function onBFHit(direction:Int, doPush:Bool) {
	// BF is attacking Matt. Matt's shield absorbs the hit before Long/Mid
	// punch sprites can target Matt himself.
	var hitsMattShield:Bool = mattShieldAbsorbsHit();
	if (doPush && (state.bfSplashes || hitsMattShield)) makeSplash(boyfriend, direction, false);
	if (hitsMattShield) return;
	// BF is behind his own shield; keep the mic sing animation but suppress
	// the boxing Long/Mid attack generated by this script.
	if (bfShieldAbsorbsHit()) return;
	var mattCanBlock:Bool = state.mattBlock;

	if (mattCanBlock) {
		var parryAnim = singAnim(direction, "-parry");
		var blockAnim = singAnim(direction, "-block");
		if (state.mattParry && dad.hasAnimation(parryAnim)) {
			scripts.call("onDoubleNoteGhostScriptedAnim", [dad, parryAnim]);
			dad.playSingAnim(direction, "-parry");
		} else if (dad.hasAnimation(blockAnim)) {
			scripts.call("onDoubleNoteGhostScriptedAnim", [dad, blockAnim]);
			dad.playSingAnim(direction, "-block");
		}

		if (doPush) pushCharacters(-pushPower);
	}

	if (mattCanBlock || state.standPunches) {
		showRangedPunch(boyfriend, dad, true, direction);
		putAbove(boyfriend, dad);
	}
	if (mattCanBlock && state.bfEchoTrail)
		scripts.call("onDoubleNoteGhostEchoTrail", [boyfriend, dad]);
}

function singAnim(direction:Int, suffix:String):String {
	return ["singLEFT", "singDOWN", "singUP", "singRIGHT"][direction % 4] + suffix;
}

function pushCharacters(amount:Float) {
	if (!state.pushing) return;
	var next = pushAmount + amount;
	if (next > maxPush || next < minPush) return;
	pushAmount = next;
	boyfriend.x += amount;
	dad.x += amount;
	positionShields();
}

function putAbove(front, back) {
	remove(front, true);
	insert(members.indexOf(back) + 1, front);
}

function makeSplash(char, direction:Int, flip:Bool) {
	var splash = new FlxSprite();
	splash.frames = Paths.getSparrowAtlas("characters/Splash");
	splash.animation.addByPrefix("splash", "splash", 24, false);
	splash.animation.play("splash");
	splash.scale.set(0.5, 0.5);
	splash.updateHitbox();
	splash.angle = 90;
	splash.flipX = flip;
	splash.x = flip ? dad.x + 250 : boyfriend.x - 500;
	splash.y = (flip ? getBaseVisualY(dad, defaultMattY) : getBaseVisualY(boyfriend, defaultBFY))
		+ (flip ? mattPunchOffsets[direction] : bfPunchOffsets[direction]);
	insert(members.indexOf(char) + 1, splash);
	FlxTween.tween(splash, {alpha: 0}, Conductor.crochet * 0.002, {
		onComplete: function(_) {
			remove(splash);
			splash.destroy();
		}
	});
}

function showRangedPunch(attacker, target, bfAttack:Bool, direction:Int) {
	if (!state.ranged) return;
	direction = direction % 4;

	var dist:Float = Math.abs((dad.x + 200) - boyfriend.x);
	if (dist < 220) return;

	var spriteName:String;
	if (dist < 500)
		spriteName = bfAttack ? "MidBF" : "MidMatt";
	else
		spriteName = bfAttack ? "LongBF" : "LongMatt";

	var punch = (bfAttack ? bfPunches : mattPunches)[direction];
	var offsets = bfAttack ? bfPunchOffsets : mattPunchOffsets;
	var xPos = bfAttack ? target.x : target.x - punch.width;
	var yPos = attacker.y + offsets[direction] - 400;

	FlxTween.cancelTweensOf(punch);
	punch.loadGraphic(Paths.image("punches/" + spriteName));
	punch.x = xPos;
	punch.y = yPos;
	punch.flipX = false;
	punch.visible = true;
	punch.alpha = 1;
	FlxTween.tween(punch, {alpha: 0}, 0.15, {
		ease: FlxEase.cubeOut,
		onComplete: function(_) punch.visible = false
	});
}

function drainHealth() {
	if (health - healthDrain > 0.09)
		health -= healthDrain;
	else
		health = 0.035;
}

function resetOptions() {
	state.pushing = false;
	state.pushTrails = false;
	state.bfBlock = false;
	state.mattBlock = false;
	state.bfEchoTrail = false;
	state.mattEchoTrail = false;
	state.bfShieldVisible = false;
	state.mattShieldVisible = false;
	state.standPunches = false;
	state.mattParry = false;
	state.ranged = false;
	state.bfSplashes = false;
	state.mattSplashes = false;
	state.healthDrain = true;
	setDadSuffix("", true);
	setBFSuffix("", true);
}

function leaveMode() {
	if (mode == "shield" || mode == "bfshield" || mode == "doubleshield"
		|| (mode == "custom" && (state.bfShieldVisible || state.mattShieldVisible)))
		moveShieldCharacters(0, 0);
	else if (mode == "duet" || mode == "duet-tko" || mode == "tko-closeup")
		moveCharacters(0, 0, 4);
	else if (mode == "tko-powerup")
		moveCharacters(0, 0, 4);

	if (mode == "shield") setDadSuffix("", true);
	else if (mode == "bfshield") setBFSuffix("", true);
	else if (mode == "duet parry") setDadSuffix("", false);
	else if (mode == "doubleshield") {
		setDadSuffix("", true);
		setBFSuffix("", true);
	} else if (mode == "custom") {
		if (state.mattShieldVisible) setDadSuffix("", true);
		if (state.bfShieldVisible) setBFSuffix("", true);
	}
	if (bfShield != null) FlxTween.tween(bfShield, {alpha: 0}, Conductor.crochet * 0.004);
	if (mattShield != null) FlxTween.tween(mattShield, {alpha: 0}, Conductor.crochet * 0.004);
	state.bfShieldVisible = false;
	state.mattShieldVisible = false;
	if (aura != null && doingPowerup) FlxTween.tween(aura, {alpha: 0}, Conductor.crochet * 0.008);
	if (doingPowerup) {
		cancelPowerupYTween();
		doingPowerup = false;
		powerupRising = false;
		playIfExists(dad, "destrans");
		powerupYTween = FlxTween.tween(dad, {y: defaultMattY}, Conductor.crochet * 0.008, {
			ease: FlxEase.sineOut,
			onComplete: function(_) powerupYTween = null
		});
	}
}

function playIfExists(char, animName:String) {
	if (char != null && char.hasAnimation(animName))
		// NONE/null replaces the old engine's playFullAnim behavior: wait for
		// trans/destrans to finish, then dance using the current idleSuffix.
		char.playAnim(animName, true, null);
}

function moveCharacters(dadOffset:Float, bfOffset:Float, beats:Float) {
	FlxTween.tween(dad, {x: defaultMattX + pushAmount + dadOffset}, Conductor.crochet * 0.001 * beats, {ease: FlxEase.cubeInOut});
	FlxTween.tween(boyfriend, {x: defaultBFX + pushAmount + bfOffset}, Conductor.crochet * 0.001 * beats, {ease: FlxEase.cubeInOut});
}

function moveShieldCharacters(dadOffset:Float, bfOffset:Float) {
	// new_BlockStuff.hx uses a fixed half-second movement for every shield layout.
	FlxTween.cancelTweensOf(dad);
	FlxTween.cancelTweensOf(boyfriend);
	FlxTween.tween(dad, {x: defaultMattX + pushAmount + dadOffset}, 0.5);
	FlxTween.tween(boyfriend, {x: defaultBFX + pushAmount + bfOffset}, 0.5);
}

function applyMode(nextMode:String) {
	leaveMode();
	mode = nextMode;
	if (mode == "custom") return;
	resetOptions();

	switch(mode) {
		case "pushing":
			state.pushing = true; state.bfBlock = true; state.mattBlock = true;
		case "duet parry":
			state.bfBlock = true; state.mattBlock = true; state.mattParry = true; setDadSuffix("-parry", false);
		case "no ranged":
			state.bfBlock = true; state.mattBlock = true;
		case "duet":
			state.bfSplashes = true; state.ranged = true; state.standPunches = true; moveCharacters(-130, 130, 4);
		case "duet-tko":
			state.bfSplashes = true; state.ranged = true; state.standPunches = true; moveCharacters(100, -100, 4);
		case "tko-closeup":
			state.bfBlock = true; state.mattBlock = true; moveCharacters(290, -290, 4);
		case "tko-bfmoveright":
			state.bfBlock = true; state.mattBlock = true; state.ranged = true; moveCharacters(0, 200, 31);
		case "tko-mattmoveleft":
			state.bfBlock = true; state.mattBlock = true; state.ranged = true; moveCharacters(-200, 0, 31);
		case "shield":
			syncShieldMicSuffixes(false, true); state.bfSplashes = true; state.healthDrain = false;
			state.mattShieldVisible = true;
			positionMattShield(); moveShieldCharacters(-500, 0);
			FlxTween.tween(mattShield, {alpha: 1}, Conductor.crochet * 0.004);
		case "bfshield":
			syncShieldMicSuffixes(true, false); state.mattSplashes = true; state.healthDrain = false;
			state.bfShieldVisible = true;
			positionBFShield(true); moveShieldCharacters(0, 500);
			FlxTween.tween(bfShield, {alpha: 1}, Conductor.crochet * 0.004);
		case "doubleshield":
			syncShieldMicSuffixes(true, true);
			state.bfSplashes = true; state.mattSplashes = true; state.healthDrain = false;
			state.bfShieldVisible = true; state.mattShieldVisible = true;
			positionDoubleShields(); moveShieldCharacters(-500, 500);
			FlxTween.tween(bfShield, {alpha: 1}, Conductor.crochet * 0.004);
			FlxTween.tween(mattShield, {alpha: 1}, Conductor.crochet * 0.004);
		case "resetpush":
			resetPush();
			state.bfBlock = true; state.mattBlock = true; state.ranged = true;
		case "disable":
			enabled = false; punchingEnabled = false;
		case "enable":
			enabled = true; refreshCharacters(false);
		case "tko-powerup":
			state.bfBlock = false; state.mattBlock = false;
			state.mattShieldVisible = true;
			playIfExists(dad, "trans");
			positionMattShield(); moveCharacters(250, -290, 8);
			beginPowerupRise();
			FlxTween.tween(mattShield, {alpha: 1}, Conductor.crochet * 0.016);
			FlxTween.tween(aura, {alpha: 1}, Conductor.crochet * 0.016);
		case "tko-powerupEnd":
			state.mattShieldVisible = false;
			state.bfBlock = true; state.mattBlock = true;
			moveCharacters(290, -290, 8);
			if (mattShield != null) FlxTween.tween(mattShield, {alpha: 0}, Conductor.crochet * 0.008);
		default:
			state.bfBlock = true; state.mattBlock = true; state.ranged = true;
			moveCharacters(0, 0, 4);
	}
}

function resetPush() {
	pushAmount = 0;
	moveCharacters(0, 0, 4);
	positionShields();
}

function getEventName(event):String {
	if (event == null || event.event == null || event.event.name == null)
		return "";
	return StringTools.trim(Std.string(event.event.name)).toLowerCase();
}

function getEventParam(event, index:Int):Dynamic {
	if (event == null || event.event == null || event.event.params == null || event.event.params.length <= index)
		return null;
	return event.event.params[index];
}

function onEvent(event) {
	var eventName = getEventName(event);

	if (eventName == "toggle matt echo trail") {
		state.mattEchoTrail = !state.mattEchoTrail;
		return;
	}

	if (eventName == "toggle bf echo trail") {
		state.bfEchoTrail = !state.bfEchoTrail;
		return;
	}

	if (eventName == "change block state") {
		var nextMode = getEventParam(event, 0);
		if (nextMode != null && Std.string(nextMode) != "" && Std.string(nextMode) != mode)
			applyMode(Std.string(nextMode));
		return;
	}

	if (eventName != "punching control") return;
	var p = event.event.params;

	state.pushing = p[0];
	state.pushTrails = p[1];
	state.bfBlock = p[2];
	state.mattBlock = p[3];
	state.bfEchoTrail = p[4];
	state.mattEchoTrail = p[5];
	state.mattParry = p[6];
	pushPower = p[7];
	maxPush = p[8];
	minPush = p[9];
	if (p.length > 10 && p[10]) resetPush();

	if (p.length > 12) enabled = p[12];
	if (p.length > 13) state.ranged = p[13];
	if (p.length > 14) state.bfSplashes = p[14];
	if (p.length > 15) state.mattSplashes = p[15];
	if (p.length > 16) state.healthDrain = p[16];
	if (p.length > 17) healthDrain = p[17];
	refreshCharacters(false);

	if (p.length > 11 && p[11] != null && p[11] != "")
		applyMode(Std.string(p[11]));

	// These parameters were appended so older charts keep their original indices.
	// Mode presets control their own shields; the booleans are for custom mode.
	if (mode == "custom") {
		if (p.length > 18)
			setShieldVisibility(p[18] == true, p.length > 19 && p[19] == true);
		if (p.length > 20)
			state.standPunches = p[20] == true;
	}
}
