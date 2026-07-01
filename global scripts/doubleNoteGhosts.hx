import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.backend.shaders.CustomShader;
import StringTools;

var doubleGhostPools:Array<Dynamic> = [];
var doubleGhostLineData:Array<Dynamic> = [];
var doubleGhostFollowData:Array<Dynamic> = [];
var doubleGhostEchoPools:Array<Dynamic> = [];
var doubleGhostEchoShader:CustomShader = null;
var doubleGhostEchoMaxPerChar:Int = 24;
var doubleGhostEchoAlpha:Float = 0.35;
var doubleGhostEchoDuration:Float = 0.35;
var doubleGhostMaxPerChar:Int = 8;
var doubleGhostAlpha:Float = 0.5;
var doubleGhostSpawnCount:Int = 0;

function getCharPool(char:Character):Dynamic {
	for (pool in doubleGhostPools)
		if (pool.char == char)
			return pool;

	var pool = {
		char: char,
		lastTime: Math.NEGATIVE_INFINITY,
		lastAnimName: null,
		lastHoldTime: 0.0,
		lastSpawnTime: Math.NEGATIVE_INFINITY,
		spawnedAnims: [],
		activeHolds: [],
		lastObservedAnimName: null,
		lastObservedFrame: 0,
		lastObservedHoldTime: 0.0,
		ghosts: [],
		index: 0
	};
	doubleGhostPools.push(pool);
	return pool;
}

function getGhost(pool:Dynamic, char:Character):FunkinSprite {
	if (pool.ghosts.length < doubleGhostMaxPerChar) {
		var ghost:FunkinSprite = FunkinSprite.copyFrom(char);
		ghost.active = false;
		pool.ghosts.push(ghost);
		return ghost;
	}

	var ghost:FunkinSprite = pool.ghosts[pool.index];
	pool.index = (pool.index + 1) % pool.ghosts.length;
	FlxTween.cancelTweensOf(ghost);
	return ghost;
}

function hasActiveGhostAnim(pool:Dynamic, animName:String):Bool {
	if (pool == null || animName == null)
		return false;

	for (ghost in pool.ghosts)
		if (ghost != null && ghost.exists && ghost.alive && ghost.getAnimName() == animName)
			return true;

	return false;
}

function copyPoseToGhost(ghost:FunkinSprite, char:Character, animName:String, copyCurrentFrame:Bool = false, snapshotFrame:Int = 0) {
	ghost.setPosition(char.x + char.extraOffset.x, char.y + char.extraOffset.y);
	ghost.frames = char.frames;
	ghost.animation.copyFrom(char.animation);
	ghost.animOffsets = char.animOffsets.copy();
	ghost.playAnim(animName, true);
	var copiedCurrentAnim = getCurrentAnimName(char) == animName;
	ghost.globalCurFrame = copyCurrentFrame ? (copiedCurrentAnim ? char.globalCurFrame : snapshotFrame) : 0;
	var animOffset = ghost.getAnimOffset(animName);
	ghost.frameOffset.set(animOffset.x, animOffset.y);
	animOffset.putWeak();
	ghost.offset.copyFrom(char.offset);
	ghost.origin.copyFrom(char.origin);
	ghost.scale.copyFrom(char.scale);
	ghost.scrollFactor.copyFrom(char.scrollFactor);
	ghost.cameras = char.cameras;
	ghost.flipX = char.flipX;
	ghost.flipY = char.flipY;
	ghost.angle = char.angle;
	ghost.alpha = Math.min(char.alpha, doubleGhostAlpha);
	ghost.visible = char.visible;
	ghost.active = false;
	ghost.antialiasing = char.antialiasing;
	ghost.color = char.color;
	ghost.blend = char.blend;
	ghost.shader = char.shader;
	ghost.colorTransform.redMultiplier = char.colorTransform.redMultiplier;
	ghost.colorTransform.greenMultiplier = char.colorTransform.greenMultiplier;
	ghost.colorTransform.blueMultiplier = char.colorTransform.blueMultiplier;
	ghost.colorTransform.alphaMultiplier = Math.min(char.colorTransform.alphaMultiplier, 1);
	ghost.colorTransform.redOffset = char.colorTransform.redOffset;
	ghost.colorTransform.greenOffset = char.colorTransform.greenOffset;
	ghost.colorTransform.blueOffset = char.colorTransform.blueOffset;
	ghost.colorTransform.alphaOffset = 0;
	ghost.skew.set(char.skew.x, char.skew.y);
	ghost.transformMatrix = char.transformMatrix;
	ghost.matrixExposed = char.matrixExposed;
	ghost.revive();
}

function getVCCharacters(event):Array<Character> {
	if (event == null || event.note == null || event.note.strumLine == null)
		return [];

	if (event.characters != null && event.characters.length > 0)
		return event.characters;

	var line = event.note.strumLine;
	if (line.characters == null || line.characters.length <= 0)
		return [];

	if (event.noteType != null && StringTools.contains(event.noteType, "char[")) {
		var charsIndex = event.noteType.indexOf("char[") + 5;
		var list = event.noteType.substring(charsIndex, event.noteType.length - 1);
		var result:Array<Character> = [];

		for (id in list.split(",")) {
			var index = Std.parseInt(id) % line.characters.length;
			if (line.characters[index] != null)
				result.push(line.characters[index]);
		}

		return result;
	}

	return [line.characters[0]];
}

function getEventAnimName(char:Character, event):String {
	if (char == null || event == null || event.cancelled || event.animCancelled)
		return null;

	var suffix:String = event.animSuffix == null ? "" : event.animSuffix;
	var direction:Int = event.direction;
	var animName:String = getFirstExistingAnim(char, getAnimCandidates(char, direction, suffix));

	if (animName != null)
		return animName;

	var currentAnim = getCurrentAnimName(char);
	if (currentAnim != null && !isIdleAnim(currentAnim) && char.hasAnimation(currentAnim))
		return currentAnim;

	return null;
}

function getAnimCandidates(char:Character, direction:Int, suffix:String):Array<String> {
	var dir = getDirectionName(direction);
	var lowerDir = dir.toLowerCase();
	var cleanSuffix = suffix == null ? "" : suffix;
	if (StringTools.startsWith(cleanSuffix, "-"))
		cleanSuffix = cleanSuffix.substr(1);

	var candidates:Array<String> = [];

	if (suffix != "") {
		candidates.push(char.getSingAnim(direction, suffix));
		candidates.push(cleanSuffix + dir);
		candidates.push(cleanSuffix + lowerDir);
		candidates.push(cleanSuffix.toLowerCase() + dir);
		candidates.push(cleanSuffix.toLowerCase() + lowerDir);
		candidates.push(dir + cleanSuffix);
		candidates.push(lowerDir + cleanSuffix);
	}

	candidates.push(char.getSingAnim(direction, ""));
	return candidates;
}

function getFirstExistingAnim(char:Character, candidates:Array<String>):String {
	for (animName in candidates)
		if (animName != null && animName != "" && char.hasAnimation(animName))
			return animName;
	return null;
}

function getDirectionName(direction:Int):String {
	return ["LEFT", "DOWN", "UP", "RIGHT"][direction % 4];
}

function getGhostHoldTime(event):Float {
	if (event == null || event.note == null)
		return 0;

	var length:Float = event.note.sustainLength == null ? 0 : event.note.sustainLength;
	var next = event.note.nextNote;
	var maxEnd:Float = event.note.strumTime;

	while (next != null && next.isSustainNote) {
		var sustainLength:Float = next.sustainLength == null ? 0 : next.sustainLength;
		maxEnd = Math.max(maxEnd, next.strumTime + sustainLength);
		next = next.nextNote;
	}

	length = Math.max(length, maxEnd - event.note.strumTime);
	return Math.max(0, length * 0.001);
}

function updateActiveHold(pool:Dynamic, event, animName:String) {
	var holdTime = getGhostHoldTime(event);
	if (pool == null || event == null || event.note == null || animName == null || holdTime <= 0)
		return;

	pruneActiveHolds(pool, event.note.strumTime);

	var id:Int = event.note.noteData;
	var hold = getActiveHold(pool, id);
	if (hold == null) {
		hold = {
			id: id,
			start: event.note.strumTime,
			until: event.note.strumTime + (holdTime * 1000),
			anim: animName
		};
		pool.activeHolds.push(hold);
		return;
	}

	hold.start = event.note.strumTime;
	hold.until = event.note.strumTime + (holdTime * 1000);
	hold.anim = animName;
}

function getActiveHold(pool:Dynamic, id:Int):Dynamic {
	if (pool == null)
		return null;

	for (hold in pool.activeHolds)
		if (hold.id == id)
			return hold;

	return null;
}

function pruneActiveHolds(pool:Dynamic, noteTime:Float) {
	if (pool == null || pool.activeHolds == null)
		return;

	var kept:Array<Dynamic> = [];
	for (hold in pool.activeHolds)
		if (noteTime <= hold.until)
			kept.push(hold);
	pool.activeHolds = kept;
}

function spawnActiveHoldInterruptGhosts(char:Character, pool:Dynamic, event, eventAnim:String):Int {
	if (char == null || pool == null || event == null || event.note == null)
		return 0;

	var noteTime:Float = event.note.strumTime;
	pruneActiveHolds(pool, noteTime);

	var spawned = 0;
	var currentAnim = getCurrentAnimName(char);
	for (hold in pool.activeHolds) {
		if (noteTime <= hold.start + 2 || noteTime > hold.until)
			continue;
		if (hold.anim == null || hold.anim == eventAnim)
			continue;
		if (!canSpawnAnimAtTime(pool, hold.anim, noteTime))
			continue;

		var remainingHold = Math.max(0, (hold.until - noteTime) * 0.001);
		spawnDoubleGhost(char, hold.anim, remainingHold, hold.anim == currentAnim);
		spawned++;
	}

	return spawned;
}

function canSpawnAnimAtTime(pool:Dynamic, animName:String, strumTime:Float):Bool {
	if (pool == null || animName == null)
		return false;

	if (pool.lastSpawnTime != strumTime) {
		pool.lastSpawnTime = strumTime;
		pool.spawnedAnims = [];
	}

	if (pool.spawnedAnims.indexOf(animName) >= 0)
		return false;

	pool.spawnedAnims.push(animName);
	return true;
}

function onDoubleNoteGhostScriptedAnim(char:Character, animName:String) {
	if (char == null || animName == null || animName == "" || !char.hasAnimation(animName))
		return;

	var pool = getCharPool(char);
	if (!canSpawnAnimAtTime(pool, animName, Conductor.songPosition))
		return;

	spawnDoubleGhost(char, animName, 0, false);
}

function getEchoPool(char:Character):Dynamic {
	for (pool in doubleGhostEchoPools)
		if (pool.char == char)
			return pool;

	var pool = {
		char: char,
		ghosts: [],
		active: [],
		index: 0
	};
	doubleGhostEchoPools.push(pool);
	return pool;
}

function getEchoShader():CustomShader {
	if (doubleGhostEchoShader == null)
		doubleGhostEchoShader = new CustomShader("EchoEffect");
	return doubleGhostEchoShader;
}

function getEchoGhost(pool:Dynamic, char:Character):FunkinSprite {
	if (pool.ghosts.length < doubleGhostEchoMaxPerChar) {
		var ghost:FunkinSprite = FunkinSprite.copyFrom(char);
		ghost.active = false;
		pool.ghosts.push(ghost);
		return ghost;
	}

	var ghost:FunkinSprite = pool.ghosts[pool.index];
	pool.index = (pool.index + 1) % pool.ghosts.length;
	FlxTween.cancelTweensOf(ghost);
	return ghost;
}

function onDoubleNoteGhostEchoTrail(char:Character, behindChar:Character = null) {
	if (char == null || !char.visible || !char.isOnScreen())
		return;

	var animName = getCurrentAnimName(char);
	if (animName == null || !char.hasAnimation(animName))
		return;

	var pool = getEchoPool(char);
	var ghost = getEchoGhost(pool, char);
	copyPoseToGhost(ghost, char, animName, true);
	ghost.x -= 20;
	ghost.y -= 20;
	ghost.shader = getEchoShader();
	ghost.alpha = Math.min(char.alpha * doubleGhostEchoAlpha, doubleGhostEchoAlpha);
	ghost.colorTransform.redMultiplier = 1;
	ghost.colorTransform.greenMultiplier = 1;
	ghost.colorTransform.blueMultiplier = 1;
	ghost.colorTransform.alphaMultiplier = 1;
	ghost.colorTransform.redOffset = 0;
	ghost.colorTransform.greenOffset = 0;
	ghost.colorTransform.blueOffset = 0;
	ghost.colorTransform.alphaOffset = 0;

	var charIndex = members.indexOf(char);
	var behindIndex = behindChar == null ? -1 : members.indexOf(behindChar);
	var insertIndex = charIndex;
	if (behindIndex >= 0 && (insertIndex < 0 || behindIndex < insertIndex))
		insertIndex = behindIndex;
	if (members.indexOf(ghost) >= 0)
		remove(ghost, true);
	insert(insertIndex < 0 ? members.length : insertIndex, ghost);

	pool.active.remove(ghost);
	pool.active.push(ghost);
	FlxTween.tween(ghost, {alpha: 0}, doubleGhostEchoDuration, {
		ease: FlxEase.cubeOut,
		onComplete: function(_) {
			recycleEchoGhost(pool, ghost);
		}
	});
}

function recycleEchoGhost(pool:Dynamic, ghost:FunkinSprite) {
	if (pool != null && pool.active != null)
		pool.active.remove(ghost);
	if (ghost == null)
		return;

	ghost.visible = false;
	ghost.alpha = 0;
	ghost.kill();
	if (members.indexOf(ghost) >= 0)
		remove(ghost, true);
}

function getLineGhostData(line):Dynamic {
	if (line == null || strumLines == null || strumLines.members == null)
		return null;

	var index = strumLines.members.indexOf(line);
	if (index < 0)
		return null;

	while (doubleGhostLineData.length <= index)
		doubleGhostLineData.push(null);

	if (doubleGhostLineData[index] == null)
		doubleGhostLineData[index] = {
			lastTime: -9999.0,
			lastID: -1,
			lastHoldTime: 0.0
		};

	return doubleGhostLineData[index];
}

function getCurrentAnimName(char:Character):String {
	if (char == null || char.animation == null || char.animation.curAnim == null)
		return null;
	return char.animation.curAnim.name;
}

function isActuallySinging(char:Character):Bool {
	return char != null
		&& char.visible
		&& char.animation != null
		&& char.animation.curAnim != null
		&& char.animation.curAnim.name.indexOf("sing") != -1
		&& !char.animation.curAnim.finished;
}

function getCurrentAnimHoldTime(char:Character):Float {
	if (char == null || char.animation == null || char.animation.curAnim == null)
		return 0;

	var anim = char.animation.curAnim;
	if (anim.frameRate <= 0 || anim.numFrames <= 0)
		return 0;

	var framesLeft = Math.max(0, anim.numFrames - anim.curFrame - 1);
	return framesLeft / anim.frameRate;
}

function getBestHoldTime(event, char:Character):Float {
	return getGhostHoldTime(event);
}

function isIdleAnim(animName:String):Bool {
	return animName == null
		|| animName == ""
		|| animName == "idle"
		|| animName == "danceLeft"
		|| animName == "danceRight"
		|| StringTools.startsWith(animName, "idle-")
		|| StringTools.startsWith(animName, "danceLeft-")
		|| StringTools.startsWith(animName, "danceRight-");
}

function isSpecialConflictAnim(animName:String):Bool {
	if (animName == null) return false;
	var lowerAnim = animName.toLowerCase();
	return StringTools.contains(lowerAnim, "-block")
		|| StringTools.contains(lowerAnim, "-parry")
		|| StringTools.contains(lowerAnim, "-dodge")
		|| StringTools.startsWith(lowerAnim, "block")
		|| StringTools.startsWith(lowerAnim, "parry")
		|| StringTools.startsWith(lowerAnim, "dodge")
		|| StringTools.startsWith(lowerAnim, "shoot")
		|| StringTools.startsWith(lowerAnim, "fist");
}

function shouldGhostCurrentAnim(char:Character, pool:Dynamic, currentAnim:String, nextAnim:String):Bool {
	if (currentAnim == null || currentAnim == nextAnim || isIdleAnim(currentAnim))
		return false;
	if (!char.hasAnimation(currentAnim))
		return false;

	return isSpecialConflictAnim(currentAnim)
		|| (pool.lastObservedAnimName != null && pool.lastObservedAnimName != currentAnim);
}

function isSingLikeAnim(animName:String):Bool {
	if (animName == null) return false;
	return StringTools.startsWith(animName.toLowerCase(), "sing");
}

function shouldSpawnObservedAnimGhost(previousAnim:String, currentAnim:String, char:Character):Bool {
	if (previousAnim == null || currentAnim == null || previousAnim == currentAnim)
		return false;
	if (isIdleAnim(previousAnim) || isIdleAnim(currentAnim))
		return false;
	if (char == null || !char.hasAnimation(previousAnim))
		return false;

	return isSpecialConflictAnim(previousAnim)
		|| isSpecialConflictAnim(currentAnim)
		|| (isSingLikeAnim(previousAnim) && isSingLikeAnim(currentAnim));
}

function spawnDoubleGhost(char:Character, animName:String, holdTime:Float, copyCurrentFrame:Bool = false, snapshotFrame:Int = 0) {
	if (char == null || animName == null || !char.isOnScreen())
		return;

	var pool = getCharPool(char);
	if (hasActiveGhostAnim(pool, animName))
		return;

	var ghost = getGhost(pool, char);
	copyPoseToGhost(ghost, char, animName, copyCurrentFrame, snapshotFrame);
	if (holdTime > 0)
		addFollowGhost(ghost, char, holdTime);
	doubleGhostSpawnCount++;

	var charIndex = members.indexOf(char);
	if (members.indexOf(ghost) < 0)
		insert(charIndex < 0 ? members.length : charIndex, ghost);
	else if (charIndex >= 0 && members.indexOf(ghost) > charIndex) {
		remove(ghost, true);
		insert(charIndex, ghost);
	}

	FlxTween.tween(ghost, {alpha: 0}, Math.max(Conductor.crochet * 0.001, 0.001), {
		ease: FlxEase.expoIn,
		startDelay: holdTime,
		onComplete: function(_) {
			ghost.kill();
		}
	});

	debugGhostTrace(char, animName, ghost.getAnimName(), pool, holdTime);
}

function addFollowGhost(ghost:FunkinSprite, char:Character, holdTime:Float) {
	for (data in doubleGhostFollowData)
		if (data.ghost == ghost) {
			data.char = char;
			data.until = Conductor.songPosition + (holdTime * 1000);
			return;
		}

	doubleGhostFollowData.push({
		ghost: ghost,
		char: char,
		until: Conductor.songPosition + (holdTime * 1000)
	});
}

function updateFollowGhosts() {
	var kept:Array<Dynamic> = [];

	for (data in doubleGhostFollowData) {
		var ghost:FunkinSprite = data.ghost;
		var char:Character = data.char;

		if (ghost == null || char == null || !ghost.exists || !ghost.alive)
			continue;
		if (Conductor.songPosition > data.until)
			continue;

		ghost.setPosition(char.x + char.extraOffset.x, char.y + char.extraOffset.y);
		ghost.scrollFactor.copyFrom(char.scrollFactor);
		ghost.cameras = char.cameras;
		kept.push(data);
	}

	doubleGhostFollowData = kept;
}

function debugGhostTrace(char:Character, animName:String, actualAnimName:String, pool:Dynamic, holdTime:Float) {
	trace('[DoubleNoteGhosts] ghost #' + doubleGhostSpawnCount
		+ ' char=' + char.curCharacter
		+ ' anim=' + animName
		+ ' actual=' + actualAnimName
		+ ' hold=' + holdTime
		+ ' activePool=' + countActiveGhosts(pool)
		+ '/' + pool.ghosts.length);
}

function countActiveGhosts(pool:Dynamic):Int {
	var count = 0;
	for (ghost in pool.ghosts)
		if (ghost != null && ghost.exists && ghost.alive)
			count++;
	return count;
}

function trackActiveCharacters() {
	if (strumLines == null || strumLines.members == null)
		return;

	for (line in strumLines.members) {
		if (line == null || line.characters == null)
			continue;

		for (char in line.characters)
			if (char != null)
				getCharPool(char);
	}
}

function rememberNoteEvent(event) {
	for (char in getVCCharacters(event)) {
		if (char == null)
			continue;

		var pool = getCharPool(char);
		var eventAnim = getEventAnimName(char, event);
		spawnActiveHoldInterruptGhosts(char, pool, event, eventAnim);
		pool.lastTime = event.note.strumTime;
		pool.lastAnimName = eventAnim;
		pool.lastHoldTime = getGhostHoldTime(event);
		updateActiveHold(pool, event, pool.lastAnimName);
	}
}

function handleDoubleGhostHit(event) {
	if (event == null || event.note == null)
		return;

	if (event.note.isSustainNote)
		return;

	var lineData = getLineGhostData(event.note.strumLine);
	if (lineData == null)
		return;

	var noteHoldTime = getGhostHoldTime(event);
	var doDouble = (event.note.strumTime - lineData.lastTime) <= 2
		&& event.note.noteData != lineData.lastID;

	lineData.lastTime = event.note.strumTime;
	lineData.lastID = event.note.noteData;
	var pairHoldTime = Math.max(noteHoldTime, lineData.lastHoldTime);
	lineData.lastHoldTime = noteHoldTime;

	if (!doDouble) {
		rememberNoteEvent(event);
		return;
	}

	for (char in getVCCharacters(event)) {
		if (char == null)
			continue;

		if (!isActuallySinging(char))
			continue;

		var pool = getCharPool(char);
		var currentAnim = getCurrentAnimName(char);
		var eventAnim = getEventAnimName(char, event);
		spawnActiveHoldInterruptGhosts(char, pool, event, eventAnim);
		var ghostAnim:String = pool.lastTime == event.note.strumTime && pool.lastAnimName != null
			? pool.lastAnimName
			: currentAnim;
		if (!canSpawnAnimAtTime(pool, ghostAnim, event.note.strumTime))
			continue;

		spawnDoubleGhost(char, ghostAnim, Math.max(pairHoldTime, pool.lastHoldTime), ghostAnim == currentAnim);

		pool.lastTime = event.note.strumTime;
		pool.lastAnimName = eventAnim == null ? ghostAnim : eventAnim;
		pool.lastHoldTime = noteHoldTime;
		pool.lastObservedAnimName = currentAnim;
		updateActiveHold(pool, event, pool.lastAnimName);
	}
}

function onNoteHit(event) {
	handleDoubleGhostHit(event);
}

function postUpdate(elapsed:Float) {
	if (doubleGhostPools.length <= 0 && doubleGhostFollowData.length <= 0)
		return;

	trackActiveCharacters();
	updateFollowGhosts();

	for (pool in doubleGhostPools) {
		if (pool == null || pool.char == null)
			continue;

		var char:Character = pool.char;
		var currentAnim = getCurrentAnimName(char);

		pool.lastObservedAnimName = currentAnim;
		pool.lastObservedFrame = char.globalCurFrame;
		pool.lastObservedHoldTime = getCurrentAnimHoldTime(char);
	}
}

function destroy() {
	for (pool in doubleGhostPools) {
		for (ghost in pool.ghosts) {
			FlxTween.cancelTweensOf(ghost);
			if (members.indexOf(ghost) >= 0)
				remove(ghost, true);
			ghost.destroy();
		}
	}
	for (pool in doubleGhostEchoPools) {
		for (ghost in pool.ghosts) {
			FlxTween.cancelTweensOf(ghost);
			if (members.indexOf(ghost) >= 0)
				remove(ghost, true);
			ghost.destroy();
		}
	}
	doubleGhostPools = [];
	doubleGhostLineData = [];
	doubleGhostFollowData = [];
	doubleGhostEchoPools = [];
}
