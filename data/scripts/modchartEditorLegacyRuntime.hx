//
// Legacy note modchart preview in ModchartEditor — must run in a script that
// importScript-merges modchartManager (same scope as gameplay legacy).
importScript("data/scripts/loaders/modchartManager.hx");

var editorNotePathGroup = [];
var editorNotePathsReady:Bool = false;
var editorModchartReady:Bool = false;

function setModifierValue(name:String, value:Float) {
	for (m in modifiers) {
		if (m[MOD_NAME] == name) {
			m[MOD_VALUE] = value;
			return;
		}
	}
}

function prepareLoad(clearModifiers:Bool) {
	if (clearModifiers) {
		modifiers.splice(0, modifiers.length);
		clearNotePaths();
	}
	initialized = false;
	editorModchartReady = false;
}

function createModifierFromEvent(event:Xml) {
	createModifier(
		event.get("name"),
		Std.parseFloat(event.get("value")),
		event.get("code"),
		event.exists("strumLineID") ? Std.parseInt(event.get("strumLineID")) : -1,
		event.exists("strumID") ? Std.parseInt(event.get("strumID")) : -1,
		event.exists("defaultValue") ? Std.parseFloat(event.get("defaultValue")) : 0.0,
		event.exists("autoDisable") ? event.get("autoDisable") == "true" : false
	);
}

function syncKeyCounts() {
	for (p in 0...PlayState.SONG.strumLines.length) {
		var kc:Int = 4;
		if (PlayState.SONG.strumLines[p] != null && PlayState.SONG.strumLines[p].keyCount != null)
			kc = PlayState.SONG.strumLines[p].keyCount;
		else if (strumLines[p] != null && strumLines[p].length > 0)
			kc = strumLines[p].length;
		modchartManagerKeyCount = kc;
	}
}

function clearNotePaths() {
	for (p in editorNotePathGroup) {
		if (p == null) continue;
		for (lane in p) {
			if (lane == null) continue;
			for (lineSpr in lane) {
				if (lineSpr != null && lineSpr.exists)
					lineSpr.destroy();
			}
		}
	}
	editorNotePathGroup = [];
	editorNotePathsReady = false;
}

function createNotePaths() {
	if (!initialized) return;
	if (editorNotePathsReady) return;

	clearNotePaths();

	var speed:Float = PlayState.SONG.scrollSpeed == null ? 1 : PlayState.SONG.scrollSpeed;
	var segments:Int = Math.ceil((3500 / speed) / (Conductor.stepCrochet > 0 ? Conductor.stepCrochet : 125));

	for (p in 0...strumLines.length) {
		editorNotePathGroup.push([]);
		if (strumLines[p] == null) continue;

		for (i => strum in strumLines[p]) {
			editorNotePathGroup[p].push([]);
			if (strum == null) continue;

			var curTime:Float = 0;
			for (l in 0...segments) {
				var lineSpr = new FlxSprite(
					strum.x + 50,
					56 + strum.y + (curTime * 0.45 * speed)
				);
				lineSpr.makeGraphic(1, 1, 0xFFFFFFFF);
				lineSpr.setGraphicSize(10, Math.ceil(Conductor.stepCrochet * 0.45 * speed));
				lineSpr.updateHitbox();
				lineSpr.cameras = [camHUD];
				lineSpr.scrollFactor.set();
				lineSpr.forceIsOnScreen = true;

				if (!stagePreviewMode)
					insert(0, lineSpr);

				editorNotePathGroup[p][i].push(lineSpr);
				curTime += Conductor.stepCrochet;
			}
		}
	}

	editorNotePathsReady = true;
}

function updateNotePaths() {
	if (!initialized || !editorNotePathsReady) return;

	var speed:Float = PlayState.SONG.scrollSpeed == null ? 1 : PlayState.SONG.scrollSpeed;

	for (p in 0...strumLines.length) {
		if (strumLines[p] == null || editorNotePathGroup[p] == null) continue;

		for (i => strum in strumLines[p]) {
			if (strum == null || editorNotePathGroup[p][i] == null) continue;

			var curTime:Float = 0;
			for (lineSpr in editorNotePathGroup[p][i]) {
				if (lineSpr == null || !lineSpr.exists) continue;

				if (!isPerspectiveShader(lineSpr.shader))
					lineSpr.shader = getPerspectiveShader(p, i);
				if (lineSpr.shader == null) continue;

				lineSpr.shader.viewMatrix = viewMatrix;
				lineSpr.shader.perspectiveMatrix = perspectiveMatrix;
				lineSpr.shader.songPosition = Conductor.songPosition;
				lineSpr.shader.curBeat = Conductor.curBeatFloat;
				lineSpr.shader.downscroll = downscroll;
				lineSpr.shader.isSustainNote = true;

				if (lineSpr.frame != null)
					lineSpr.shader.frameUV = [lineSpr.frame.uv.x, lineSpr.frame.uv.y, lineSpr.frame.uv.width, lineSpr.frame.uv.height];

				var point = FlxPoint.weak();
				lineSpr.getScreenPosition(point, camHUD);
				lineSpr.shader.screenX = lineSpr.origin.x + point.x - lineSpr.offset.x;
				lineSpr.shader.screenY = lineSpr.origin.y + point.y - lineSpr.offset.y;
				point.put();

				var time:Float = -curTime;
				var nextTime:Float = -(curTime + Conductor.stepCrochet);
				lineSpr.shader.strumID = i;
				lineSpr.shader.strumLineID = p;
				if (downscroll)
					lineSpr.shader.data.noteCurPos.value = [nextTime, nextTime, time, time];
				else
					lineSpr.shader.data.noteCurPos.value = [time, time, nextTime, nextTime];

				lineSpr.shader.scrollSpeed = speed;
				applyModifierValuesToShader(lineSpr.shader, p, i);

				curTime += Conductor.stepCrochet;
			}
		}
	}
}

function initEditor() {
	if (editorModchartReady) return;
	syncKeyCounts();
	initModchart();
	createNotePaths();
	editorModchartReady = true;
}

// modchartManager.postUpdate is a CE lifecycle hook — not callable by name from here.

function editorPostUpdate(elapsed:Float) {
	if (!editorModchartReady)
		initEditor();
	else if (!editorNotePathsReady)
		createNotePaths();

	updateNotePaths();
}
