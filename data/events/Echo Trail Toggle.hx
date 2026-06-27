import StringTools;

var echoAllStrumLines:Bool = false;
var echoStrumLines:Map<Int, Bool> = [];

function onEvent(event) {
	if (event == null || event.event == null || event.event.name != "Echo Trail Toggle")
		return;

	var enabled:Bool = event.event.params[0];
	var target:String = event.event.params.length > 1 && event.event.params[1] != null
		? Std.string(event.event.params[1]).toLowerCase()
		: "all";

	setEchoTarget(target, enabled);
}

function setEchoTarget(target:String, enabled:Bool) {
	if (target == "all") {
		echoAllStrumLines = enabled;
		echoStrumLines = [];
		return;
	}

	var id = getTargetStrumLineID(target);
	if (id < 0)
		return;

	echoStrumLines.set(id, enabled);
}

function getTargetStrumLineID(target:String):Int {
	switch (target) {
		case "opponent" | "opponent1" | "dad" | "strumline0" | "0":
			return 0;
		case "player" | "boyfriend" | "bf" | "strumline1" | "1":
			return 1;
		default:
			var rawID = StringTools.startsWith(target, "strumline")
				? target.substr("strumline".length)
				: target;
			var parsed = Std.parseInt(rawID);
			return parsed == null ? -1 : parsed;
	}
}

function isEchoEnabledForLine(id:Int):Bool {
	return echoStrumLines.exists(id) ? echoStrumLines.get(id) : echoAllStrumLines;
}

function isActuallySinging(char:Character):Bool {
	return char != null
		&& char.visible
		&& char.animation != null
		&& char.animation.curAnim != null
		&& char.animation.curAnim.name.indexOf("sing") != -1
		&& !char.animation.curAnim.finished;
}

function onNoteHit(event) {
	if (event == null || event.note == null || event.note.strumLine == null)
		return;
	if (!isEchoEnabledForLine(event.note.strumLine.ID))
		return;
	if (event.note.strumLine.characters == null)
		return;

	for (char in event.note.strumLine.characters)
		if (isActuallySinging(char))
			scripts.call("onDoubleNoteGhostEchoTrail", [char]);
}
