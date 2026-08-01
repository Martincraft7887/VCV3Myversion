import StringTools;

var ghostTrailAllEnabled:Bool = false;
var ghostTrailAllInterval:Float = 0.5;
var ghostTrailAllAlpha:Float = 0.35;
var ghostTrailAllDuration:Float = 8;
var ghostTrailLineSettings:Map<Int, Dynamic> = [];
var ghostTrailLineTimers:Map<Int, Float> = [];

function onEvent(event) {
	if (event == null || event.event == null || event.event.name != "Ghost Trail")
		return;

	var params = event.event.params;
	var enabled:Bool = params.length > 0 && params[0] == true;
	var target:String = params.length > 1 && params[1] != null
		? Std.string(params[1]).toLowerCase()
		: "all";
	var intervalSteps = getGhostTrailInterval(params.length > 2 ? params[2] : 0.5);
	var ghostAlpha = getGhostTrailAlpha(params.length > 3 ? params[3] : 0.35);
	var durationSteps = getGhostTrailDuration(params.length > 4 ? params[4] : 8);

	setGhostTrailTarget(target, enabled, intervalSteps, ghostAlpha, durationSteps);
}

function getGhostTrailInterval(value:Dynamic):Float {
	var interval = Std.parseFloat(Std.string(value));
	return Math.isNaN(interval) ? 0.5 : Math.max(interval, 0.1);
}

function getGhostTrailAlpha(value:Dynamic):Float {
	var alpha = Std.parseFloat(Std.string(value));
	return Math.isNaN(alpha) ? 0.35 : Math.max(0, Math.min(alpha, 1));
}

function getGhostTrailDuration(value:Dynamic):Float {
	var duration = Std.parseFloat(Std.string(value));
	return Math.isNaN(duration) ? 8 : Math.max(duration, 0.1);
}

function setGhostTrailTarget(target:String, enabled:Bool, intervalSteps:Float, ghostAlpha:Float, durationSteps:Float) {
	if (target == "all") {
		ghostTrailAllEnabled = enabled;
		ghostTrailAllInterval = intervalSteps;
		ghostTrailAllAlpha = ghostAlpha;
		ghostTrailAllDuration = durationSteps;
		ghostTrailLineSettings.clear();
		ghostTrailLineTimers.clear();

		if (enabled)
			spawnGhostTrailForAllLines();
		return;
	}

	var id = getGhostTrailStrumLineID(target);
	if (id < 0)
		return;

	ghostTrailLineSettings.set(id, {
		enabled: enabled,
		interval: intervalSteps,
		alpha: ghostAlpha,
		duration: durationSteps
	});
	ghostTrailLineTimers.set(id, 0);

	if (enabled)
		spawnGhostTrailForLine(id);
}

function getGhostTrailStrumLineID(target:String):Int {
	switch (target) {
		case "opponent" | "opponent1" | "dad" | "strumline0" | "0":
			return 0;
		case "player" | "boyfriend" | "bf" | "strumline1" | "1":
			return 1;
		case "girlfriend" | "gf" | "strumline2" | "2":
			return 2;
		default:
			var rawID = StringTools.startsWith(target, "strumline")
				? target.substr("strumline".length)
				: target;
			var parsed = Std.parseInt(rawID);
			return parsed == null ? -1 : parsed;
	}
}

function getGhostTrailSettings(id:Int):Dynamic {
	if (ghostTrailLineSettings.exists(id))
		return ghostTrailLineSettings.get(id);

	return {
		enabled: ghostTrailAllEnabled,
		interval: ghostTrailAllInterval,
		alpha: ghostTrailAllAlpha,
		duration: ghostTrailAllDuration
	};
}

function spawnGhostTrailForAllLines() {
	if (strumLines == null || strumLines.members == null)
		return;

	for (id in 0...strumLines.members.length)
		spawnGhostTrailForLine(id);
}

function spawnGhostTrailForLine(id:Int) {
	if (strumLines == null || strumLines.members == null || id < 0 || id >= strumLines.members.length)
		return;

	var line = strumLines.members[id];
	if (line == null || line.characters == null)
		return;
	var settings = getGhostTrailSettings(id);
	var ghostAlpha:Float = settings == null ? 0.35 : settings.alpha;
	var durationSteps:Float = settings == null ? 8 : settings.duration;
	var durationSeconds = Math.max(Conductor.stepCrochet * 0.001 * durationSteps, 0.05);

	for (char in line.characters) {
		if (char == null || !char.visible || char.animation == null || char.animation.curAnim == null)
			continue;

		// Snapshot the exact current pose through the shared ghost pool. This
		// variant has no EchoEffect shader and does not offset the copy.
		scripts.call("onGhostTrailSnapshot", [char, ghostAlpha, durationSeconds]);
	}
}

function update(elapsed:Float) {
	if (strumLines == null || strumLines.members == null)
		return;

	for (id in 0...strumLines.members.length) {
		var settings = getGhostTrailSettings(id);
		if (settings == null || settings.enabled != true) {
			ghostTrailLineTimers.set(id, 0);
			continue;
		}

		var intervalSeconds = Math.max(
			Conductor.stepCrochet * 0.001 * settings.interval,
			1 / 120
		);
		var timer:Float = ghostTrailLineTimers.exists(id) ? ghostTrailLineTimers.get(id) : 0;
		timer += elapsed;

		// Limit catch-up spawns after a lag spike so the pool is not flooded.
		var spawns = 0;
		while (timer >= intervalSeconds && spawns < 4) {
			timer -= intervalSeconds;
			spawnGhostTrailForLine(id);
			spawns++;
		}
		if (spawns >= 4 && timer >= intervalSeconds)
			timer = 0;

		ghostTrailLineTimers.set(id, timer);
	}
}

function destroy() {
	ghostTrailLineSettings.clear();
	ghostTrailLineTimers.clear();
}
