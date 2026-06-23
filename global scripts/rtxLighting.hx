var rtxStageName:String = "";
var rtxData:Dynamic = null;
var rtxTargets:Array<Dynamic> = [];
var rtxShaders:Array<Dynamic> = [];
var rtxOverrideNames:Array<String> = [];
var rtxOverrideValues:Array<Float> = [];
var rtxDebug:Bool = false;
var rtxHue:Float = 0;

function create() {
	rtxTargets = [];
	rtxShaders = [];
	rtxOverrideNames = [];
	rtxOverrideValues = [];
}

function postCreate() {
	loadStageRTX(curStage);
}

function onStageChanged(name:String) {
	loadStageRTX(name);
}

function onCharactersChanged(strumlineID:Int, characterNames:String) {
	applyRTXToCharacters();
}

function loadStageRTX(name:String) {
	rtxStageName = name;
	rtxTrace("loading stage RTX for: " + name);
	rtxData = readStageRTXData(name);
	clearRTXShaders();

	if (rtxData != null) {
		rtxTrace("rtxData found for " + name + ": " + Json.stringify(rtxData));
		applyRTXToCharacters();
	} else {
		rtxTrace("no rtxData found for " + name);
	}
}

function readStageRTXData(name:String):Dynamic {
	var path = getStageRTXPath(name);
	rtxTrace("looking for stage RTX json at: " + path);
	if (!Assets.exists(path)) {
		rtxTrace("stage RTX json does not exist: " + path);
		return null;
	}

	var text = stripUTF8BOM(Assets.getText(path));
	var parsed:Dynamic = null;
	try {
		parsed = Json.parse(text);
	} catch(e:Dynamic) {
		rtxTrace("could not parse stage RTX json " + path + ": " + e);
		return null;
	}
	rtxTrace("stage RTX json loaded: " + path);
	return parsed == null ? null : Reflect.field(parsed, "rtxData");
}

function getStageRTXPath(name:String):String {
	var names:Array<String> = [];
	addStageRTXCandidate(names, name);

	try {
		if (stage != null) {
			addStageRTXCandidate(names, stage.stageFile);
			addStageRTXCandidate(names, stage.stageName);
			if (stage.stageXML != null && stage.stageXML.exists("name"))
				addStageRTXCandidate(names, stage.stageXML.get("name"));
		}
	} catch(e:Dynamic) {}

	for (candidate in names) {
		var path = Paths.file("data/stages/" + candidate + ".json");
		rtxTrace("checking stage RTX candidate: " + path);
		if (Assets.exists(path))
			return path;
	}

	return Paths.file("data/stages/" + name + ".json");
}

function addStageRTXCandidate(list:Array<String>, value:Dynamic) {
	if (value == null) return;

	var name = Std.string(value);
	if (name == "" || list.contains(name)) return;
	list.push(name);
}

function stripUTF8BOM(text:String):String {
	if (text == null || text.length == 0) return text;
	if (StringTools.fastCodeAt(text, 0) == 65279) return text.substr(1);
	return text;
}

function clearRTXShaders() {
	for (i in 0...rtxTargets.length) {
		var target = rtxTargets[i];
		var shader = rtxShaders[i];
		if (target != null && target.shader == shader) {
			target.shader = null;
		}
	}
	rtxTargets = [];
	rtxShaders = [];
}

function applyRTXToCharacters() {
	if (rtxData == null) return;

	var applied = 0;
	for (strumLine in strumLines.members) {
		if (strumLine == null || strumLine.characters == null) continue;

		for (char in strumLine.characters) {
			applyRTXToSprite(char);
			applied++;
		}
	}
	rtxTrace("RTX apply pass finished. Character slots checked: " + applied + ", active targets: " + rtxTargets.length);
}

function applyRTXToSprite(sprite:Dynamic) {
	if (sprite == null || rtxTargets.indexOf(sprite) >= 0) return;

	var shader = new CustomShader("RTXEffect");
	setupRTXShader(shader, sprite);
	sprite.shader = shader;
	rtxTargets.push(sprite);
	rtxShaders.push(shader);
	rtxTrace("RTX shader applied to sprite: " + getSpriteDebugName(sprite));
}

function setupRTXShader(shader:Dynamic, sprite:Dynamic) {
	var overlay = colorToVec4(getRTXString("overlay", "0x000000"), getRTXFloat("overlayAlpha", 0));
	var satin = colorToVec4(getRTXString("satin", "0xFFFFFF"), getRTXFloat("satinAlpha", 0));
	var inner = colorToVec4(getRTXString("inner", "0x000000"), getRTXFloat("innerAlpha", 0));
	var distance = getRTXFloat("innerDistance", 10);
	var angle = getRTXAngle(sprite);
	var angles = getRTXAngles(sprite);
	var layers = getRTXFloat("layernumbers", getRTXFloat("layers", 5));
	var separation = getRTXFloat("layerseparation", getRTXFloat("separation", 1));

	setRTXUniform(shader, "overlayColor", overlay);
	setRTXUniform(shader, "satinColor", satin);
	setRTXUniform(shader, "innerShadowColor", inner);
	setRTXUniform(shader, "innerShadowDistance", distance);
	setRTXUniform(shader, "innerShadowAngle", angle);
	applyRTXLightUniforms(shader, sprite, angles);
	setRTXUniform(shader, "layernumbers", layers);
	setRTXUniform(shader, "layerseparation", separation);
	setRTXUniform(shader, "hue", rtxHue);

	rtxTrace("uniforms for " + getSpriteDebugName(sprite) + " -> overlay=" + overlay + ", satin=" + satin + ", inner=" + inner + ", distance=" + distance + ", angleDeg=" + (angle * 180 / Math.PI) + ", angleRad=" + angle + ", pointLights=" + angles.length + ", layers=" + layers + ", separation=" + separation + ", hue=" + rtxHue);
}

function setRTXHue(value:Float) {
	setRTXShaderProperty("hue", value);
}

function setRTXShaderProperty(property:String, value:Float) {
	setRTXOverride(property, value);

	switch(property) {
		case "hue":
			rtxHue = value;
		case "innerShadowDistance":
			setRTXOverride("innerDistance", value);
		case "innerShadowAngle":
			setRTXOverride("innerAngle", value);
	}

	for (shader in rtxShaders) {
		if (shader == null) continue;

		switch(property) {
			case "overlayAlpha" | "satinAlpha" | "innerAlpha":
				refreshRTXColors(shader);
			case "innerDistance" | "innerShadowDistance":
				setRTXUniform(shader, "innerShadowDistance", value);
			case "innerAngle" | "innerShadowAngle":
				refreshRTXAngles();
			case "layers" | "layernumbers":
				setRTXUniform(shader, "layernumbers", value);
			case "separation" | "layerseparation":
				setRTXUniform(shader, "layerseparation", value);
			default:
				setRTXUniform(shader, property, value);
		}
	}
}

function refreshRTXColors(shader:Dynamic) {
	setRTXUniform(shader, "overlayColor", colorToVec4(getRTXString("overlay", "0x000000"), getRTXFloat("overlayAlpha", 0)));
	setRTXUniform(shader, "satinColor", colorToVec4(getRTXString("satin", "0xFFFFFF"), getRTXFloat("satinAlpha", 0)));
	setRTXUniform(shader, "innerShadowColor", colorToVec4(getRTXString("inner", "0x000000"), getRTXFloat("innerAlpha", 0)));
	refreshRTXLights();
}

function refreshRTXAngles() {
	refreshRTXLights();
}

function refreshRTXLights() {
	for (i in 0...rtxTargets.length) {
		var sprite = rtxTargets[i];
		var shader = rtxShaders[i];
		if (sprite == null || shader == null) continue;
		setRTXUniform(shader, "innerShadowAngle", getRTXAngle(sprite));
		applyRTXLightUniforms(shader, sprite, getRTXAngles(sprite));
	}
}

function setRTXUniform(shader:Dynamic, property:String, value:Dynamic) {
	try {
		shader.hset(property, value);
	} catch(e:Dynamic) {
		try {
			Reflect.setProperty(shader, property, value);
		} catch(e2:Dynamic) {}
	}
}

function colorToVec4(value:String, alpha:Float):Array<Float> {
	var rgb = parseRTXColor(value);
	return [rgb[0], rgb[1], rgb[2], alpha];
}

function parseRTXColor(value:String):Array<Float> {
	var raw = Std.string(value);
	raw = StringTools.replace(raw, "#", "");
	raw = StringTools.replace(raw, "0x", "");
	raw = StringTools.replace(raw, "0X", "");

	if (raw.length == 8) {
		raw = raw.substr(2, 6);
	}

	if (raw.length != 6) {
		rtxTrace("could not parse color '" + value + "', using white");
		return [1, 1, 1];
	}

	var r = Std.parseInt("0x" + raw.substr(0, 2));
	var g = Std.parseInt("0x" + raw.substr(2, 2));
	var b = Std.parseInt("0x" + raw.substr(4, 2));

	if (r == null || g == null || b == null) {
		rtxTrace("could not parse color '" + value + "', using white");
		return [1, 1, 1];
	}

	return [r / 255, g / 255, b / 255];
}

function setRTXOverride(field:String, value:Float) {
	var i = rtxOverrideNames.indexOf(field);
	if (i < 0) {
		rtxOverrideNames.push(field);
		rtxOverrideValues.push(value);
	} else {
		rtxOverrideValues[i] = value;
	}
}

function getRTXOverride(field:String):Dynamic {
	var i = rtxOverrideNames.indexOf(field);
	return i < 0 ? null : rtxOverrideValues[i];
}

function update(elapsed:Float) {
	if (rtxData == null) return;

	for (i in 0...rtxTargets.length) {
		var sprite = rtxTargets[i];
		var shader = rtxShaders[i];
		if (sprite == null || shader == null) continue;
		if (sprite.shader != shader) continue;

		setRTXUniform(shader, "innerShadowAngle", getRTXAngle(sprite));
		applyRTXLightUniforms(shader, sprite, getRTXAngles(sprite));
	}
}

function applyRTXAngleUniforms(shader:Dynamic, angles:Array<Float>) {
	if (angles == null)
		angles = [];

	setRTXUniform(shader, "pointLightCount", angles.length);
	for (i in 0...4) {
		var angle = i < angles.length ? angles[i] : 0;
		setRTXUniform(shader, "innerShadowAngle" + i, angle);
	}
}

function applyRTXLightUniforms(shader:Dynamic, sprite:Dynamic, angles:Array<Float>) {
	applyRTXAngleUniforms(shader, angles);

	var lights = getRTXBool("pointLight", false) ? getRTXPointLights() : [];
	for (i in 0...4) {
		var light = i < lights.length ? normalizeRTXPointLight(lights[i]) : null;
		setRTXUniform(shader, "overlayColor" + i, colorToVec4(getLightString(light, "overlay", getRTXString("overlay", "0x000000")), getLightFloat(light, "overlayAlpha", getRTXFloat("overlayAlpha", 0))));
		setRTXUniform(shader, "satinColor" + i, colorToVec4(getLightString(light, "satin", getRTXString("satin", "0xFFFFFF")), getLightFloat(light, "satinAlpha", getRTXFloat("satinAlpha", 0))));
		setRTXUniform(shader, "innerShadowColor" + i, colorToVec4(getLightString(light, "inner", getRTXString("inner", "0x000000")), getLightFloat(light, "innerAlpha", getRTXFloat("innerAlpha", 0))));
		setRTXUniform(shader, "innerShadowDistance" + i, getLightFloat(light, "innerDistance", getRTXFloat("innerDistance", 10)));
		setRTXUniform(shader, "layernumbers" + i, getLightFloat(light, "layernumbers", getRTXFloat("layernumbers", getRTXFloat("layers", 5))));
		setRTXUniform(shader, "layerseparation" + i, getLightFloat(light, "layerseparation", getRTXFloat("layerseparation", getRTXFloat("separation", 1))));
	}
}

function getRTXAngles(sprite:Dynamic):Array<Float> {
	var angles:Array<Float> = [];
	if (!getRTXBool("pointLight", false) || sprite == null)
		return angles;

	var lights = getRTXPointLights();
	for (light in lights) {
		if (angles.length >= 4)
			break;
		var normalizedLight = normalizeRTXPointLight(light);
		angles.push(getRTXPointLightAngle(sprite, getDynamicFloat(normalizedLight, "x", 0), getDynamicFloat(normalizedLight, "y", 0)));
	}
	return angles;
}

function getRTXAngle(sprite:Dynamic):Float {
	if (getRTXBool("pointLight", false) && sprite != null) {
		var lights = getRTXPointLights();
		if (lights.length > 0) {
			var firstLight = normalizeRTXPointLight(lights[0]);
			return getRTXPointLightAngle(sprite, getDynamicFloat(firstLight, "x", getRTXFloat("lightX", 0)), getDynamicFloat(firstLight, "y", getRTXFloat("lightY", 0)));
		}
	}

	var radians = getRTXFloat("innerAngle", 270) * Math.PI / 180;
	if (sprite != null && sprite.flipX) {
		radians = Math.atan2(Math.sin(radians), -Math.cos(radians));
	}
	return radians;
}

function getRTXPointLightAngle(sprite:Dynamic, lightX:Float, lightY:Float):Float {
	var midpoint = sprite.getGraphicMidpoint();
	var dx = lightX - midpoint.x;
	var dy = lightY - midpoint.y;
	if (sprite.flipX) dx = -dx;
	if (sprite.flipY) dy = -dy;
	return Math.atan2(dy, dx);
}

function getRTXPointLights():Array<Dynamic> {
	var lights:Array<Dynamic> = [];
	var raw = Reflect.field(rtxData, "pointLights");
	if (raw != null) {
		try {
			for (light in cast(raw, Array<Dynamic>)) {
				if (light != null)
					lights.push(normalizeRTXPointLight(light));
			}
		} catch(e:Dynamic) {}
	}

	if (lights.length <= 0)
		lights.push(normalizeRTXPointLight({x: getRTXFloat("lightX", 0), y: getRTXFloat("lightY", 0)}));
	return lights;
}

function normalizeRTXPointLight(light:Dynamic):Dynamic {
	if (light == null)
		light = {};

	setLightDefault(light, "x", getRTXFloat("lightX", 0));
	setLightDefault(light, "y", getRTXFloat("lightY", 0));
	setLightDefault(light, "overlay", getRTXString("overlay", "0x000000"));
	setLightDefault(light, "overlayAlpha", getRTXFloat("overlayAlpha", 0));
	setLightDefault(light, "satin", getRTXString("satin", "0xFFFFFF"));
	setLightDefault(light, "satinAlpha", getRTXFloat("satinAlpha", 0));
	setLightDefault(light, "inner", getRTXString("inner", "0x000000"));
	setLightDefault(light, "innerAlpha", getRTXFloat("innerAlpha", 0));
	setLightDefault(light, "innerDistance", getRTXFloat("innerDistance", 10));
	setLightDefault(light, "layernumbers", getRTXFloat("layernumbers", getRTXFloat("layers", 5)));
	setLightDefault(light, "layerseparation", getRTXFloat("layerseparation", getRTXFloat("separation", 1)));
	return light;
}

function setLightDefault(light:Dynamic, field:String, value:Dynamic) {
	if (Reflect.field(light, field) == null)
		Reflect.setField(light, field, value);
}

function getLightString(light:Dynamic, field:String, fallback:String):String {
	var value = light == null ? null : Reflect.field(light, field);
	return value == null ? fallback : Std.string(value);
}

function getLightFloat(light:Dynamic, field:String, fallback:Float):Float {
	var value = light == null ? null : Reflect.field(light, field);
	if (value == null) return fallback;
	var parsed = Std.parseFloat(Std.string(value));
	return Math.isNaN(parsed) ? fallback : parsed;
}

function getDynamicFloat(obj:Dynamic, field:String, fallback:Float):Float {
	var value = obj == null ? null : Reflect.field(obj, field);
	if (value == null)
		return fallback;
	var parsed = Std.parseFloat(Std.string(value));
	return Math.isNaN(parsed) ? fallback : parsed;
}

function getRTXString(field:String, fallback:String):String {
	var value = Reflect.field(rtxData, field);
	return value == null ? fallback : Std.string(value);
}

function getRTXFloat(field:String, fallback:Float):Float {
	var overrideValue = getRTXOverride(field);
	if (overrideValue != null) return overrideValue;

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

function getSpriteDebugName(sprite:Dynamic):String {
	if (sprite == null) return "null";
	try {
		var name = Reflect.field(sprite, "curCharacter");
		if (name != null) return Std.string(name);
	} catch(e:Dynamic) {}
	try {
		var name = Reflect.field(sprite, "characterName");
		if (name != null) return Std.string(name);
	} catch(e:Dynamic) {}
	try {
		var name = Reflect.field(sprite, "name");
		if (name != null) return Std.string(name);
	} catch(e:Dynamic) {}
	return Std.string(sprite);
}

function rtxTrace(message:String) {
	if (rtxDebug) trace("[RTXLighting] " + message);
}
