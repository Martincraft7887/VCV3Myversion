import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import funkin.backend.shaders.CustomShader;
import StringTools;

var doubleGhostPools:Array<Dynamic> = [];
var doubleGhostFollowData:Array<Dynamic> = [];
var doubleGhostEchoPools:Array<Dynamic> = [];
var doubleGhostEchoShader:CustomShader = null;
var doubleGhostEchoMaxPerChar:Int = 24;
var doubleGhostEchoAlpha:Float = 0.35;
var doubleGhostEchoDuration:Float = 0.35;
var doubleGhostMaxPerChar:Int = 8;
var doubleGhostAlpha:Float = 0.5;
var doubleGhostShuttingDown:Bool = false;

function doubleGhostPlayStateIsAlive():Bool {
	return !doubleGhostShuttingDown
		&& PlayState.instance != null
		&& FlxG.state == PlayState.instance;
}

function getCharPool(char:Character):Dynamic {
	for (pool in doubleGhostPools)
		if (pool.char == char)
			return pool;

	var pool = {
		char: char,
		lastTime: Math.NEGATIVE_INFINITY,
		lastID: -1,
		lastAnimName: null,
		lastHoldTime: 0.0,
		lastSpawnTime: Math.NEGATIVE_INFINITY,
		spawnedAnims: [],
		activeHolds: [],
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

function copyIndependentGhostAnimOffsets(ghost:FunkinSprite, char:Character) {
	if (ghost == null || char == null || char.animOffsets == null)
		return;

	// FunkinSprite.copyFrom() and Map.copy() are shallow: their FlxPoints would
	// still belong to the Character. Ghost destruction would then return those
	// live points to the pool and corrupt the character's singing offsets.
	if (ghost.extra != null && ghost.extra.exists("vcOwnedGhostAnimOffsets") && ghost.animOffsets != null) {
		var oldNames:Array<String> = [];
		for (name in ghost.animOffsets.keys())
			oldNames.push(name);
		for (name in oldNames) {
			var oldPoint = ghost.animOffsets.get(name);
			ghost.animOffsets.remove(name);
			if (oldPoint != null)
				oldPoint.put();
		}
	}

	var copiedOffsets = char.animOffsets.copy();
	for (name in copiedOffsets.keys()) {
		var sourcePoint = copiedOffsets.get(name);
		// Some character XML animations intentionally have no offset entry. The
		// copied map keeps that animation usable instead of dereferencing null.
		if (sourcePoint == null)
			copiedOffsets.set(name, FlxPoint.get());
		else
			copiedOffsets.set(name, FlxPoint.get(sourcePoint.x, sourcePoint.y));
	}
	ghost.animOffsets = copiedOffsets;
	ghost.extra.set("vcOwnedGhostAnimOffsets", true);
}

function copyCharacterDrawOrientationToGhost(ghost:FunkinSprite, char:Character) {
	ghost.scale.copyFrom(char.scale);
	ghost.flipX = char.flipX;
	ghost.flipY = char.flipY;

	// Character.draw() temporarily performs these two changes when the chart
	// side (isPlayer) does not match the XML offset side (playerOffsets). A
	// pooled FunkinSprite has no Character.draw(), so it must keep the effective
	// draw values itself or every ghost is mirrored around the wrong origin.
	if (char.isFlippedOffsets()) {
		ghost.flipX = !char.flipX;
		ghost.scale.x = -char.scale.x;
	}
}

function copyPoseToGhost(ghost:FunkinSprite, char:Character, animName:String, copyCurrentFrame:Bool = false, snapshotFrame:Int = 0) {
	ghost.setPosition(char.x + char.extraOffset.x, char.y + char.extraOffset.y);
	ghost.frames = char.frames;
	ghost.animation.copyFrom(char.animation);
	copyIndependentGhostAnimOffsets(ghost, char);
	ghost.playAnim(animName, true);
	var copiedCurrentAnim = getCurrentAnimName(char) == animName;
	ghost.globalCurFrame = copyCurrentFrame ? (copiedCurrentAnim ? char.globalCurFrame : snapshotFrame) : 0;
	var animOffset = ghost.getAnimOffset(animName);
	ghost.frameOffset.set(animOffset.x, animOffset.y);
	animOffset.putWeak();
	ghost.offset.copyFrom(char.offset);
	ghost.origin.copyFrom(char.origin);
	ghost.scrollFactor.copyFrom(char.scrollFactor);
	ghost.cameras = char.cameras;
	copyCharacterDrawOrientationToGhost(ghost, char);
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
	if (char.transformMatrix != null) {
		var independentMatrix = new FlxMatrix();
		independentMatrix.copyFrom(char.transformMatrix);
		ghost.transformMatrix = independentMatrix;
	}
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
	if (!doubleGhostPlayStateIsAlive())
		return;

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
	if (!doubleGhostPlayStateIsAlive())
		return;

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
			if (doubleGhostPlayStateIsAlive())
				recycleEchoGhost(pool, ghost);
		}
	});
}

function onGhostTrailSnapshot(char:Character, ghostAlpha:Float = 0.35, ghostDuration:Float = 0.75, behindChar:Character = null) {
	if (!doubleGhostPlayStateIsAlive())
		return;

	if (char == null || !char.visible || !char.isOnScreen())
		return;

	var animName = getCurrentAnimName(char);
	if (animName == null || !char.hasAnimation(animName))
		return;

	var pool = getEchoPool(char);
	var ghost = getEchoGhost(pool, char);
	copyPoseToGhost(ghost, char, animName, true);

	// This trail is a clean character snapshot: no EchoEffect shader and no
	// positional offset. Restore the exact visual state after copyPoseToGhost(),
	// which normally applies the shared double-note ghost alpha limit.
	ghost.shader = char.shader;
	ghost.alpha = char.alpha * Math.max(0, Math.min(ghostAlpha, 1));
	ghost.colorTransform.redMultiplier = char.colorTransform.redMultiplier;
	ghost.colorTransform.greenMultiplier = char.colorTransform.greenMultiplier;
	ghost.colorTransform.blueMultiplier = char.colorTransform.blueMultiplier;
	ghost.colorTransform.alphaMultiplier = char.colorTransform.alphaMultiplier;
	ghost.colorTransform.redOffset = char.colorTransform.redOffset;
	ghost.colorTransform.greenOffset = char.colorTransform.greenOffset;
	ghost.colorTransform.blueOffset = char.colorTransform.blueOffset;
	ghost.colorTransform.alphaOffset = char.colorTransform.alphaOffset;

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
	FlxTween.tween(ghost, {alpha: 0}, Math.max(ghostDuration, 0.05), {
		ease: FlxEase.cubeOut,
		onComplete: function(_) {
			if (doubleGhostPlayStateIsAlive())
				recycleEchoGhost(pool, ghost);
		}
	});
}

function recycleEchoGhost(pool:Dynamic, ghost:FunkinSprite) {
	// FlxTween is global: an onComplete can arrive just after returning from a
	// Charter playtest, when the old PlayState.members has already become null.
	if (!doubleGhostPlayStateIsAlive())
		return;

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

function getCurrentAnimName(char:Character):String {
	if (char == null || char.animation == null || char.animation.curAnim == null)
		return null;
	return char.animation.curAnim.name;
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

function isDodgeBlockAnim(animName:String):Bool {
	if (animName == null) return false;
	var lowerAnim = animName.toLowerCase();
	return StringTools.contains(lowerAnim, "-dodge")
		|| StringTools.contains(lowerAnim, "-block")
		|| StringTools.contains(lowerAnim, "-parry")
		|| StringTools.startsWith(lowerAnim, "dodge")
		|| StringTools.startsWith(lowerAnim, "block")
		|| StringTools.startsWith(lowerAnim, "parry");
}

function getDoubleSpecialAnim(char:Character, event, eventAnim:String):String {
	if (char == null || event == null)
		return null;

	if (eventAnim != null && isDodgeBlockAnim(eventAnim) && char.hasAnimation(eventAnim))
		return eventAnim;

	var suffix:String = event.animSuffix == null ? "" : Std.string(event.animSuffix);
	if (suffix == "")
		return null;

	var lowerSuffix = suffix.toLowerCase();
	if (!StringTools.contains(lowerSuffix, "dodge")
		&& !StringTools.contains(lowerSuffix, "block")
		&& !StringTools.contains(lowerSuffix, "parry"))
		return null;

	return getFirstExistingAnim(char, getAnimCandidates(char, event.direction, suffix));
}

function spawnDoubleGhost(char:Character, animName:String, holdTime:Float, copyCurrentFrame:Bool = false, snapshotFrame:Int = 0) {
	if (!doubleGhostPlayStateIsAlive())
		return;

	if (char == null || animName == null || !char.isOnScreen())
		return;

	var pool = getCharPool(char);
	if (hasActiveGhostAnim(pool, animName))
		return;

	var ghost = getGhost(pool, char);
	copyPoseToGhost(ghost, char, animName, copyCurrentFrame, snapshotFrame);
	if (holdTime > 0)
		addFollowGhost(ghost, char, holdTime);

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
			if (doubleGhostPlayStateIsAlive() && ghost != null)
				ghost.kill();
		}
	});
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
		copyCharacterDrawOrientationToGhost(ghost, char);
		ghost.scrollFactor.copyFrom(char.scrollFactor);
		ghost.cameras = char.cameras;
		kept.push(data);
	}

	doubleGhostFollowData = kept;
}

function handleDoubleGhostHit(event) {
	if (!doubleGhostPlayStateIsAlive())
		return;

	if (event == null || event.note == null)
		return;

	if (event.note.isSustainNote)
		return;

	var noteHoldTime = getGhostHoldTime(event);
	var noteTime:Float = event.note.strumTime;
	var noteID:Int = event.note.noteData;

	for (char in getVCCharacters(event)) {
		if (char == null)
			continue;

		var pool = getCharPool(char);
		var currentAnim = getCurrentAnimName(char);
		var eventAnim = getEventAnimName(char, event);
		var doDouble = Math.abs(noteTime - pool.lastTime) <= 2 && noteID != pool.lastID;
		var pairHoldTime = Math.max(noteHoldTime, pool.lastHoldTime);

		if (!doDouble) {
			spawnActiveHoldInterruptGhosts(char, pool, event, eventAnim);
			pool.lastTime = noteTime;
			pool.lastID = noteID;
			pool.lastAnimName = eventAnim;
			pool.lastHoldTime = noteHoldTime;
			updateActiveHold(pool, event, pool.lastAnimName);
			continue;
		}

		spawnActiveHoldInterruptGhosts(char, pool, event, eventAnim);
		var specialAnim = getDoubleSpecialAnim(char, event, eventAnim);
		var ghostAnim:String = specialAnim != null
			? specialAnim
			: (Math.abs(noteTime - pool.lastTime) <= 2 && pool.lastAnimName != null ? pool.lastAnimName : currentAnim);

		if (ghostAnim == null || isIdleAnim(ghostAnim) || !char.hasAnimation(ghostAnim)) {
			pool.lastTime = noteTime;
			pool.lastID = noteID;
			pool.lastAnimName = eventAnim == null ? ghostAnim : eventAnim;
			pool.lastHoldTime = noteHoldTime;
			updateActiveHold(pool, event, pool.lastAnimName);
			continue;
		}

		if (canSpawnAnimAtTime(pool, ghostAnim, event.note.strumTime)) {
			spawnDoubleGhost(char, ghostAnim, Math.max(pairHoldTime, pool.lastHoldTime), ghostAnim == currentAnim);
		}

		pool.lastTime = noteTime;
		pool.lastID = noteID;
		pool.lastAnimName = eventAnim == null ? ghostAnim : eventAnim;
		pool.lastHoldTime = noteHoldTime;
		updateActiveHold(pool, event, pool.lastAnimName);
	}
}

function onNoteHit(event) {
	handleDoubleGhostHit(event);
}

function postUpdate(elapsed:Float) {
	if (!doubleGhostPlayStateIsAlive())
		return;

	if (doubleGhostFollowData.length <= 0)
		return;

	updateFollowGhosts();
}

function destroy() {
	// Mark teardown before cancelling anything. A callback already queued by
	// Flixel will see this and cannot access the destroyed PlayState.
	doubleGhostShuttingDown = true;

	for (pool in doubleGhostPools) {
		for (ghost in pool.ghosts) {
			FlxTween.cancelTweensOf(ghost);
			FlxTween.cancelTweensOf(ghost.scale);
			if (members.indexOf(ghost) >= 0)
				remove(ghost, true);
			ghost.destroy();
		}
	}
	for (pool in doubleGhostEchoPools) {
		for (ghost in pool.ghosts) {
			FlxTween.cancelTweensOf(ghost);
			FlxTween.cancelTweensOf(ghost.scale);
			if (members.indexOf(ghost) >= 0)
				remove(ghost, true);
			ghost.destroy();
		}
	}
	doubleGhostPools = [];
	doubleGhostFollowData = [];
	doubleGhostEchoPools = [];
}
