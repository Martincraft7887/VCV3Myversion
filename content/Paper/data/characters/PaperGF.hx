var speakers:FlxSprite = null;
var lastGFAnim:String = "";
var gfLeatherOffsetX:Float = 50;
var gfLeatherOffsetY:Float = -275;
var speakerLeatherOffsetX:Float = 25;
var speakerLeatherOffsetY:Float = 60;
var speakerTweakY:Float = 55;

function postCreate() {
	createSpeakers();
	syncSpeakersAnim(true);
}

function createSpeakers() {
	if (speakers != null) return;

	speakers = new FlxSprite();
	speakers.frames = Paths.getSparrowAtlas("characters/speakers");
	speakers.animation.addByIndices("danceLeft", "speakers", [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
	speakers.animation.addByIndices("danceRight", "speakers", [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
	speakers.scale.set(1.4, 1.4);
	speakers.updateHitbox();
	speakers.antialiasing = antialiasing;
	speakers.animation.play("danceLeft", true);
}

function update(elapsed:Float) {
	if (speakers == null) return;
	ensureSpeakersLayer();
	positionSpeakers();
	syncSpeakersAnim(false);
}

function beatHit(curBeat:Int) {
	if (speakers != null) {
		if (curBeat % 2 == 0)
			speakers.animation.play("danceLeft", true);
		else
			speakers.animation.play("danceRight", true);
	}
}

function dance() {
	if (speakers != null) speakers.animation.play("danceLeft", true);
}

function positionSpeakers() {
	var visualX = x - offset.x;
	var visualY = y - offset.y;
	var leatherDiffX = speakerLeatherOffsetX - gfLeatherOffsetX;
	var leatherDiffY = speakerLeatherOffsetY - gfLeatherOffsetY;

	speakers.x = visualX + ((width - speakers.width) * 0.5) + leatherDiffX;
	speakers.y = visualY + (height - speakers.height) + leatherDiffY + speakerTweakY;
	speakers.scrollFactor.set(scrollFactor.x, scrollFactor.y);
	speakers.cameras = cameras;
	speakers.alpha = alpha;
	speakers.visible = visible;
	speakers.active = active;
	speakers.antialiasing = antialiasing;
}

function ensureSpeakersLayer() {
	if (FlxG.state == null || FlxG.state.members == null) return;

	var gfIndex = FlxG.state.members.indexOf(this);
	var speakerIndex = FlxG.state.members.indexOf(speakers);

	if (gfIndex < 0) {
		if (speakerIndex >= 0) FlxG.state.remove(speakers, true);
		return;
	}

	if (speakerIndex >= 0) FlxG.state.remove(speakers, true);
	gfIndex = FlxG.state.members.indexOf(this);
	FlxG.state.insert(gfIndex, speakers);
}

function syncSpeakersAnim(force:Bool) {
	var animName = getCurrentGFAnim();
	if (animName == lastGFAnim && !force) return;

	lastGFAnim = animName;
	if (animName == "danceRight")
		speakers.animation.play("danceRight", true);
	else
		speakers.animation.play("danceLeft", true);
}

function getCurrentGFAnim():String {
	if (animation == null || animation.curAnim == null) return "";
	return animation.curAnim.name;
}

function destroy() {
	if (speakers != null) {
		if (FlxG.state != null) FlxG.state.remove(speakers, true);
		speakers.destroy();
		speakers = null;
	}
}
