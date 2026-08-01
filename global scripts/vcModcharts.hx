//
import haxe.io.Path;
import haxe.Timer;
import Xml;

public var modcharts = Reflect.field(FlxG.save.data, "voiidModcharts") != false;
public var opponentPlay = PlayState.opponentMode;
public var camOther:FlxCamera;

public var eventScripts = ["" => null];
public var eventTypes = [];
public var itemScripts = ["" => null];
public var itemTypes = [];

var eventUpdateFuncs = [];

public var modchartItems = [];
public function createModchartItem(n, p, t, v, o) {
	var item = {
		name: n,
		property: p,
		type: t,
		value: v,
		object: o
	};
	modchartItems.push(item);
	return item;
}

var events:Array<Dynamic> = [];
var originalEvents:Array<Dynamic> = [];
var nextEventIndex:Int = 0;
var didInitialTimelineSync:Bool = false;
var lastModchartSongPosition:Float = Math.NEGATIVE_INFINITY;
var rewindThresholdMs:Float = 250;
var modchartFullSyncCount:Int = 0;
var lastModchartFullSyncMs:Float = 0;
var activeLegacyModchart:Bool = false;

function ensureModchartOption() {
	if (Reflect.field(FlxG.save.data, "voiidModcharts") == null) {
		Reflect.setField(FlxG.save.data, "voiidModcharts", true);
		FlxG.save.flush();
	}
	modcharts = Reflect.field(FlxG.save.data, "voiidModcharts") != false;
}

function getModchartXMLPath():String {
	var base = "songs/" + PlayState.SONG.meta.name + "/";
	var diffPath = Paths.getPath(base + "modchart-" + PlayState.difficulty + ".xml");
	if (Assets.exists(diffPath)) return diffPath;

	var normalPath = Paths.getPath(base + "modchart.xml");
	if (Assets.exists(normalPath)) return normalPath;

	var extensionlessPath = Paths.getPath(base + "modchart");
	if (Assets.exists(extensionlessPath)) return extensionlessPath;

	return null;
}

function getModchartXML():Xml {
	var xmlPath = getModchartXMLPath();
	if (xmlPath == null) return null;
	return Xml.parse(Assets.getText(xmlPath)).firstElement();
}

function isLegacyModchartXML(xml:Xml):Bool {
	if (xml == null) return false;
	if (xml.get("noteModchart") == "true") return true;
	if (xml.elementsNamed("Shader").hasNext()) return false;
	if (xml.elementsNamed("Modifier").hasNext()) return false;
	if (xml.elementsNamed("FunkinModifier").hasNext()) return false;

	for (list in xml.elementsNamed("Init")) {
		if (list.elementsNamed("Shader").hasNext()) return false;
		if (list.elementsNamed("Modifier").hasNext()) return false;
		if (list.elementsNamed("FunkinModifier").hasNext()) return false;

		for (event in list.elementsNamed("Event")) {
			switch(event.get("type")) {
				case "initShader" | "setCameraShader" | "setShaderProperty" | "initModifier":
					return true;
			}
		}
	}

	for (list in xml.elementsNamed("Events")) {
		for (event in list.elementsNamed("Event")) {
			switch(event.get("type")) {
				case "setModifierValue":
					return true;
			}
		}
	}

	return false;
}

function useLegacyLoader():Bool {
	return isLegacyModchartXML(getModchartXML());
}

function destroy() {
	if (activeLegacyModchart) return;

	for (e in modchartItems) e = null;
	modchartItems.splice(0, modchartItems.length);
	for (e in events) e = null;
	events.splice(0, events.length);
	for (e in originalEvents) e = null;
	originalEvents.splice(0, originalEvents.length);
	nextEventIndex = 0;
}

function applyItemDefault(item:Dynamic) {
	if (item == null || item.object == null || item.property == null) return;
	try {
		item.object.hset(item.property, item.value);
	} catch(e:Dynamic) {
		try {
			Reflect.setProperty(item.object, item.property, item.value);
		} catch(e2:Dynamic) {}
	}
}

function isImpulseEvent(e:Dynamic):Bool {
	var typeName = eventTypes[e.type];
	return typeName == "addCameraZoom" || typeName == "addHUDZoom";
}

function loadNewModchart() {
	eventScripts.clear();
	eventTypes = [];
	eventUpdateFuncs = [];
	for (path in Paths.getFolderContent('data/scripts/modchartEvents/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			eventScripts.set(file, importScript("data/scripts/modchartEvents/" + file + ".hx"));
			eventTypes.push(file);
			eventUpdateFuncs.push(eventScripts.get(file).get("updateEventGame"));
		}
	}

	itemScripts.clear();
	itemTypes = [];
	for (path in Paths.getFolderContent('data/scripts/modchartTimelineItems/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			itemScripts.set(file, importScript("data/scripts/modchartTimelineItems/" + file + ".hx"));
			itemTypes.push(file);
		}
	}

	var xml = getModchartXML();
	if (xml == null) return;

	for (name => script in itemScripts) {
		script.call("setupDefaultsGame", []);
	}

	for (list in xml.elementsNamed("Init")) {
		for (name => script in itemScripts) {
			script.call("setupItemsFromXMLGame", [list]);
		}
	}
	
	for (list in xml.elementsNamed("Events")) {
		for (event in list.elementsNamed("Event")) {
			var eventType = event.get("type");
			if (eventScripts.exists(eventType)) {
				var n = eventScripts.get(eventType).call("getItemNameFromXML", [event]);
				for (i => item in modchartItems) {
					if (item.name == n) {
						var e = eventScripts.get(eventType).call("createEventGame", [eventTypes.indexOf(eventType), event, i]);
						events.push(e);
						break;
					}
				}
			}
		}
	}
	for (name => script in itemScripts) {
		script.call("postXMLLoadGame", [xml]);
	}

	events.sort(function(a, b) {
		if(a.step < b.step) return -1;
		else if(a.step > b.step) return 1;
		else return 0;
	});

	// The timeline remains immutable; `events` contains active tweens only.
	// This avoids cloning the complete XML and shifting thousands of entries
	// with splice() as a song advances.
	originalEvents = events;
	events = [];
	nextEventIndex = 0;
}

function syncModchartToStep(step:Float, skipImpulses:Bool = true) {
	if (activeLegacyModchart) return;

	for (item in modchartItems)
		applyItemDefault(item);

	events = [];
	nextEventIndex = 0;
	while (nextEventIndex < originalEvents.length) {
		var e = originalEvents[nextEventIndex];
		if (step < e.step) break;

		if (!(skipImpulses && isImpulseEvent(e))) {
			var done = eventUpdateFuncs[e.type](step, e);
			if (!done) events.push(e);
		}
		nextEventIndex++;
	}
}

function forceModchartSeekSync(step:Float = -1) {
	if (activeLegacyModchart) return;

	syncModchartToStep(step < 0 ? curStepFloat : step, true);
	didInitialTimelineSync = true;
	lastModchartSongPosition = Conductor.songPosition;
}

function consumeDueEvents(currentStep:Float) {
	var i = 0;
	while (i < events.length) {
		var e = events[i];
		if (eventUpdateFuncs[e.type](currentStep, e)) {
			events.splice(i, 1);
		} else {
			i++;
		}
	}

	while (nextEventIndex < originalEvents.length) {
		var e = originalEvents[nextEventIndex];
		if (currentStep < e.step) break;

		if (!eventUpdateFuncs[e.type](currentStep, e))
			events.push(e);
		nextEventIndex++;
	}
}

function ensureOtherCamera() {
	if (camOther != null) return;

	camOther = new FlxCamera();
	camOther.bgColor = 0;
	FlxG.cameras.add(camOther, false);
}

function create() {
	ensureModchartOption();
	// camOther is also used by non-modchart systems such as Skip, lyrics and
	// mechanic overlays. It must exist even when XML modcharts are disabled.
	if (!modcharts) {
		ensureOtherCamera();
		return;
	}

	activeLegacyModchart = useLegacyLoader();
	if (activeLegacyModchart) {
		importScript("data/scripts/loaders/vcLegacyModcharts.hx");
		return;
	}

	ensureOtherCamera();
}

function postCreate() {
	if (!modcharts || activeLegacyModchart) return;
	loadNewModchart();
}

function postUpdate(elapsed) {
	if (!modcharts || activeLegacyModchart) return;

	// Let normal forward audio corrections advance through the event cursor.
	// Rebuilding every prior event after a >250 ms forward correction produces a
	// large one-frame spike. Intentional forward skips synchronize explicitly.
	var rewindAmountMs = lastModchartSongPosition == Math.NEGATIVE_INFINITY ? 0 : lastModchartSongPosition - Conductor.songPosition;
	var didRewind = rewindAmountMs > rewindThresholdMs;

	if (!didInitialTimelineSync || didRewind) {
		var syncStart = Timer.stamp();
		syncModchartToStep(curStepFloat, didRewind || Conductor.songPosition > 100);
		lastModchartFullSyncMs = (Timer.stamp() - syncStart) * 1000;
		modchartFullSyncCount++;
		if (didRewind || lastModchartFullSyncMs >= 4) {
			trace('[Voiid modchart] full sync #' + modchartFullSyncCount + ' at step ' + curStepFloat + ': ' + lastModchartFullSyncMs + ' ms (rewind ' + rewindAmountMs + ' ms)');
		}
		didInitialTimelineSync = true;
	} else {
		consumeDueEvents(curStepFloat);
	}
	lastModchartSongPosition = Conductor.songPosition;

	for (item in modchartItems) {
		if (item.property == "iTime") {
			item.object.hset("iTime", Conductor.songPosition * 0.001);
		}
	}
}
