import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
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

var state = {
	pushing: false,
	pushTrails: false,
	bfBlock: true,
	mattBlock: true,
	bfEchoTrail: false,
	mattEchoTrail: false,
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
var echoShader:CustomShader;

var doingPowerup:Bool = false;
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

	echoShader = new CustomShader("EchoEffect");
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
	defaultBFX = boyfriend.x - pushAmount;
	defaultBFY = boyfriend.y;
	defaultMattX = dad.x - pushAmount;
	defaultMattY = dad.y;
	positionShields();
}

function positionShields() {
	if (bfShield != null) {
		bfShield.x = getBaseVisualX(boyfriend, defaultBFX) - 240;
		bfShield.y = getBaseVisualY(boyfriend, defaultBFY) - 400;
	}
	if (mattShield != null) {
		mattShield.x = getBaseVisualX(dad, defaultMattX) - 240;
		mattShield.y = getBaseVisualY(dad, defaultMattY) - 420;
	}
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
		defaultMattX = dad.x - pushAmount;
		defaultMattY = dad.y;
		applyIdleSuffix(dad, dadIdleSuffix);
	} else if (strumlineID == 1) {
		defaultBFX = boyfriend.x - pushAmount;
		defaultBFY = boyfriend.y;
		applyIdleSuffix(boyfriend, bfIdleSuffix);
	}
	positionShields();
}

function update(elapsed) {
	if (firstFrame) {
		firstFrame = false;
		refreshCharacters(true);
	}
	if (!punchingEnabled) return;

	if (stage != null && stage.stageSprites != null && stage.stageSprites.exists("tko-floorGlow"))
		stage.stageSprites.get("tko-floorGlow").alpha = aura.alpha;

	if (doingPowerup) {
		floatTime += elapsed;
		dad.y = defaultMattY - 150 + Math.sin(floatTime) * 50;
	}
}

function postUpdate(elapsed) {
	refreshIdleSuffix(dad, dadIdleSuffix);
	refreshIdleSuffix(boyfriend, bfIdleSuffix);
}

function setDadSuffix(suffix:String, affectIdle:Bool) {
	dadSingSuffix = suffix;
	dadIdleSuffix = affectIdle ? suffix : "";
	applyIdleSuffix(dad, dadIdleSuffix);
}

function setBFSuffix(suffix:String, affectIdle:Bool) {
	bfSingSuffix = suffix;
	bfIdleSuffix = affectIdle ? suffix : "";
	applyIdleSuffix(boyfriend, bfIdleSuffix);
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
		applyEventSingSuffix(event, dadSingSuffix);
		onMattHit(direction, doPush);
		if (doPush && state.healthDrain) drainHealth();
	} else if (event.note.strumLine.ID == 1) {
		applyEventSingSuffix(event, bfSingSuffix);
		if (!isDodgeNote(event))
			onBFHit(direction, doPush);
	}
}

function onDadHit(event) {
	correctPunchDirection(event);
	applyEventSingSuffix(event, dadSingSuffix);
}

function onPlayerHit(event) {
	correctPunchDirection(event);
	applyEventSingSuffix(event, bfSingSuffix);
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

function onMattHit(direction:Int, doPush:Bool) {
	if (doPush && state.mattSplashes) makeSplash(dad, direction, true);
	if (!state.bfBlock || StringTools.endsWith(boyfriend.getAnimName(), "-dodge")) return;

	if (boyfriend.hasAnimation(singAnim(direction, "-block")))
		boyfriend.playSingAnim(direction, "-block");

	if (state.mattEchoTrail || state.pushTrails) makeTrail(dad);
	if (doPush) pushCharacters(pushPower);
	showRangedPunch(dad, boyfriend, false, direction);
	putAbove(dad, boyfriend);
}

function onBFHit(direction:Int, doPush:Bool) {
	if (doPush && state.bfSplashes) makeSplash(boyfriend, direction, false);
	if (!state.mattBlock) return;

	if (state.mattParry && dad.hasAnimation(singAnim(direction, "-parry")))
		dad.playSingAnim(direction, "-parry");
	else if (dad.hasAnimation(singAnim(direction, "-block")))
		dad.playSingAnim(direction, "-block");

	if (state.bfEchoTrail || state.pushTrails) makeTrail(boyfriend);
	if (doPush) pushCharacters(-pushPower);
	showRangedPunch(boyfriend, dad, true, direction);
	putAbove(boyfriend, dad);
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

function makeTrail(char) {
	new FlxTimer().start(0.001, function(_) spawnTrail(char));
}

function spawnTrail(char) {
	if (char == null || char.getAnimName() == null) return;

	var ghost = FunkinSprite.copyFrom(char);
	ghost.x = char.x;
	ghost.y = char.y;
	ghost.color = char.color;
	ghost.shader = echoShader;
	insert(members.indexOf(char) + 1, ghost);

	FlxTween.tween(ghost, {alpha: 0}, Conductor.crochet * 0.001 * 16, {
		ease: FlxEase.cubeOut,
		onComplete: function(_) {
			remove(ghost);
			ghost.destroy();
		}
	});
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
	state.mattParry = false;
	state.ranged = false;
	state.bfSplashes = false;
	state.mattSplashes = false;
	state.healthDrain = true;
	setDadSuffix("", true);
	setBFSuffix("", true);
}

function leaveMode() {
	if (mode == "shield" || mode == "bfshield" || mode == "duet" || mode == "duet-tko" || mode == "tko-closeup")
		moveCharacters(0, 0, 4);
	else if (mode == "doubleshield")
		moveCharacters(0, 0, 8);
	else if (mode == "tko-powerup")
		moveCharacters(0, 0, 4);

	if (mode == "shield") setDadSuffix("", true);
	else if (mode == "bfshield") setBFSuffix("", true);
	else if (mode == "duet parry") setDadSuffix("", false);
	else if (mode == "doubleshield") {
		setDadSuffix("", true);
		setBFSuffix("", true);
	}
	if (bfShield != null) FlxTween.tween(bfShield, {alpha: 0}, Conductor.crochet * 0.004);
	if (mattShield != null) FlxTween.tween(mattShield, {alpha: 0}, Conductor.crochet * 0.004);
	if (aura != null && doingPowerup) FlxTween.tween(aura, {alpha: 0}, Conductor.crochet * 0.008);
	if (doingPowerup) {
		doingPowerup = false;
		playIfExists(dad, "destrans");
		FlxTween.tween(dad, {y: defaultMattY}, Conductor.crochet * 0.008, {ease: FlxEase.sineOut});
	}
}

function playIfExists(char, animName:String) {
	if (char != null && char.hasAnimation(animName))
		char.playAnim(animName, true, "SING");
}

function moveCharacters(dadOffset:Float, bfOffset:Float, beats:Float) {
	FlxTween.tween(dad, {x: defaultMattX + pushAmount + dadOffset}, Conductor.crochet * 0.001 * beats, {ease: FlxEase.cubeInOut});
	FlxTween.tween(boyfriend, {x: defaultBFX + pushAmount + bfOffset}, Conductor.crochet * 0.001 * beats, {ease: FlxEase.cubeInOut});
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
			state.bfSplashes = true; moveCharacters(-130, 130, 4);
		case "duet-tko":
			state.bfSplashes = true; moveCharacters(100, -100, 4);
		case "tko-closeup":
			state.bfBlock = true; state.mattBlock = true; moveCharacters(290, -290, 4);
		case "tko-bfmoveright":
			state.bfBlock = true; state.mattBlock = true; state.ranged = true; moveCharacters(0, 200, 31);
		case "tko-mattmoveleft":
			state.bfBlock = true; state.mattBlock = true; state.ranged = true; moveCharacters(-200, 0, 31);
		case "shield":
			setDadSuffix("-mic", true); state.bfSplashes = true; state.healthDrain = false; moveCharacters(-450, 70, 4);
			positionShields(); FlxTween.tween(mattShield, {alpha: 1}, Conductor.crochet * 0.004);
		case "bfshield":
			setBFSuffix("-mic", true); state.mattSplashes = true; state.healthDrain = false; moveCharacters(-150, 450, 4);
			positionShields(); FlxTween.tween(bfShield, {alpha: 1}, Conductor.crochet * 0.004);
		case "doubleshield":
			setDadSuffix("-mic", true); setBFSuffix("-mic", true);
			state.bfSplashes = true; state.mattSplashes = true; state.healthDrain = false; moveCharacters(-450, 450, 8);
			positionShields();
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
			doingPowerup = true; floatTime = 0;
			playIfExists(dad, "trans");
			moveCharacters(250, -290, 8);
			positionShields();
			FlxTween.tween(mattShield, {alpha: 1}, Conductor.crochet * 0.016);
			FlxTween.tween(aura, {alpha: 1}, Conductor.crochet * 0.016);
		case "tko-powerupEnd":
			doingPowerup = false;
			playIfExists(dad, "destrans");
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

function onEvent(event) {
	if (event.event.name != "Punching Control") return;
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
		applyMode(p[11]);
}
