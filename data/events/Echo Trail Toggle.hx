import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

public var disableGhosts:Bool = false;

// ===== CONFIG =====
var MAX_PER_CHAR:Int = 8;

var ghostPools:Map<String, Array<Character>> = [];
var activeGhosts:Map<String, Array<Character>> = [];

var echoShader:CustomShader;

// =======================================================
// INIT
// =======================================================

function postCreate() {
	echoShader = new CustomShader("EchoEffect");
}

// =======================================================
// CHECK SING
// =======================================================

function isActuallySinging(char:Character):Bool {
	return char != null
		&& char.animation != null
		&& char.animation.curAnim != null
		&& char.animation.curAnim.name.indexOf("sing") != -1
		&& !char.animation.curAnim.finished;
}

// =======================================================
// NOTE HIT
// =======================================================

function onNoteHit(event:NoteHitEvent) {

	if (disableGhosts) return;

	for (character in event.note.strumLine.characters) {

		if (character.visible && isActuallySinging(character)) {
			spawnGhost(character, event.note.noteData);
			break;
		}
	}
}

// =======================================================
// POOLS
// =======================================================

function getPool(id:String):Array<Character> {
	if (!ghostPools.exists(id))
		ghostPools.set(id, []);
	return ghostPools.get(id);
}

function getActive(id:String):Array<Character> {
	if (!activeGhosts.exists(id))
		activeGhosts.set(id, []);
	return activeGhosts.get(id);
}

// =======================================================
// GET GHOST
// =======================================================

function getGhost(char:Character):Character {

	var id = char.curCharacter;
	var pool = getPool(id);
	var active = getActive(id);

	if (pool.length > 0)
		return pool.shift();

	if (active.length >= MAX_PER_CHAR)
		return active.shift();

	return new Character(0, 0, char.curCharacter, char.isPlayer);
}

// =======================================================
// SPAWN
// =======================================================

function spawnGhost(char:Character, dir:Int) {

	var id = char.curCharacter;
	var ghost = getGhost(char);

	ghost.setPosition(char.x, char.y);
	ghost.curCharacter = char.curCharacter;
	ghost.isPlayer = char.isPlayer;

	ghost.color = char.iconColor;
	ghost.alpha = char.alpha * 0.85;
	ghost.scale.set(char.scale.x, char.scale.y);
	ghost.flipX = char.flipX;
	ghost.visible = true;

	ghost.playAnim(char.getAnimName(), false, 'LOCK');
	ghost.holdTime = 9999999;
	ghost.shader = echoShader;

	// ⭐ INSERT EXACTO COMO TU SCRIPT ORIGINAL
	insert(members.indexOf(char), ghost);

	getActive(id).push(ghost);

	FlxTween.tween(ghost, {alpha: 0}, 0.55).onComplete = function(_) {
		recycleGhost(ghost, id);
	};

	moveGhost(ghost, char, dir);
}

// =======================================================
// MOVE
// =======================================================


// =======================================================
// RECYCLE
// =======================================================

function recycleGhost(g:Character, id:String) {

	g.visible = false;
	g.alpha = 0;

	remove(g, true);

	getActive(id).remove(g);
	getPool(id).push(g);
}