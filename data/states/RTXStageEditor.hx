import funkin.editors.EditorTreeMenu;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UISliceSprite;
import funkin.editors.ui.UISlider;
import funkin.editors.ui.UIText;
import funkin.game.Character;
import funkin.game.Stage;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import haxe.Json;
import haxe.io.Path;
import openfl.utils.Assets;
import Xml;

var stageName:String = "stage";
var stage:Stage;
var previewCam:FlxCamera;
var uiCam:FlxCamera;
var selectedSlot:String = "dad";
var selectedChar:String = "dad";
var charPreview:Character;
var stageRoot:Xml;
var rtxRoot:Dynamic;
var rtxData:Dynamic;
var charNodes:Array<Dynamic> = [];
var rtxInputs:Array<Dynamic> = [];
var rtxPanelItems:Array<Dynamic> = [];
var rtxSwatches:Array<Dynamic> = [];
var title:UIText;
var status:UIText;
var slotDropdown:UIDropDown;
var charDropdown:UIDropDown;
var leftPanelItems:Array<Dynamic> = [];
var leftPanelHidden:Bool = false;
var leftPanelToggle:UIButton;
var charOffsetX:Float = 0;
var charOffsetY:Float = 0;
var charDragging:Bool = false;
var charDragOffsetX:Float = 0;
var charDragOffsetY:Float = 0;
var cameraDragging:Bool = false;
var cameraPanLastMouse:FlxPoint = null;
var previewShader:Dynamic = null;

function create() {
	if (Reflect.hasField(FlxG.save.data, "rtxStageEditorStage"))
		stageName = Reflect.field(FlxG.save.data, "rtxStageEditorStage");

	FlxG.mouse.visible = true;

	previewCam = new FlxCamera();
	previewCam.bgColor = 0xFF111111;
	FlxG.cameras.add(previewCam, true);
	FlxG.camera = previewCam;

	uiCam = new FlxCamera();
	uiCam.bgColor = 0;
	FlxG.cameras.add(uiCam, false);

	loadStageXML();
	loadRTXJson();
	buildPreview();
	buildUI();
	loadCharacter(getCharacterList()[0]);
	selectSlot("dad");
}

function loadStageXML() {
	var path = Paths.xml("stages/" + stageName);
	if (Assets.exists(path))
		stageRoot = Xml.parse(Assets.getText(path)).firstElement();
	else
		stageRoot = Xml.createElement("stage");

	charNodes = [];
	for (node in stageRoot.elements()) {
		var nodeName = xmlGet(node, "name");
		var key = nodeNameToSlot(node.nodeName, nodeName);
		if (key != null && findNode(charNodes, key) == null)
			charNodes.push({name: key, node: node});
	}
}

function loadRTXJson() {
	rtxRoot = {};
	rtxData = {};

	var path = getRTXAssetPath();
	if (Assets.exists(path)) {
		var text = Assets.getText(path);
		if (text != null && text.length > 0 && StringTools.fastCodeAt(text, 0) == 65279)
			text = text.substr(1);
		try {
			rtxRoot = Json.parse(text);
			var loaded = Reflect.field(rtxRoot, "rtxData");
			if (loaded != null)
				rtxData = loaded;
		} catch(e:Dynamic) {
			rtxRoot = {};
			rtxData = {};
		}
	}

	ensureRTXDefaults();
	Reflect.setField(rtxRoot, "rtxData", rtxData);
}

function ensureRTXDefaults() {
	setRTXDefault("overlay", "0x000000");
	setRTXDefault("overlayAlpha", 0);
	setRTXDefault("satin", "0xFFFFFF");
	setRTXDefault("satinAlpha", 0);
	setRTXDefault("inner", "0x000000");
	setRTXDefault("innerAlpha", 0);
	setRTXDefault("innerDistance", 10);
	setRTXDefault("innerAngle", 270);
	setRTXDefault("lightX", 0);
	setRTXDefault("lightY", 0);
	setRTXDefault("pointLight", false);
	setRTXDefault("layernumbers", 5);
	setRTXDefault("layerseparation", 1);
}

function setRTXDefault(field:String, value:Dynamic) {
	if (Reflect.field(rtxData, field) == null)
		Reflect.setField(rtxData, field, value);
}

function buildPreview() {
	stage = new Stage(stageName, FlxG.state);
	for (spr in stage.stageSprites)
		spr.cameras = [previewCam];
	for (pos in stage.characterPoses)
		pos.cameras = [previewCam];
}

function buildUI() {
	var panel = new UISliceSprite(0, 0, 330, FlxG.height, "editors/ui/inputbox");
	panel.cameras = [uiCam];
	panel.scrollFactor.set();
	add(panel);
	leftPanelItems.push(panel);

	title = new UIText(12, 10, 310, "RTX Stage Editor: " + stageName, 18);
	title.cameras = [uiCam];
	title.scrollFactor.set();
	add(title);
	leftPanelItems.push(title);

	addLabel("Slot", 18, 54);
	slotDropdown = new UIDropDown(18, 74, 290, 32, ["dad", "boyfriend", "girlfriend"], 0);
	slotDropdown.onChange = function(i) selectSlot(slotDropdown.options[i]);
	addLeftUI(slotDropdown);

	addLabel("Character", 18, 112);
	charDropdown = new UIDropDown(18, 132, 290, 32, getCharacterList(), 0);
	charDropdown.onChange = function(i) loadCharacter(charDropdown.options[i]);
	addLeftUI(charDropdown);

	var saveButton = new UIButton(18, 190, "Save JSON", saveRTXJson, 140, 32);
	addLeftUI(saveButton);

	var backButton = new UIButton(170, 190, "Back", function() {
		var state = new EditorTreeMenu();
		state.scriptName = "RTXStageEditorSelection";
		FlxG.switchState(state);
	}, 140, 32);
	addLeftUI(backButton);

	status = new UIText(18, FlxG.height - 70, 300, "Left drag moves preview char. Right drag pans camera. Wheel zooms.", 13);
	status.cameras = [uiCam];
	status.scrollFactor.set();
	add(status);
	leftPanelItems.push(status);

	leftPanelToggle = new UIButton(6, 6, "<", toggleLeftPanel, 28, 24);
	addUI(leftPanelToggle);

	buildRTXPanel();
}

function buildRTXPanel() {
	var panel = new UISliceSprite(330, 0, 650, 430, "editors/ui/inputbox");
	addRTXUI(panel);

	var header = new UIText(344, 10, 360, "RTX Debug: " + stageName, 18);
	addRTXUI(header);

	addLeatherColorColumn("Overlay", "overlay", "overlayAlpha", 344, 58);
	addLeatherColorColumn("Satin", "satin", "satinAlpha", 552, 58);
	addLeatherColorColumn("Inner", "inner", "innerAlpha", 760, 58);

	addRTXSlider("Angle", "innerAngle", 364, 322, 244, 0, 360);
	addRTXSlider("Distance", "innerDistance", 364, 366, 244, 0, 120);
	addRTXSlider("Light X", "lightX", 632, 322, 244, -3000, 3000);
	addRTXSlider("Light Y", "lightY", 632, 366, 244, -3000, 3000);
	addRTXSlider("Layers", "layernumbers", 364, 408, 244, 0, 100);
	addRTXSlider("Separation", "layerseparation", 632, 408, 244, 0, 100);

	var pointButton:UIButton = null;
	pointButton = new UIButton(800, 12, "Point Light: " + (getRTXBool("pointLight", false) ? "ON" : "OFF"), function() {
		var next = !getRTXBool("pointLight", false);
		Reflect.setField(rtxData, "pointLight", next);
		if (pointButton != null)
			pointButton.field.text = "Point Light: " + (next ? "ON" : "OFF");
		applyRTXPreview();
	}, 166, 28);
	addRTXUI(pointButton);

	refreshRTXSwatches();
}

function addLeatherColorColumn(label:String, colorField:String, alphaField:String, x:Float, y:Float) {
	var title = new UIText(x, y - 24, 166, label, 14);
	addRTXUI(title);
	addColorChannelSlider("R", colorField, 0, x, y);
	addColorChannelSlider("G", colorField, 1, x, y + 40);
	addColorChannelSlider("B", colorField, 2, x, y + 80);
	addRTXSlider("A", alphaField, x, y + 120, 166, 0, 1);

	var swatch = new FlxSprite(x + 20, y + 166);
	swatch.makeGraphic(128, 48, 0xFFFFFFFF);
	addRTXUI(swatch);
	var text = new UIText(x + 20, y + 218, 172, "", 13);
	addRTXUI(text);
	rtxSwatches.push({field: colorField, alpha: alphaField, spr: swatch, text: text});
}

function addColorChannelSlider(label:String, colorField:String, channel:Int, x:Float, y:Float) {
	var rowLabel = new UIText(x, y - 2, 20, label, 12);
	addRTXUI(rowLabel);
	var input = makeUISlider(x + 96, y, 86, getColorChannel(colorField, channel), 0, 1, function(value:Float) {
		setColorChannel(colorField, channel, value);
		applyRTXPreview();
		refreshRTXSwatches();
	});
	rtxInputs.push({field: colorField, input: input});
	addRTXUI(input);
}

function addRTXSlider(label:String, field:String, x:Float, y:Float, width:Int, min:Float, max:Float) {
	var rowLabel = new UIText(x, y - 18, width, label, 12);
	addRTXUI(rowLabel);
	var input = makeUISlider(x + 96, y, width - 96, getRTXFloat(field, 0), min, max, function(value:Float) {
		Reflect.setField(rtxData, field, value);
		applyRTXPreview();
		refreshRTXSwatches();
	});
	rtxInputs.push({field: field, input: input});
	addRTXUI(input);
}

function makeUISlider(x:Float, y:Float, width:Int, value:Float, min:Float, max:Float, onChange:Float->Void):UISlider {
	var segs = [{start: min, end: max, size: 1}];
	var slider = new UISlider(x, y, width, value, segs, false);
	slider.startText.text = "";
	slider.endText.text = "";
	slider.valueStepper.visible = true;
	slider.valueStepper.active = true;
	slider.valueStepper.value = value;
	slider.value = value;
	slider.onChange = onChange;
	return slider;
}

function addRTXLabel(text:String, x:Float, y:Float) {
	var label = new UIText(x, y, 88, text, 12);
	label.cameras = [uiCam];
	label.scrollFactor.set();
	add(label);
	rtxPanelItems.push({spr: label, x: label.x});
}

function addRTXUI(spr) {
	addUI(spr);
	rtxPanelItems.push({spr: spr, x: spr.x});
}

function setRTXPanelOffset(offset:Float) {
	for (entry in rtxPanelItems) {
		if (entry == null || entry.spr == null) continue;
		try {
			entry.spr.x = entry.x + offset;
		} catch(e:Dynamic) {}
	}
}

function addLabel(text:String, x:Float, y:Float) {
	var label = new UIText(x, y, 140, text, 13);
	label.cameras = [uiCam];
	label.scrollFactor.set();
	add(label);
	if (x < 330)
		leftPanelItems.push(label);
}

function addUI(spr) {
	spr.cameras = [uiCam];
	spr.scrollFactor.set();
	add(spr);
}

function addLeftUI(spr) {
	addUI(spr);
	leftPanelItems.push(spr);
}

function toggleLeftPanel() {
	leftPanelHidden = !leftPanelHidden;
	for (spr in leftPanelItems) {
		if (spr == leftPanelToggle) continue;
		spr.visible = !leftPanelHidden;
		spr.active = !leftPanelHidden;
	}
	leftPanelToggle.field.text = leftPanelHidden ? ">" : "<";
	leftPanelToggle.x = leftPanelHidden ? 656 : 6;
	leftPanelToggle.y = 6;
	setRTXPanelOffset(leftPanelHidden ? -330 : 0);
}

function selectSlot(slot:String) {
	selectedSlot = slot;
	charOffsetX = 0;
	charOffsetY = 0;
	refreshCharacterPlacement();
}

function loadCharacter(charName:String) {
	if (charName == null || charName == "")
		return;
	selectedChar = charName;
	if (charPreview != null)
		remove(charPreview);

	charOffsetX = 0;
	charOffsetY = 0;
	charPreview = new Character(0, 0, selectedChar, selectedSlot == "boyfriend", true, true);
	charPreview.debugMode = true;
	charPreview.cameras = [previewCam];
	add(charPreview);
	previewShader = null;
	refreshCharacterPlacement();
}

function refreshCharacterPlacement() {
	if (charPreview == null)
		return;
	charPreview.visible = true;
	var node = getSlotNode(selectedSlot);
	charPreview.setPosition(readFloat(node, "x", defaultSlotX(selectedSlot)) + charOffsetX, readFloat(node, "y", defaultSlotY(selectedSlot)) + charOffsetY);
	var scrollX = readFloat(node, "scrollx", readFloat(node, "scroll", defaultSlotScroll(selectedSlot)));
	var scrollY = readFloat(node, "scrolly", readFloat(node, "scroll", defaultSlotScroll(selectedSlot)));
	charPreview.scrollFactor.set(scrollX, scrollY);
	var scale = readFloat(node, "scale", 1);
	charPreview.scale.set(scale, scale);
	charPreview.flipX = xmlGet(node, "flip") == "true" || xmlGet(node, "flipX") == "true";
	if (selectedSlot == "boyfriend")
		charPreview.flipX = !charPreview.flipX;
	charPreview.skew.x = readFloat(node, "skewx", 0);
	charPreview.skew.y = readFloat(node, "skewy", 0);
	charPreview.alpha = readFloat(node, "alpha", 1);
	applyRTXPreview();
}

function update(elapsed:Float) {
	if (FlxG.keys.justPressed.F6) {
		_view_reload_editor(null);
		return;
	}

	if (FlxG.keys.justPressed.ESCAPE) {
		var state = new EditorTreeMenu();
		state.scriptName = "RTXStageEditorSelection";
		FlxG.switchState(state);
	}

	if (FlxG.keys.justPressed.S)
		saveRTXJson();

	updatePreviewCharacterControls();
	updateCameraControls();
	applyRTXPreview();

	if (FlxG.mouse.wheel != 0 && isPreviewMouse())
		previewCam.zoom = Math.max(0.25, Math.min(3, previewCam.zoom + FlxG.mouse.wheel * 0.05));
}

function updatePreviewCharacterControls() {
	if (charPreview == null)
		return;

	var moveStep = FlxG.keys.pressed.SHIFT ? 10 : 1;
	var dx = 0;
	var dy = 0;
	if (FlxG.keys.pressed.LEFT) dx -= moveStep;
	if (FlxG.keys.pressed.RIGHT) dx += moveStep;
	if (FlxG.keys.pressed.UP) dy -= moveStep;
	if (FlxG.keys.pressed.DOWN) dy += moveStep;
	if (dx != 0 || dy != 0) {
		charOffsetX += dx;
		charOffsetY += dy;
		refreshCharacterPlacement();
	}

	if (FlxG.mouse.justPressed && isPreviewMouse()) {
		charDragging = true;
		var mouse = FlxG.mouse.getWorldPosition(previewCam);
		charDragOffsetX = mouse.x - charPreview.x;
		charDragOffsetY = mouse.y - charPreview.y;
	}
	if (FlxG.mouse.justReleased)
		charDragging = false;
	if (charDragging) {
		var node = getSlotNode(selectedSlot);
		var mouse = FlxG.mouse.getWorldPosition(previewCam);
		charOffsetX = mouse.x - charDragOffsetX - readFloat(node, "x", defaultSlotX(selectedSlot));
		charOffsetY = mouse.y - charDragOffsetY - readFloat(node, "y", defaultSlotY(selectedSlot));
		refreshCharacterPlacement();
	}
}

function updateCameraControls() {
	if (FlxG.mouse.justPressedRight && isPreviewMouse()) {
		cameraDragging = true;
		if (cameraPanLastMouse == null)
			cameraPanLastMouse = FlxPoint.get();
		var mouse = FlxG.mouse.getScreenPosition();
		cameraPanLastMouse.set(mouse.x, mouse.y);
	}

	if (!FlxG.mouse.pressedRight)
		cameraDragging = false;

	if (cameraDragging) {
		var mouse = FlxG.mouse.getScreenPosition();
		var zoom = previewCam.zoom;
		if (zoom <= 0) zoom = 0.001;
		previewCam.scroll.x -= (mouse.x - cameraPanLastMouse.x) / zoom;
		previewCam.scroll.y -= (mouse.y - cameraPanLastMouse.y) / zoom;
		cameraPanLastMouse.set(mouse.x, mouse.y);
	}
}

function isPreviewMouse():Bool {
	var mouse = FlxG.mouse.getScreenPosition();
	if (!leftPanelHidden && mouse.x < 330)
		return false;
	if (mouse.y < 430 && mouse.x < (leftPanelHidden ? 650 : 980))
		return false;
	return true;
}

function saveRTXJson() {
	Reflect.setField(rtxRoot, "rtxData", rtxData);
	var path = getRTXSavePath();
	CoolUtil.safeSaveFile(path, Json.stringify(rtxRoot, null, "    "));
	status.text = "Saved: " + path;
}

function applyRTXPreview() {
	if (charPreview == null)
		return;

	if (previewShader == null || charPreview.shader != previewShader) {
		try {
			previewShader = new CustomShader("RTXEffect");
			charPreview.shader = previewShader;
		} catch(e:Dynamic) {
			previewShader = null;
			return;
		}
	}

	setRTXUniform(previewShader, "overlayColor", colorToVec4(getRTXString("overlay", "0x000000"), getRTXFloat("overlayAlpha", 0)));
	setRTXUniform(previewShader, "satinColor", colorToVec4(getRTXString("satin", "0xFFFFFF"), getRTXFloat("satinAlpha", 0)));
	setRTXUniform(previewShader, "innerShadowColor", colorToVec4(getRTXString("inner", "0x000000"), getRTXFloat("innerAlpha", 0)));
	setRTXUniform(previewShader, "innerShadowDistance", getRTXFloat("innerDistance", 10));
	setRTXUniform(previewShader, "innerShadowAngle", getRTXAngle(charPreview));
	setRTXUniform(previewShader, "layernumbers", getRTXFloat("layernumbers", getRTXFloat("layers", 5)));
	setRTXUniform(previewShader, "layerseparation", getRTXFloat("layerseparation", getRTXFloat("separation", 1)));
	setRTXUniform(previewShader, "hue", getRTXFloat("hue", 0));
	refreshRTXSwatches();
}

function refreshRTXSwatches() {
	for (entry in rtxSwatches) {
		if (entry == null) continue;
		var rgb = parseRTXColorInt(getRTXString(entry.field, "0x000000"), [0, 0, 0]);
		var color = FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
		try {
			entry.spr.color = color;
			entry.spr.alpha = 1;
		} catch(e:Dynamic) {}
		try {
			entry.text.text = rgbToRTXColor(rgb) + " A " + Std.string(Math.round(getRTXFloat(entry.alpha, 0) * 100) / 100);
		} catch(e2:Dynamic) {}
	}
}

function setRTXUniform(shader:Dynamic, property:String, value:Dynamic) {
	if (shader == null)
		return;
	try {
		var hset = Reflect.field(shader, "hset");
		if (hset != null)
			Reflect.callMethod(shader, hset, [property, value]);
		else
			Reflect.setProperty(shader, property, value);
	} catch(e:Dynamic) {
		try {
			Reflect.setProperty(shader, property, value);
		} catch(e2:Dynamic) {}
	}
}

function getRTXAngle(sprite:Dynamic):Float {
	if (getRTXBool("pointLight", false) && sprite != null) {
		var midpoint = sprite.getGraphicMidpoint();
		var dx = getRTXFloat("lightX", 0) - midpoint.x;
		var dy = getRTXFloat("lightY", 0) - midpoint.y;
		if (sprite.flipX) dx = -dx;
		if (sprite.flipY) dy = -dy;
		return Math.atan2(dy, dx);
	}

	var radians = getRTXFloat("innerAngle", 270) * Math.PI / 180;
	if (sprite != null && sprite.flipX)
		radians = Math.atan2(Math.sin(radians), -Math.cos(radians));
	return radians;
}

function colorToVec4(value:String, alpha:Float):Array<Float> {
	var rgb = parseRTXColorFloat(value);
	return [rgb[0], rgb[1], rgb[2], alpha];
}

function parseRTXColorFloat(value:String):Array<Float> {
	var rgb = parseRTXColorInt(value, [255, 255, 255]);
	return [rgb[0] / 255, rgb[1] / 255, rgb[2] / 255];
}

function getColorChannel(field:String, channel:Int):Float {
	var fallback = field == "satin" ? [255, 255, 255] : [0, 0, 0];
	var rgb = parseRTXColorInt(getRTXString(field, rgbToRTXColor(fallback)), fallback);
	if (channel < 0 || channel >= rgb.length)
		return 0;
	return rgb[channel] / 255;
}

function setColorChannel(field:String, channel:Int, value:Float) {
	var fallback = field == "satin" ? [255, 255, 255] : [0, 0, 0];
	var rgb = parseRTXColorInt(getRTXString(field, rgbToRTXColor(fallback)), fallback);
	if (channel < 0 || channel >= rgb.length)
		return;
	rgb[channel] = Std.int(Math.max(0, Math.min(255, Math.round(value * 255))));
	Reflect.setField(rtxData, field, rgbToRTXColor(rgb));
}

function parseRTXColorInt(value:String, fallback:Array<Int>):Array<Int> {
	var raw = Std.string(value);
	raw = StringTools.replace(raw, "#", "");
	raw = StringTools.replace(raw, "0x", "");
	raw = StringTools.replace(raw, "0X", "");
	raw = StringTools.trim(raw);
	if (raw.length == 8)
		raw = raw.substr(2, 6);
	if (raw.length != 6)
		return fallback.copy();

	var r = Std.parseInt("0x" + raw.substr(0, 2));
	var g = Std.parseInt("0x" + raw.substr(2, 2));
	var b = Std.parseInt("0x" + raw.substr(4, 2));
	if (r == null || g == null || b == null)
		return fallback.copy();
	return [r, g, b];
}

function rgbToRTXColor(rgb:Array<Int>):String {
	return "0x" + StringTools.hex(rgb[0], 2) + StringTools.hex(rgb[1], 2) + StringTools.hex(rgb[2], 2);
}

function getRTXAssetPath():String {
	return Paths.file("data/stages/" + stageName + ".json");
}

function getRTXSavePath():String {
	var assetPath = getRTXAssetPath();
	var path = null;
	try {
		path = Paths.assetsTree.getSpecificPath(assetPath);
	} catch(e:Dynamic) {}
	if (path == null)
		path = Paths.getAssetsRoot() + "/data/stages/" + stageName + ".json";
	if (path.indexOf(":assets/") >= 0)
		path = Paths.getAssetsRoot() + "/data/stages/" + stageName + ".json";
	return path;
}

function _view_reload_editor(_) {
	var state = new funkin.editors.ui.UIState();
	state.scriptName = "RTXStageEditor";
	FlxG.switchState(state);
}

function getSlotNode(slot:String):Xml {
	var existing = findNode(charNodes, slot);
	if (existing != null)
		return existing;

	var nodeName = switch(slot) {
		case "boyfriend": "boyfriend";
		case "girlfriend": "girlfriend";
		default: "dad";
	}
	var node = Xml.createElement(nodeName);
	xmlSet(node, "x", Std.string(defaultSlotX(slot)));
	xmlSet(node, "y", Std.string(defaultSlotY(slot)));
	xmlSet(node, "scroll", Std.string(defaultSlotScroll(slot)));
	if (slot == "boyfriend")
		xmlSet(node, "flip", "true");
	stageRoot.addChild(node);
	charNodes.push({name: slot, node: node});
	return node;
}

function getCharacterList():Array<String> {
	var list:Array<String> = [];
	for (path in Paths.getFolderContent("data/characters/", true)) {
		if (Path.extension(path) == "xml") {
			var name = Path.withoutDirectory(Path.withoutExtension(path));
			if (!list.contains(name))
				list.push(name);
		}
	}
	list.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
	if (list.length == 0)
		list.push("bf");
	return list;
}

function nodeNameToSlot(nodeName:String, customName:String):String {
	return switch(nodeName) {
		case "boyfriend" | "bf" | "player": "boyfriend";
		case "girlfriend" | "gf": "girlfriend";
		case "dad" | "opponent": "dad";
		case "character" | "char": customName;
		default: null;
	}
}

function readFloat(node:Xml, att:String, def:Float):Float {
	var text = xmlGet(node, att);
	var v = text != null ? Std.parseFloat(text) : Math.NaN;
	return Math.isNaN(v) ? def : v;
}

function getRTXFloat(field:String, fallback:Float):Float {
	var value = Reflect.field(rtxData, field);
	if (value == null) return fallback;
	var parsed = Std.parseFloat(Std.string(value));
	return Math.isNaN(parsed) ? fallback : parsed;
}

function getRTXBool(field:String, fallback:Bool):Bool {
	var value = Reflect.field(rtxData, field);
	if (value == null) return fallback;
	return Std.string(value).toLowerCase() == "true";
}

function getRTXString(field:String, fallback:String):String {
	var value = Reflect.field(rtxData, field);
	return value == null ? fallback : Std.string(value);
}

function findNode(list:Array<Dynamic>, name:String):Xml {
	for (entry in list)
		if (entry.name == name)
			return entry.node;
	return null;
}

function xmlGet(node:Xml, att:String):String {
	if (node == null)
		return null;
	try {
		return node.get(att);
	} catch(e:Dynamic) {
		return null;
	}
}

function xmlSet(node:Xml, att:String, value:String) {
	if (node == null)
		return;
	try {
		node.set(att, value);
	} catch(e:Dynamic) {}
}

function defaultSlotX(slot:String):Float {
	return switch(slot) {
		case "boyfriend": 770;
		case "girlfriend": 400;
		default: 100;
	}
}

function defaultSlotY(slot:String):Float {
	return switch(slot) {
		case "girlfriend": 130;
		default: 100;
	}
}

function defaultSlotScroll(slot:String):Float {
	return slot == "girlfriend" ? 0.95 : 1;
}

function destroy() {
	if (FlxG.cameras.list.contains(previewCam))
		FlxG.cameras.remove(previewCam);
	if (FlxG.cameras.list.contains(uiCam))
		FlxG.cameras.remove(uiCam);
}
