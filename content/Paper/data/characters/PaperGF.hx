var speakers:FlxSprite = null;
var lastGFAnim:String = "";
var gfLeatherOffsetX:Float = 50;
var gfLeatherOffsetY:Float = -275;
var speakerLeatherOffsetX:Float = 25;
var speakerLeatherOffsetY:Float = 60;
var speakerTweakY:Float = 55;
var gfBaseScaleX:Float = 1.4;
var gfBaseScaleY:Float = 1.4;
var speakerBaseScale:Float = 1.4;
var speakerStageHeightFix:Float = 420;

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
	speakers.scale.set(speakerBaseScale, speakerBaseScale);
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
	var stageScaleX = getStageScaleX();
	var stageScaleY = getStageScaleY();

	refreshSpeakersScale(stageScaleX, stageScaleY);

	speakers.x = visualX + ((width - speakers.width) * 0.5) + (leatherDiffX * stageScaleX);
	speakers.y = visualY + (height - speakers.height) + ((leatherDiffY + speakerTweakY) * stageScaleY) - getSpeakerStageHeightFix(stageScaleY);
	speakers.scrollFactor.set(scrollFactor.x, scrollFactor.y);
	speakers.cameras = cameras;
	speakers.alpha = alpha;
	speakers.visible = visible;
	speakers.active = active;
	speakers.antialiasing = antialiasing;
}

function getStageScaleX():Float {
	return normalizeStageScale(scale.x / gfBaseScaleX);
}

function getStageScaleY():Float {
	return normalizeStageScale(scale.y / gfBaseScaleY);
}

function normalizeStageScale(value:Float):Float {
	if (value != value || value <= 0) return 1;
	return value;
}

function refreshSpeakersScale(stageScaleX:Float, stageScaleY:Float) {
	var targetScaleX = speakerBaseScale * stageScaleX;
	var targetScaleY = speakerBaseScale * stageScaleY;
	if (speakers.scale.x == targetScaleX && speakers.scale.y == targetScaleY) return;

	speakers.scale.set(targetScaleX, targetScaleY);
	speakers.updateHitbox();
}

function getSpeakerStageHeightFix(stageScaleY:Float):Float {
	if (stageScaleY >= 1) return 0;
	return speakerStageHeightFix * (1 - stageScaleY);
}

function ensureSpeakersLayer() {
	if (FlxG.state == null || FlxG.state.members == null) return;

	var gfIndex = FlxG.state.members.indexOf(this);
	var speakerIndex = FlxG.state.members.indexOf(speakers);

	if (gfIndex < 0) {
		if (speakerIndex >= 0) FlxG.state.remove(speakers, true);
		return;
	}

	if (speakerIndex == gfIndex - 1)
		return;

	if (speakerIndex >= 0)
		FlxG.state.remove(speakers, true);

	gfIndex = FlxG.state.members.indexOf(this);
	if (gfIndex >= 0)
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
