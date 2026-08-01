import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.backend.FunkinSprite;
import openfl.display.BlendMode;

var angleMoveGhosts:Array<FunkinSprite> = [];
var lastAngleGhostStep:Int = -999999;
var angleMoveGhostsShuttingDown:Bool = false;

var ANGLE_SECTION_START:Int = 1024;
var ANGLE_SECTION_END:Int = 1280;
var ANGLE_PATTERN_LENGTH:Int = 32;
var ANGLE_GHOST_DURATION_STEPS:Float = 8;
var ANGLE_GHOST_SCALE:Float = 2.5;
var ANGLE_GHOST_ALPHA:Float = 0.7;

var TARO_GHOST_COLOR:Int = 0xFFFFB7A8;
var MW_GHOST_COLOR:Int = 0xFF000B8D;
var SHAGGY_GHOST_COLOR:Int = 0xFFDB450B;

function angleMoveGhostPlayStateIsAlive():Bool {
	return !angleMoveGhostsShuttingDown
		&& PlayState.instance != null
		&& FlxG.state == PlayState.instance;
}

function isAngleMoveGhostStep(step:Int):Bool {
	if (step < ANGLE_SECTION_START || step >= ANGLE_SECTION_END)
		return false;

	// Los giros y movimientos Y del XML se repiten cada 32 steps en 0, 6 y 12.
	var phase = (step - ANGLE_SECTION_START) % ANGLE_PATTERN_LENGTH;
	return phase == 0 || phase == 6 || phase == 12;
}

function trySpawnAngleMoveGhosts(step:Int) {
	if (!angleMoveGhostPlayStateIsAlive()
		|| step == lastAngleGhostStep
		|| !isAngleMoveGhostStep(step))
		return;

	lastAngleGhostStep = step;
	spawnAngleMoveGhosts();
}

function stepHit() {
	trySpawnAngleMoveGhosts(curStep);
}

// Respaldo para builds donde otro script consume o altera la llamada de stepHit.
function postUpdate(elapsed:Float) {
	trySpawnAngleMoveGhosts(curStep);
}

function spawnAngleMoveGhosts() {
	if (strumLines == null || strumLines.members == null)
		return;

	// Línea 0: VoiidShaggyxm y MW.
	if (strumLines.members.length > 0 && strumLines.members[0] != null) {
		var opponents = strumLines.members[0].characters;
		if (opponents != null) {
			if (opponents.length > 0)
				spawnAngleMoveGhost(opponents[0], SHAGGY_GHOST_COLOR);
			if (opponents.length > 1)
				spawnAngleMoveGhost(opponents[1], MW_GHOST_COLOR);
		}
	}

	// Línea 1: Taro.
	if (strumLines.members.length > 1 && strumLines.members[1] != null) {
		var players = strumLines.members[1].characters;
		if (players != null && players.length > 0)
			spawnAngleMoveGhost(players[0], TARO_GHOST_COLOR);
	}
}

function copyAngleGhostAnimOffsets(char:Character):Map<String, FlxPoint> {
	var copiedOffsets:Map<String, FlxPoint> = [];
	if (char.animOffsets == null)
		return copiedOffsets;

	for (name in char.animOffsets.keys()) {
		var sourcePoint = char.animOffsets.get(name);
		if (sourcePoint != null)
			copiedOffsets.set(name, FlxPoint.get(sourcePoint.x, sourcePoint.y));
	}
	return copiedOffsets;
}

function getAngleGhostAnimName(char:Character):String {
	if (char == null)
		return null;

	var animName:String = char.getAnimName();
	if (animName != null && char.hasAnimation(animName))
		return animName;

	// Una captura idle sigue siendo preferible a cancelar el efecto por completo.
	if (char.hasAnimation("idle"))
		return "idle";
	return null;
}

function copyCurrentAngleGhostFrame(ghost:FunkinSprite, char:Character) {
	if (ghost == null || char == null)
		return;

	// Los tres personajes de New Horizon usan spritesheets normales.
	if (char.animation != null && char.animation.curAnim != null
		&& ghost.animation != null && ghost.animation.curAnim != null) {
		ghost.animation.curAnim.curFrame = char.animation.curAnim.curFrame;
	}
}

function spawnAngleMoveGhost(char:Character, tint:Int) {
	if (char == null)
		return;

	var animName = getAngleGhostAnimName(char);
	if (animName == null)
		return;

	var ghost:FunkinSprite = FunkinSprite.copyFrom(char);
	ghost.animOffsets = copyAngleGhostAnimOffsets(char);
	ghost.setPosition(char.x, char.y);
	ghost.playAnim(animName, true);
	copyCurrentAngleGhostFrame(ghost, char);

	ghost.offset.copyFrom(char.offset);
	ghost.frameOffset.copyFrom(char.frameOffset);
	ghost.origin.copyFrom(char.origin);
	ghost.scale.copyFrom(char.scale);
	ghost.scrollFactor.copyFrom(char.scrollFactor);
	ghost.cameras = char.cameras;
	ghost.flipX = char.flipX;
	ghost.flipY = char.flipY;
	ghost.angle = char.angle;
	ghost.skew.set(char.skew.x, char.skew.y);
	if (char.transformMatrix != null) {
		var independentMatrix = new FlxMatrix();
		independentMatrix.copyFrom(char.transformMatrix);
		ghost.transformMatrix = independentMatrix;
	}
	ghost.matrixExposed = char.matrixExposed;

	// Silueta plana: el color no se multiplica por los píxeles oscuros del char.
	ghost.shader = null;
	ghost.blend = BlendMode.NORMAL;
	ghost.color = 0xFFFFFFFF;
	ghost.colorTransform.redMultiplier = 0;
	ghost.colorTransform.greenMultiplier = 0;
	ghost.colorTransform.blueMultiplier = 0;
	ghost.colorTransform.alphaMultiplier = 1;
	ghost.colorTransform.redOffset = (tint >> 16) & 0xFF;
	ghost.colorTransform.greenOffset = (tint >> 8) & 0xFF;
	ghost.colorTransform.blueOffset = tint & 0xFF;
	ghost.colorTransform.alphaOffset = 0;
	ghost.alpha = ANGLE_GHOST_ALPHA;
	ghost.visible = true;
	ghost.active = false;
	ghost.antialiasing = char.antialiasing;
	ghost.revive();

	var charIndex = members.indexOf(char);
	insert(charIndex < 0 ? members.length : charIndex + 1, ghost);
	angleMoveGhosts.push(ghost);

	var duration = Math.max(Conductor.stepCrochet * 0.001 * ANGLE_GHOST_DURATION_STEPS, 0.1);
	var targetScaleX = ghost.scale.x * ANGLE_GHOST_SCALE;
	var targetScaleY = ghost.scale.y * ANGLE_GHOST_SCALE;

	FlxTween.tween(ghost.scale, {x: targetScaleX, y: targetScaleY}, duration, {
		ease: FlxEase.circOut
	});
	FlxTween.tween(ghost, {alpha: 0}, duration, {
		ease: FlxEase.cubeIn,
		onComplete: function(_) {
			if (angleMoveGhostPlayStateIsAlive())
				removeAngleMoveGhost(ghost);
		}
	});
}

function removeAngleMoveGhost(ghost:FunkinSprite) {
	if (!angleMoveGhostPlayStateIsAlive() || ghost == null)
		return;

	FlxTween.cancelTweensOf(ghost);
	FlxTween.cancelTweensOf(ghost.scale);
	angleMoveGhosts.remove(ghost);
	if (members.indexOf(ghost) >= 0)
		remove(ghost, true);
	ghost.destroy();
}

function destroy() {
	angleMoveGhostsShuttingDown = true;

	for (ghost in angleMoveGhosts.copy()) {
		if (ghost == null)
			continue;
		FlxTween.cancelTweensOf(ghost);
		FlxTween.cancelTweensOf(ghost.scale);
		if (members.indexOf(ghost) >= 0)
			remove(ghost, true);
		ghost.destroy();
	}
	angleMoveGhosts = [];
}
