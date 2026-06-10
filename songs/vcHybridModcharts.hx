//
import haxe.io.Path;
import Xml;

public var modcharts = Reflect.field(FlxG.save.data, "voiidModcharts") != false;
public var opponentPlay = PlayState.opponentMode;

var legacyLoaded:Bool = false;

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
	var xmlPath = getModchartXMLPath();
	if (xmlPath == null) return false;

	var xml = Xml.parse(Assets.getText(xmlPath)).firstElement();
	return isLegacyModchartXML(xml);
}

function loadActiveLoader() {
	if (!modcharts) return;

	var xmlPath = getModchartXMLPath();
	var legacy = useLegacyLoader();
	trace("vcHybridModcharts: xml=" + xmlPath + " legacy=" + legacy);

	if (legacy) {
		legacyLoaded = true;
		importScript("data/scripts/loaders/vcLegacyModcharts.hx");
		trace("vcHybridModcharts: using legacy old reader");
	} else {
		trace("vcHybridModcharts: using new reader");
	}
}

function create() {
	ensureModchartOption();
	loadActiveLoader();
}
