var fadeSpeed:Float = 10;
var singHoldTime:Float = Conductor.stepCrochet * 10 / 1000;
var extraChar:Character;
var extraCharAlpha:Float = 0;
var singTimer:Float = 0;
var enabledExtraCharFade:Bool = false;

function usesExtraCharFade():Bool {
	var song = PlayState.SONG;
	if (song == null || song.meta == null) return false;
	return ["final destination vip", "intervention", "final destination", "final destination god"].contains(song.meta.name.toLowerCase());
}

function postCreate() {
	enabledExtraCharFade = usesExtraCharFade();
	if (!enabledExtraCharFade) {
		disableScript();
		return;
	}

	var playerLine = strumLines.members[1];
	if (playerLine != null && playerLine.characters.length > 1) {
		extraChar = playerLine.characters[1];
		extraChar.alpha = 0;
		extraCharAlpha = 0;
		singTimer = 0;
	}
}

function isSinging(char:Character):Bool {
	if (char == null || char.animation == null || char.animation.curAnim == null) return false;
	return char.animation.curAnim.name.indexOf("sing") != -1;
}

function fadeLerp(a:Float, b:Float, t:Float):Float {
	return a + (b - a) * t;
}

function update(elapsed:Float) {
	if (!enabledExtraCharFade || extraChar == null) return;

	if (isSinging(extraChar))
		singTimer = singHoldTime;
	else
		singTimer -= elapsed;

	var targetAlpha:Float = singTimer > 0 ? 0.7 : 0;
	extraCharAlpha = fadeLerp(extraCharAlpha, targetAlpha, elapsed * fadeSpeed);
	extraChar.alpha = extraCharAlpha;
}
