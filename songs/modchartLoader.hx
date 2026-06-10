//
import haxe.io.Path;
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
var didInitialTimelineSync:Bool = false;
var lastModchartSongPosition:Float = Math.NEGATIVE_INFINITY;
var seekThresholdMs:Float = 250;

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

function destroy() {
	for (e in modchartItems) e = null;
	modchartItems.splice(0, modchartItems.length);
	for (e in events) e = null;
	events.splice(0, events.length);
	for (e in originalEvents) e = null;
	originalEvents.splice(0, originalEvents.length);
}

function cloneEvent(e:Dynamic):Dynamic {
	return Reflect.copy(e);
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

function loadEvents() {

	eventScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartEvents/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			eventScripts.set(file, importScript("data/scripts/modchartEvents/" + file + ".hx"));
			eventTypes.push(file);
			eventUpdateFuncs.push(eventScripts.get(file).get("updateEventGame"));
		}
	}

	itemScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartTimelineItems/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			itemScripts.set(file, importScript("data/scripts/modchartTimelineItems/" + file + ".hx"));
			itemTypes.push(file);
		}
	}

	var xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart.xml");
	if (Assets.exists(Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml"))) {
		xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml");
	}
	if (!Assets.exists(xmlPath)) return;

	var xml = Xml.parse(Assets.getText(xmlPath)).firstElement();
	if (isLegacyModchartXML(xml)) {
		trace("modchartLoader: skipping legacy modchart xml");
		return;
	}

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

	originalEvents = [];
	for (e in events) originalEvents.push(cloneEvent(e));
}

function syncModchartToStep(step:Float, skipImpulses:Bool = true) {
	for (item in modchartItems)
		applyItemDefault(item);

	events = [];
	for (sourceEvent in originalEvents) {
		var e = cloneEvent(sourceEvent);
		if (step >= e.step) {
			if (skipImpulses && isImpulseEvent(e)) continue;
			var done = eventUpdateFuncs[e.type](step, e);
			if (!done) events.push(e);
		} else {
			events.push(e);
		}
	}
}

function forceModchartSeekSync(step:Float = -1) {
	syncModchartToStep(step < 0 ? curStepFloat : step, true);
	didInitialTimelineSync = true;
	lastModchartSongPosition = Conductor.songPosition;
}

function consumeDueEvents(currentStep:Float) {
	var i = 0;
	while (i < events.length) {
		var e = events[i];
		if (currentStep < e.step) break;

		if (eventUpdateFuncs[e.type](currentStep, e)) {
			events.splice(i, 1);
		} else {
			i++;
		}
	}
}

function postUpdate(elapsed) {
	if (!modcharts) return;

	var expectedPosition = lastModchartSongPosition == Math.NEGATIVE_INFINITY ? Conductor.songPosition : lastModchartSongPosition + (elapsed * 1000);
	var didSeek = lastModchartSongPosition != Math.NEGATIVE_INFINITY && Math.abs(Conductor.songPosition - expectedPosition) > seekThresholdMs;

	if (!didInitialTimelineSync || didSeek) {
		syncModchartToStep(curStepFloat, didSeek || Conductor.songPosition > 100);
		didInitialTimelineSync = true;
	} else {
		consumeDueEvents(curStepFloat);
	}
	lastModchartSongPosition = Conductor.songPosition;

	/*for (data in iTimeShaderData) {
		if (data.hasSpeed) {
			data.iTime += (FlxG.elapsed * data.shader.speed);
			data.shader.iTime = data.iTime;
		} else {
			data.shader.iTime = Conductor.songPosition*0.001;
		}
	}*/
	for (item in modchartItems) {
    if (item.property == "iTime") {
        item.object.hset("iTime", Conductor.songPosition * 0.001);
    }
}
}

function create() {
	if (Reflect.field(FlxG.save.data, "voiidModcharts") == null) {
		Reflect.setField(FlxG.save.data, "voiidModcharts", true);
		FlxG.save.flush();
	}
	modcharts = Reflect.field(FlxG.save.data, "voiidModcharts") != false;

	camOther = new FlxCamera();
	camOther.bgColor = 0;
	FlxG.cameras.add(camOther, false);
}
function postCreate() {
	if (!modcharts) return;
	loadEvents();
}
