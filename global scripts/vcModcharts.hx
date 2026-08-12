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
var iTimeShaders:Array<Dynamic> = [];
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

function rebuildITimeShaderCache() {
	iTimeShaders = [];
	for (item in modchartItems) {
		if (item == null || item.property != "iTime" || item.object == null) continue;
		// Normally there is one iTime item per shader. Avoid duplicate uniform
		// writes as well if an item script happens to expose it more than once.
		if (iTimeShaders.indexOf(item.object) < 0) iTimeShaders.push(item.object);
	}
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
var modchartXMLPathCache:String = null;
var modchartXMLTextCache:String = null;

inline function isNewModchartText(text:String):Bool {
	if (text == null) return false;

	// Only inspect the beginning and the root tag. Modern charts use the same
	// unobtrusive root-attribute style as options such as stageHueCamHUD.
	var prefix = text.length > 512 ? text.substr(0, 512) : text;
	var rootStart = prefix.indexOf("<Modchart");
	if (rootStart < 0) return false;
	var rootEnd = prefix.indexOf(">", rootStart);
	if (rootEnd < 0) return false;

	var rootTag = prefix.substr(rootStart, rootEnd - rootStart + 1);
	return rootTag.indexOf('format="2"') >= 0 || rootTag.indexOf("format='2'") >= 0;
}

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

function getModchartXMLText():String {
	var xmlPath = getModchartXMLPath();
	if (xmlPath == null) return null;
	if (modchartXMLTextCache != null && modchartXMLPathCache == xmlPath)
		return modchartXMLTextCache;

	modchartXMLPathCache = xmlPath;
	modchartXMLTextCache = Assets.getText(xmlPath);
	return modchartXMLTextCache;
}

function getModchartXML():Xml {
	var text = getModchartXMLText();
	if (text == null) return null;
	return Xml.parse(text).firstElement();
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
	var text = getModchartXMLText();
	return text != null && !isNewModchartText(text);
}

function destroy() {
	modchartXMLPathCache = null;
	modchartXMLTextCache = null;
	for (shader in iTimeShaders) shader = null;
	iTimeShaders.splice(0, iTimeShaders.length);
	if (activeLegacyModchart) return;

	for (e in modchartItems) e = null;
	modchartItems.splice(0, modchartItems.length);
	for (e in events) e = null;
	events.splice(0, events.length);
	for (e in originalEvents) e = null;
	originalEvents.splice(0, originalEvents.length);
	nextEventIndex = 0;
}

function applyTypedModchartItemValue(item:Dynamic, value:Float) {
    if (item == null || item.object == null || item.property == null) return;
    var uniformName = Reflect.hasField(item, "uniformName") && item.uniformName != null ? item.uniformName : item.property;
    var uniformType = Reflect.hasField(item, "uniformType") && item.uniformType != null ? Std.string(item.uniformType).toLowerCase() : "float";
    var componentIndex = Reflect.hasField(item, "componentIndex") && item.componentIndex != null ? Std.int(item.componentIndex) : -1;
    var objectData = Reflect.hasField(item.object, "data") ? Reflect.field(item.object, "data") : null;
    var parameter = objectData == null ? null : Reflect.field(objectData, uniformName);

    try {
        if (componentIndex >= 0) {
            if (parameter != null && parameter.value != null && parameter.value.length > componentIndex) {
                parameter.value[componentIndex] = value;
            } else {
                var count = uniformType == "vec2" ? 2 : (uniformType == "vec4" ? 4 : 3);
                var values = [];
                for (i in 0...count) values.push(i == componentIndex ? value : 0.0);
                item.object.hset(uniformName, values);
            }
            return;
        }

        var typedValue:Dynamic = switch(uniformType) {
            case "bool": value >= 0.5;
            case "int": Std.int(Math.round(value));
            default: value;
        };
        if (parameter != null && parameter.value != null && parameter.value.length > 0)
            parameter.value[0] = typedValue;
        else
            item.object.hset(uniformName, typedValue);
    } catch(e:Dynamic) {
        try {
            Reflect.setProperty(item.object, uniformName, value);
        } catch(e2:Dynamic) {}
    }
}

function applyItemDefault(item:Dynamic) {
    applyTypedModchartItemValue(item, item.value);
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
	// Cache this once after every timeline item has been created. The frame loop
	// can then touch only actual iTime shaders, like the legacy loader does.
	rebuildITimeShaderCache();

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
		var legacyLoader = importScript("data/scripts/loaders/vcLegacyModcharts.hx");
		if (legacyLoader != null)
			legacyLoader.set("modchartXMLText", modchartXMLTextCache);
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

	var shaderTime = Conductor.songPosition * 0.001;
	for (shader in iTimeShaders)
		shader.hset("iTime", shaderTime);
}
