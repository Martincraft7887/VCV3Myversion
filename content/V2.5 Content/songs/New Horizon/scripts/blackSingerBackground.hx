import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

var singerBackground:FlxSprite = null;

function postCreate() {
	singerBackground = new FlxSprite();
	singerBackground.makeGraphic(1, 1, 0xFF000000);
	singerBackground.setGraphicSize(5000, 5000);
	singerBackground.updateHitbox();
	singerBackground.screenCenter();
	singerBackground.scrollFactor.set();
	singerBackground.cameras = [camGame];
	singerBackground.alpha = 0;

	// New Horizon uses lines 0 and 1 for VoiidShaggyxm/MW and Taro.
	// Inserting the background immediately before the first of those characters
	// hides the stage and GF while leaving all three singers above the black layer.
	var singerIndex = getFirstSingerIndex();
	if (singerIndex < members.length)
		insert(singerIndex, singerBackground);
	else
		add(singerBackground);
}

function getFirstSingerIndex():Int {
	var firstIndex = members.length;

	for (lineIndex in [0, 1]) {
		if (lineIndex >= strumLines.members.length) continue;

		var line = strumLines.members[lineIndex];
		if (line == null || line.characters == null) continue;

		for (char in line.characters) {
			if (char == null) continue;

			var charIndex = members.indexOf(char);
			if (charIndex >= 0 && charIndex < firstIndex)
				firstIndex = charIndex;
		}
	}

	return firstIndex;
}

function stepHit() {
	if (singerBackground == null) return;

	if (curStep == 1022) {
		FlxTween.cancelTweensOf(singerBackground);
		singerBackground.alpha = 0;
		FlxTween.tween(singerBackground, {alpha: 1}, Conductor.stepCrochet * 0.001 * 4, {
			ease: FlxEase.linear
		});
	} else if (curStep == 1280) {
		FlxTween.cancelTweensOf(singerBackground);
		singerBackground.alpha = 0;
	}
}

function destroy() {
	if (singerBackground != null)
		FlxTween.cancelTweensOf(singerBackground);
}
