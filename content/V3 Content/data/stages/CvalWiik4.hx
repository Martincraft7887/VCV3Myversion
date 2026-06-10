var blimp:Dynamic = null;
var blimpPos:Float = 0;
var blimpMaxX:Float = 1200;
var blimpMinX:Float = 0;
var reverse:Bool = false;
var initialized:Bool = false;

function initBlimp() {
	if (initialized) return;
	if (blimp == null) return;

	blimpPos = FlxG.random.float(800, 1200);
	blimp.x = blimpPos;
	initialized = true;
	trace("[CvalWiik4] stage script loaded. blimpPos=" + blimpPos);
}

function update(elapsed:Float) {
	initBlimp();
	if (!initialized || blimp == null) return;

	if (reverse) {
		blimpPos += elapsed * 4;
	} else {
		blimpPos -= elapsed * 4;
	}

	blimp.x = blimpPos;
}
