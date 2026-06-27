var targetX:Float = 0;
var targetY:Float = 0;
var lastAppliedX:Float = 0;
var lastAppliedY:Float = 0;
var hasStagePosition:Bool = false;
var count:Float = 100;

function update(elapsed:Float) {
	if (!hasStagePosition || x != lastAppliedX || y != lastAppliedY) {
		targetX = x;
		targetY = y;
		hasStagePosition = true;
	}

	count += 50 * elapsed;
	var what = count / 6;

	x = targetX + Math.cos(what / 4) * 20;
	y = targetY + Math.cos(what / 6) * 40;
	lastAppliedX = x;
	lastAppliedY = y;
}
