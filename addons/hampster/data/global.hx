var hampster = null;
var hampsterState = null;
var hampsterCamera = null;
var camHAMP = null;
var camOtherFallback = null;
var lastHampsterCameraMode = "";
var hampsterMousePoint = FlxPoint.get();
var draggingHampster = false;
var dragOffsetX = 0.0;
var dragOffsetY = 0.0;
var hampsterSize = 200.0;
var lastHampsterSize = 200.0;
var hampsterRTXStageName = "";
var hampsterRTXData = null;
var hampsterRTXShader = null;
var hampsterRTXEnabled = false;
var hampsterRTXHue = 0.0;

if (FlxG.save.data.deidadHampster == null)
	FlxG.save.data.deidadHampster = true;
if (FlxG.save.data.deidadHampsterRTX == null)
	FlxG.save.data.deidadHampsterRTX = true;
if (FlxG.save.data.deidadHampsterSize == null)
	FlxG.save.data.deidadHampsterSize = 200;
if (FlxG.save.data.deidadHampsterGameScroll == null)
	FlxG.save.data.deidadHampsterGameScroll = 0;
if (FlxG.save.data.deidadHampsterIgnoreBorders == null)
	FlxG.save.data.deidadHampsterIgnoreBorders = false;
if (FlxG.save.data.deidadHampsterCamera == null)
	FlxG.save.data.deidadHampsterCamera = "hud";

function postStateSwitch() {
	saveHampsterPosition();
	draggingHampster = false;
	hampster = null;
	hampsterState = null;
	hampsterCamera = null;
	camHAMP = null;
	camOtherFallback = null;
	lastHampsterCameraMode = "";
	hampsterRTXStageName = "";
	hampsterRTXData = null;
	hampsterRTXShader = null;
	hampsterRTXEnabled = false;
	hampsterRTXHue = 0.0;
	attachHampster();
}

function postUpdate(elapsed) {
	if (!FlxG.save.data.deidadHampster) {
		hideHampster();
		return;
	}

	attachHampster();
	updateHampsterCamera();
	updateHampsterScrollFactor();
	updateHampsterWheelControls();
	updateHampsterSize();
	updateHampsterDrag();
	keepHampsterOnScreen();
	updateHampsterFlip();
	updateHampsterRTX();
}

function gameResized(w, h) {
	keepHampsterOnScreen();
	saveHampsterPosition();
	updateHampsterFlip();
}

function destroy() {
	hideHampster();
}

function attachHampster() {
	if (FlxG.state == null)
		return;

	if (hampster == null || hampsterState != FlxG.state)
		createHampster();

	if (hampster == null)
		return;

	hampster.visible = true;
	updateHampsterCamera();
}

function createHampster() {
	hampsterSize = getSavedHampsterSize();
	lastHampsterSize = hampsterSize;
	lastHampsterCameraMode = getSavedHampsterCameraMode();
	hampsterCamera = getSelectedHampsterCamera();

	var oldX = getSavedHampsterX(lastHampsterCameraMode);
	var oldY = getSavedHampsterY(lastHampsterCameraMode);

	hampster = new FlxSprite(oldX, oldY);
	hampster.frames = Paths.getSparrowAtlas("Hampster");
	hampster.animation.addByPrefix("idle", "Hampster", 24, true);
	hampster.animation.play("idle");
	applyHampsterSize();
	hampster.updateHitbox();
	updateHampsterScrollFactor();
	hampster.antialiasing = true;
	hampsterState = FlxG.state;
	hampster.cameras = [hampsterCamera];
	FlxG.state.add(hampster);
	keepHampsterOnScreen();
	saveHampsterPosition();
	refreshHampsterRTX();
}

function hideHampster() {
	draggingHampster = false;

	if (hampster == null)
		return;

	hampster.visible = false;
}

function updateHampsterDrag() {
	var altPressed = FlxG.keys.pressed.ALT;
	FlxG.mouse.getWorldPosition(hampsterCamera, hampsterMousePoint);
	var mouseX = hampsterMousePoint.x;
	var mouseY = hampsterMousePoint.y;

	if (!altPressed) {
		if (draggingHampster)
			saveHampsterPosition();
		draggingHampster = false;
		return;
	}

	if (FlxG.mouse.justPressed && canStartHampsterDrag(mouseX, mouseY)) {
		draggingHampster = true;
		dragOffsetX = mouseX - hampster.x;
		dragOffsetY = mouseY - hampster.y;
	}

	if (!FlxG.mouse.pressed) {
		if (draggingHampster)
			saveHampsterPosition();
		draggingHampster = false;
	}

	if (draggingHampster) {
		hampster.x = mouseX - dragOffsetX;
		hampster.y = mouseY - dragOffsetY;
	}
}

function pointInsideHampster(x, y) {
	return hampster != null
		&& x >= hampster.x
		&& x <= hampster.x + hampster.width
		&& y >= hampster.y
		&& y <= hampster.y + hampster.height;
}

function canStartHampsterDrag(x, y) {
	var mode = getSavedHampsterCameraMode();
	return mode == "hud" || mode == "game" || pointInsideHampster(x, y);
}

function keepHampsterOnScreen() {
	if (hampster == null)
		return;
	if (FlxG.save.data.deidadHampsterIgnoreBorders)
		return;

	var cam = getActiveHampsterCamera();
	var left = getCameraLeft(cam);
	var top = getCameraTop(cam);
	var right = left + getCameraVisibleWidth(cam);
	var bottom = top + getCameraVisibleHeight(cam);

	hampster.x = FlxMath.bound(hampster.x, left, Math.max(left, right - hampster.width));
	hampster.y = FlxMath.bound(hampster.y, top, Math.max(top, bottom - hampster.height));
}

function updateHampsterSize() {
	if (hampster == null)
		return;

	var newSize = getSavedHampsterSize();
	if (newSize == lastHampsterSize)
		return;

	var centerX = hampster.x + (hampster.width * 0.5);
	var centerY = hampster.y + (hampster.height * 0.5);

	hampsterSize = newSize;
	lastHampsterSize = newSize;
	applyHampsterSize();
	hampster.updateHitbox();
	hampster.x = centerX - (hampster.width * 0.5);
	hampster.y = centerY - (hampster.height * 0.5);
	keepHampsterOnScreen();
	saveHampsterPosition();
}

function updateHampsterWheelControls() {
	if (hampster == null)
		return;

	var wheel = getMouseWheel();
	if (wheel == 0)
		return;

	var mode = getSavedHampsterCameraMode();

	if (FlxG.keys.pressed.CONTROL) {
		FlxG.save.data.deidadHampsterSize = FlxMath.bound(getSavedHampsterSize() + (wheel * 10), 50, 300);
		updateHampsterSize();
		FlxG.save.flush();
		return;
	}

	if (mode == "game" && FlxG.keys.pressed.ALT) {
		FlxG.save.data.deidadHampsterGameScroll = FlxMath.bound(getSavedHampsterGameScroll() + (wheel * 0.05), 0, 2);
		updateHampsterScrollFactor();
		FlxG.save.flush();
	}
}

function updateHampsterScrollFactor() {
	if (hampster == null)
		return;

	var mode = getSavedHampsterCameraMode();
	var scroll = mode == "game" ? getSavedHampsterGameScroll() : 0;
	try {
		hampster.scrollFactor.set(scroll, scroll);
	} catch(e:Dynamic) {}
}

function updateHampsterFlip() {
	if (hampster == null)
		return;

	var cam = getActiveHampsterCamera();
	var middle = getCameraLeft(cam) + (getCameraVisibleWidth(cam) * 0.5);
	hampster.flipX = (hampster.x + (hampster.width * 0.5)) < middle;
}

function updateHampsterRTX() {
	if (hampster == null)
		return;

	var enabled = FlxG.save.data.deidadHampsterRTX;
	if (!enabled) {
		clearHampsterRTX();
		hampsterRTXEnabled = false;
		return;
	}

	var stageName = getCurrentStageName();
	if (enabled != hampsterRTXEnabled || stageName != hampsterRTXStageName || hampster.shader != hampsterRTXShader) {
		hampsterRTXEnabled = enabled;
		hampsterRTXStageName = stageName;
		hampsterRTXData = readHampsterRTXData(stageName);
		refreshHampsterRTX();
	}

	if (hampsterRTXShader != null && hampster.shader == hampsterRTXShader)
		setHampsterRTXUniform(hampsterRTXShader, "innerShadowAngle", getHampsterRTXAngle());
}

function setRTXHue(value:Float) {
	setHampsterRTXHue(value);
}

function setHampsterRTXHue(value:Float) {
	if (Math.isNaN(value))
		value = 0;

	hampsterRTXHue = value;
	if (hampsterRTXShader != null)
		setHampsterRTXUniform(hampsterRTXShader, "hue", hampsterRTXHue);
}

function refreshHampsterRTX() {
	if (hampster == null)
		return;

	if (!FlxG.save.data.deidadHampsterRTX) {
		clearHampsterRTX();
		return;
	}

	if (hampsterRTXData == null)
		hampsterRTXData = readHampsterRTXData(getCurrentStageName());

	if (hampsterRTXData == null) {
		clearHampsterRTX();
		return;
	}

	try {
		hampsterRTXShader = new CustomShader("HampsterRTX");
		setupHampsterRTXShader(hampsterRTXShader);
		hampster.shader = hampsterRTXShader;
	} catch(e:Dynamic) {
		clearHampsterRTX();
	}
}

function clearHampsterRTX() {
	if (hampster != null && hampster.shader == hampsterRTXShader)
		hampster.shader = null;
	hampsterRTXShader = null;
}

function setupHampsterRTXShader(shader) {
	setHampsterRTXUniform(shader, "overlayColor", hampsterRTXColorToVec4(getHampsterRTXString("overlay", "0x000000"), getHampsterRTXFloat("overlayAlpha", 0)));
	setHampsterRTXUniform(shader, "satinColor", hampsterRTXColorToVec4(getHampsterRTXString("satin", "0xFFFFFF"), getHampsterRTXFloat("satinAlpha", 0)));
	setHampsterRTXUniform(shader, "innerShadowColor", hampsterRTXColorToVec4(getHampsterRTXString("inner", "0x000000"), getHampsterRTXFloat("innerAlpha", 0)));
	setHampsterRTXUniform(shader, "innerShadowDistance", getHampsterRTXFloat("innerDistance", 10));
	setHampsterRTXUniform(shader, "innerShadowAngle", getHampsterRTXAngle());
	setHampsterRTXUniform(shader, "layernumbers", getHampsterRTXFloat("layernumbers", getHampsterRTXFloat("layers", 5)));
	setHampsterRTXUniform(shader, "layerseparation", getHampsterRTXFloat("layerseparation", getHampsterRTXFloat("separation", 1)));
	setHampsterRTXUniform(shader, "hue", hampsterRTXHue);
}

function readHampsterRTXData(stageName) {
	if (stageName == null || stageName == "")
		return null;

	var path = Paths.file("data/stages/" + stageName + ".json");
	if (!Assets.exists(path))
		return null;

	try {
		var text = stripHampsterRTXBOM(Assets.getText(path));
		var parsed = Json.parse(text);
		return parsed == null ? null : Reflect.field(parsed, "rtxData");
	} catch(e:Dynamic) {}

	return null;
}

function stripHampsterRTXBOM(text) {
	if (text == null || text.length == 0)
		return text;
	if (StringTools.fastCodeAt(text, 0) == 65279)
		return text.substr(1);
	return text;
}

function getCurrentStageName() {
	if (FlxG.state != null) {
		for (field in ["curStage", "stageName"]) {
			try {
				var value = Reflect.field(FlxG.state, field);
				if (value != null)
					return Std.string(value);
			} catch(e:Dynamic) {}
		}

		try {
			var song = Reflect.field(FlxG.state, "SONG");
			if (song != null) {
				var stage = Reflect.field(song, "stage");
				if (stage != null)
					return Std.string(stage);
			}
		} catch(e:Dynamic) {}
	}

	try {
		if (PlayState.SONG != null && PlayState.SONG.stage != null)
			return Std.string(PlayState.SONG.stage);
	} catch(e:Dynamic) {}

	return "";
}

function getHampsterRTXAngle() {
	if (getHampsterRTXBool("pointLight", false) && hampster != null) {
		var midpoint = hampster.getGraphicMidpoint();
		var dx = getHampsterRTXFloat("lightX", 0) - midpoint.x;
		var dy = getHampsterRTXFloat("lightY", 0) - midpoint.y;
		if (hampster.flipX) dx = -dx;
		if (hampster.flipY) dy = -dy;
		return Math.atan2(dy, dx);
	}

	var radians = getHampsterRTXFloat("innerAngle", 270) * Math.PI / 180;
	if (hampster != null && hampster.flipX)
		radians = Math.atan2(Math.sin(radians), -Math.cos(radians));
	return radians;
}

function getHampsterRTXString(field, fallback) {
	var value = Reflect.field(hampsterRTXData, field);
	return value == null ? fallback : Std.string(value);
}

function getHampsterRTXFloat(field, fallback) {
	var value = Reflect.field(hampsterRTXData, field);
	if (value == null)
		return fallback;

	var parsed = Std.parseFloat(Std.string(value));
	return Math.isNaN(parsed) ? fallback : parsed;
}

function getHampsterRTXBool(field, fallback) {
	var value = Reflect.field(hampsterRTXData, field);
	if (value == null)
		return fallback;
	return Std.string(value).toLowerCase() == "true";
}

function hampsterRTXColorToVec4(value, alpha) {
	var rgb = parseHampsterRTXColor(value);
	return [rgb[0], rgb[1], rgb[2], alpha];
}

function parseHampsterRTXColor(value) {
	var raw = Std.string(value);
	raw = StringTools.replace(raw, "#", "");
	raw = StringTools.replace(raw, "0x", "");
	raw = StringTools.replace(raw, "0X", "");

	if (raw.length == 8)
		raw = raw.substr(2, 6);

	if (raw.length != 6)
		return [1, 1, 1];

	var r = Std.parseInt("0x" + raw.substr(0, 2));
	var g = Std.parseInt("0x" + raw.substr(2, 2));
	var b = Std.parseInt("0x" + raw.substr(4, 2));

	if (r == null || g == null || b == null)
		return [1, 1, 1];

	return [r / 255, g / 255, b / 255];
}

function setHampsterRTXUniform(shader, property, value) {
	try {
		shader.hset(property, value);
	} catch(e:Dynamic) {
		try {
			Reflect.setProperty(shader, property, value);
		} catch(e2:Dynamic) {}
	}
}

function applyHampsterSize() {
	hampster.setGraphicSize(Std.int(hampsterSize), Std.int(hampsterSize));
}

function updateHampsterCamera() {
	if (hampster == null)
		return;

	var mode = getSavedHampsterCameraMode();
	var selectedCamera = getSelectedHampsterCamera();

	if (mode != lastHampsterCameraMode || selectedCamera != hampsterCamera) {
		saveHampsterPosition();
		lastHampsterCameraMode = mode;
		hampsterCamera = selectedCamera;
		hampster.x = getSavedHampsterX(mode);
		hampster.y = getSavedHampsterY(mode);
		updateHampsterScrollFactor();
		keepHampsterOnScreen();
	}

	hampster.cameras = [hampsterCamera];
}

function getSelectedHampsterCamera() {
	var mode = getSavedHampsterCameraMode();
	switch (mode) {
		case "game":
			if (FlxG.state != null && Reflect.hasField(FlxG.state, "camGame")) {
				var gameCamera = Reflect.field(FlxG.state, "camGame");
				if (gameCamera != null)
					return gameCamera;
			}
			return FlxG.camera;
		case "other":
			return getOtherCamera();
		case "hamp":
			return getHampCamera();
		case "hud":
			if (FlxG.state != null && Reflect.hasField(FlxG.state, "camHUD")) {
				var hudCamera = Reflect.field(FlxG.state, "camHUD");
				if (hudCamera != null)
					return hudCamera;
			}
	}

	return FlxG.camera;
}

function getActiveHampsterCamera() {
	if (hampsterCamera == null)
		hampsterCamera = getSelectedHampsterCamera();
	return hampsterCamera;
}

function getHampCamera() {
	if (camHAMP == null) {
		camHAMP = new FlxCamera();
		camHAMP.bgColor = 0;
		FlxG.cameras.add(camHAMP, false);
	}

	camHAMP.scroll.set(0, 0);
	camHAMP.zoom = 1;
	return camHAMP;
}

function getOtherCamera() {
	if (FlxG.state != null && Reflect.hasField(FlxG.state, "camOther")) {
		var otherCamera = Reflect.field(FlxG.state, "camOther");
		if (otherCamera != null)
			return otherCamera;
	}

	if (camOtherFallback == null) {
		camOtherFallback = new FlxCamera();
		camOtherFallback.bgColor = 0;
		FlxG.cameras.add(camOtherFallback, false);
	}

	camOtherFallback.scroll.set(0, 0);
	camOtherFallback.zoom = 1;
	return camOtherFallback;
}

function getSavedHampsterSize() {
	var size = FlxG.save.data.deidadHampsterSize;
	if (size == null)
		size = 200;
	return FlxMath.bound(size, 50, 300);
}

function getSavedHampsterGameScroll() {
	var scroll = FlxG.save.data.deidadHampsterGameScroll;
	if (scroll == null)
		scroll = 0;
	return FlxMath.bound(scroll, 0, 2);
}

function getSavedHampsterCameraMode() {
	var mode = FlxG.save.data.deidadHampsterCamera;
	if (mode == null)
		mode = "hud";
	return mode;
}

function getSavedHampsterX(mode) {
	var value = Reflect.field(FlxG.save.data, getHampsterPositionKey("X", mode));
	if (value != null)
		return value;
	if (mode == "hud" && FlxG.save.data.deidadHampsterX != null)
		return FlxG.save.data.deidadHampsterX;
	return getDefaultHampsterX();
}

function getSavedHampsterY(mode) {
	var value = Reflect.field(FlxG.save.data, getHampsterPositionKey("Y", mode));
	if (value != null)
		return value;
	if (mode == "hud" && FlxG.save.data.deidadHampsterY != null)
		return FlxG.save.data.deidadHampsterY;
	return getDefaultHampsterY();
}

function saveHampsterPosition() {
	if (hampster == null)
		return;

	var mode = lastHampsterCameraMode != "" ? lastHampsterCameraMode : getSavedHampsterCameraMode();
	Reflect.setField(FlxG.save.data, getHampsterPositionKey("X", mode), hampster.x);
	Reflect.setField(FlxG.save.data, getHampsterPositionKey("Y", mode), hampster.y);
	FlxG.save.data.deidadHampsterX = hampster.x;
	FlxG.save.data.deidadHampsterY = hampster.y;
	FlxG.save.flush();
}

function getHampsterPositionKey(axis, mode) {
	return "deidadHampster" + axis + "_" + mode;
}

function getDefaultHampsterX() {
	var cam = getActiveHampsterCamera();
	return getCameraLeft(cam) + getCameraVisibleWidth(cam) - getSavedHampsterSize() - 20;
}

function getDefaultHampsterY() {
	var cam = getActiveHampsterCamera();
	return getCameraTop(cam) + getCameraVisibleHeight(cam) - getSavedHampsterSize() - 20;
}

function getCameraLeft(cam) {
	return getCameraScrollAxis(cam, "x");
}

function getCameraTop(cam) {
	return getCameraScrollAxis(cam, "y");
}

function getCameraVisibleWidth(cam) {
	if (cam == null)
		return FlxG.width;
	return getCameraNumber(cam, "width", FlxG.width) / Math.max(0.001, getCameraNumber(cam, "zoom", 1));
}

function getCameraVisibleHeight(cam) {
	if (cam == null)
		return FlxG.height;
	return getCameraNumber(cam, "height", FlxG.height) / Math.max(0.001, getCameraNumber(cam, "zoom", 1));
}

function getCameraScrollAxis(cam, axis) {
	if (cam == null)
		return 0;

	try {
		var scroll = Reflect.field(cam, "scroll");
		if (scroll != null) {
			var value = Reflect.field(scroll, axis);
			if (value != null)
				return value;
		}
	} catch(e:Dynamic) {}

	return 0;
}

function getCameraNumber(cam, field, fallback) {
	if (cam == null)
		return fallback;

	try {
		var value = Reflect.field(cam, field);
		if (value != null)
			return value;
	} catch(e:Dynamic) {}

	return fallback;
}

function getMouseWheel() {
	try {
		var wheel = Reflect.field(FlxG.mouse, "wheel");
		if (wheel != null)
			return wheel;
	} catch(e:Dynamic) {}

	return 0;
}
