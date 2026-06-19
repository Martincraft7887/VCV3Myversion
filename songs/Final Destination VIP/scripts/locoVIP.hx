import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

var locoImages:Array<FlxSprite> = [];
var locoBg:FlxSprite = null;
var locoFloatTime:Float = 0;
var locoFloatEnabled:Bool = true;
var locoStartZoom:Float = 1;
var locoFloatBaseZoom:Float = 0.95;
var locoEndZoom:Float = 0.6;
var locoCreated:Bool = false;
var locoSceneStarted:Bool = false;
var locoCam:FlxCamera = null;
var locoShaders:Map<String, Dynamic> = [];
var locoShaderTime:Float = 0;
var locoShadersReady:Bool = false;
var locoCARadiusX:Float = 0.0075;
var locoCARadiusY:Float = 0.0075;
var locoOvalSpeed:Float = 3;

var lyricTexts:Map<String, FlxText> = [];
var lyricPositions:Map<String, Dynamic> = [];
var lyricCopies:Array<FlxText> = [];

function create() {
	createLoco();
}

function postCreate() {
	createLoco();
}

function createLoco() {
	if (locoCreated) return;
	locoCreated = true;
	camHUD.alpha = 0;
	createLocoCamera();
	createLocoIntro();
	createLocoLyrics();
}

function createLocoCamera() {
	locoCam = new FlxCamera();
	locoCam.bgColor = 0;
	locoCam.zoom = locoStartZoom;
	locoCam.alpha = 1;
	locoCam.visible = true;
	FlxG.cameras.add(locoCam, false);
	keepLocoCameraOnTop();
}

function createLocoShaders() {
	if (locoCam == null || locoShadersReady) return;
	locoShadersReady = true;

	addLocoShader("greyscale", ["locoVIP/GreyscaleEffect"], {
		strength: 1
	});
	addLocoShader("bars", ["locoVIP/bars"], {
		effect: 0,
		effect2: 0,
		angle1: 0,
		angle2: 0
	});
	addLocoShader("Sunrays", ["locoVIP/Sunrays"], {
		strength: 1.5,
		iTime: 0
	});
	addLocoShader("mirror", ["locoVIP/BarrelBlurEffect"], {
		barrel: 0,
		zoom: 1,
		warp: 0,
		angle: 0,
		iTime: 0,
		x: 0,
		y: 0,
		dist: -0.07,
		Xdirection: 0,
		Ydirection: 0,
		doChroma: false,
		rotation: [0, 0, 0],
		repeatNormal: false
	});
	addLocoShader("ca", ["locoVIP/ChromAbEffect"], {
		strength: 0.003,
		strengthY: 0
	});
	addLocoShader("blur", ["locoVIP/zoomblur"], {
		focusPower: 0,
		posX: -3,
		posY: 0
	});
	addLocoShader("vignette", ["locoVIP/vignette"], {
		strength: 15,
		size: 0.15,
		red: 0,
		green: 0,
		blue: 0,
		followAlpha: true
	});
	addLocoShader("bloom", ["locoVIP/BloomEffect"], {
		contrast: 1,
		brightness: -0.1,
		effect: 1,
		strength: 0
	});
	addLocoShader("vidrio", ["locoVIP/BreakGlassMania"], {
		u_pointCount: 35,
		zoom: 1,
		strength: 0
	});
}

function addLocoShader(name:String, paths:Array<String>, props:Dynamic) {
	for (path in paths) {
		try {
			var shader = new CustomShader(path);
			for (field in Reflect.fields(props)) {
				try {
					Reflect.setField(shader, field, Reflect.field(props, field));
				} catch (e:Dynamic) {}
			}
			locoCam.addShader(shader);
			locoShaders.set(name, shader);
			return;
		} catch (e:Dynamic) {}
	}
}

function createLocoIntro() {
	if (locoCam != null) locoCam.zoom = locoStartZoom;

	locoBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	locoBg.scale.set(1.5, 1.5);
	locoBg.updateHitbox();
	locoBg.scrollFactor.set(0, 0);
	locoBg.screenCenter();
	locoBg.cameras = [locoCam];
	add(locoBg);

	for (name in ["mark", "scene1", "scene2", "scene3", "scene4", "scene5"]) {
		var spr = new FlxSprite().loadGraphic(Paths.image("songs img/Final Destination VIP/" + name));
		spr.scrollFactor.set(0, 0);
		spr.screenCenter();
		spr.x += 620;
		spr.y -= 320;
		spr.alpha = name == "scene5" ? 0 : 1;
		spr.cameras = [locoCam];
		add(spr);
		locoImages.push(spr);
	}

	if (locoImages.length > 1) {
		locoImages[1].alpha = 0;
		locoImages[1].y -= 150;
	}
}

function createLocoLyrics() {
	for (id in ["1", "2", "3", "4", "5"]) {
		var txt = new FlxText(0, -200, 0, "", 85);
		txt.setFormat(Paths.font("Contb___.ttf"), 85, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.borderSize = 4;
		txt.borderQuality = 3;
		txt.antialiasing = true;
		txt.alpha = 0;
		txt.cameras = [locoCam];
		add(txt);
		lyricTexts.set(id, txt);
	}
}

function startSong() {
	startLocoScene();
}

function onSongStart() {
	startLocoScene();
}

function startLocoScene() {
	if (locoSceneStarted) return;
	locoSceneStarted = true;
	keepLocoCameraOnTop();
	createLocoShaders();
	if (locoImages.length > 1) {
		var dur = Conductor.crochet * 0.008;
		locoImages[1].visible = true;
		FlxTween.tween(locoImages[1], {y: locoImages[1].y + 150, alpha: 1}, dur, {ease: FlxEase.cubeOut});
	}
}

function update(elapsed:Float) {
	if (!locoSceneStarted && Conductor.songPosition >= 0)
		startLocoScene();

	keepLocoCameraOnTop();
	updateLocoShaders(elapsed);

	if (!locoFloatEnabled) return;

	locoFloatTime += elapsed;
	var t = locoFloatTime * 1.25;
	var zoomT = locoFloatTime;
	var floatX = Math.sin(t) * 40;
	var floatY = Math.sin(t) * Math.cos(t) * 40;

	for (spr in locoImages)
		if (spr != null) spr.offset.set(-floatX, -floatY);

	if (locoCam != null)
		locoCam.zoom = locoFloatBaseZoom + Math.sin(zoomT) * 0.075;
}

function keepLocoCameraOnTop() {
	if (locoCam == null) return;

	try {
		var cameraList = FlxG.cameras.list;
		if (cameraList != null && !cameraList.contains(locoCam))
			FlxG.cameras.add(locoCam, false);
	} catch (e:Dynamic) {}
}

function stepHit() {
	runLocoCinematics();

	switch (curStep) {
		case 27:
			moveLocoImages(-1300, 0, crochetTime(0.004));
		case 60:
			moveLocoImages(0, 700, crochetTime(0.004));
		case 92:
			moveLocoImages(1300, 0, crochetTime(0.004));
		case 104:
			moveLocoImages(-620, -500, crochetTime(0.003), 1);
		case 128:
			resetLocoIntro();
			clearLocoIntro();
			camHUD.alpha = 1;
			camHUD.flash(FlxColor.WHITE, 1);
			removeLocoCamera();
	}

	runLocoLyrics(1568, true);
	runLocoLyrics(1632, false);
}

function crochetTime(mult:Float):Float {
	return Conductor.crochet * mult;
}

function updateLocoShaders(elapsed:Float) {
	locoShaderTime += elapsed;

	setLocoShaderValue("Sunrays", "iTime", locoShaderTime);
	setLocoShaderValue("mirror", "iTime", locoShaderTime);

	var caX = Math.cos(locoShaderTime * locoOvalSpeed) * locoCARadiusX;
	var caY = Math.sin(locoShaderTime * locoOvalSpeed) * locoCARadiusY;
	setLocoShaderValue("ca", "strength", caX);
	setLocoShaderValue("ca", "strengthY", caY);
}

function runLocoCinematics() {
	switch (curStep) {
		case 1:
			tweenLocoShaderValue("greyscale", "strength", 0, crochetTime(0.004), FlxEase.cubeOut);
		case 24 | 56 | 88:
			tweenLocoShaderValue("greyscale", "strength", 1, crochetTime(0.004), FlxEase.cubeIn);
			tweenLocoBlur(3, crochetTime(0.004));
		case 32 | 64 | 96:
			tweenLocoShaderValue("greyscale", "strength", 0, crochetTime(0.002), FlxEase.cubeOut);
			tweenLocoBlur(0, crochetTime(0.002));
		case 120:
			tweenLocoShaderValue("vidrio", "strength", 6, crochetTime(0.0035), FlxEase.expoIn);
		case 128:
			setLocoShaderValue("vidrio", "strength", 0);
			setLocoShaderValue("bars", "effect", 0.55);
			tweenLocoShaderValue("bars", "effect", 0.05, crochetTime(0.008), FlxEase.cubeOut);
	}
}

function tweenLocoBlur(value:Float, dur:Float) {
	var dir = curStep % 3;
	setLocoShaderValue("blur", "dirX", dir == 0 ? 1 : -1);
	setLocoShaderValue("blur", "dirY", dir == 1 ? 1 : 0);
	setLocoShaderValue("blur", "posX", dir == 0 ? -3 : 3);
	setLocoShaderValue("blur", "posY", dir == 1 ? 3 : 0);
	tweenLocoShaderValue("blur", "strength", value, dur, value <= 0 ? FlxEase.cubeOut : FlxEase.cubeIn);
	tweenLocoShaderValue("blur", "focusPower", value, dur, value <= 0 ? FlxEase.cubeOut : FlxEase.cubeIn);
}

function setLocoShaderValue(name:String, field:String, value:Dynamic) {
	var shader = locoShaders.get(name);
	if (shader == null) return;
	try {
		Reflect.setField(shader, field, value);
	} catch (e:Dynamic) {}
}

function tweenLocoShaderValue(name:String, field:String, value:Float, dur:Float, ease:Dynamic) {
	var shader = locoShaders.get(name);
	if (shader == null) return;

	var start:Float = 0;
	var current = null;
	try {
		current = Reflect.field(shader, field);
	} catch (e:Dynamic) {}
	if (current != null) start = Std.parseFloat(Std.string(current));
	if (Math.isNaN(start)) start = 0;

	FlxTween.num(start, value, dur, {ease: ease}, function(v:Float) {
		try {
			Reflect.setField(shader, field, v);
		} catch (e:Dynamic) {}
	});
}

function moveLocoImages(dx:Float, dy:Float, dur:Float, ?setAlpha:Float) {
	for (spr in locoImages) {
		if (spr == null) continue;
		var props:Dynamic = {};
		if (dx != 0) props.x = spr.x + dx;
		if (dy != 0) props.y = spr.y + dy;
		if (setAlpha != null) props.alpha = setAlpha;
		FlxTween.tween(spr, props, dur, {ease: FlxEase.cubeInOut});
	}
}

function resetLocoIntro() {
	locoFloatEnabled = false;
	locoFloatTime = 0;

	for (spr in locoImages) {
		if (spr == null) continue;
		FlxTween.cancelTweensOf(spr);
		spr.offset.set(0, 0);
	}

	if (locoCam != null) {
		FlxTween.cancelTweensOf(locoCam);
		locoCam.zoom = locoEndZoom;
	}
}

function clearLocoIntro() {
	for (spr in locoImages) {
		if (spr == null) continue;
		remove(spr, true);
		spr.destroy();
	}
	locoImages = [];

	if (locoBg != null) {
		FlxTween.cancelTweensOf(locoBg);
		remove(locoBg, true);
		locoBg.destroy();
		locoBg = null;
	}
}

function removeLocoCamera() {
	if (locoCam == null) return;

	try {
		if (FlxG.cameras.list.contains(locoCam))
			FlxG.cameras.remove(locoCam, true);
	} catch (e:Dynamic) {}

	locoCam = null;
	locoShaders.clear();
	locoShadersReady = false;
}

function getLyric(tag:String):FlxText {
	return lyricTexts.get(tag);
}

function setLyricText(tag:String, content:String, x:Float, y:Float, ?z:Float = 0) {
	var txt = getLyric(tag);
	if (txt == null) return;
	if (content != null) txt.text = content;
	txt.x = x;
	txt.y = y;
	txt.alpha = 1;
	lyricPositions.set(tag, {x: x, y: y, z: z});
}

function setLyricColor(tag:String, color:FlxColor) {
	var txt = getLyric(tag);
	if (txt != null) txt.color = color;
}

function tweenLyric(tag:String, props:Dynamic, time:Float, ease:Dynamic) {
	var txt = getLyric(tag);
	if (txt != null) FlxTween.tween(txt, props, time, {ease: ease});
}

function moveLyric(tag:String, content:String, x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, time:Float, ease:Dynamic, ?fromColor:FlxColor, ?toColor:FlxColor) {
	setLyricText(tag, content, x0, y0, z0);
	var txt = getLyric(tag);
	if (txt == null) return;
	if (fromColor != null) {
		txt.color = fromColor;
		FlxTween.color(txt, time, fromColor, toColor == null ? FlxColor.WHITE : toColor, {ease: ease});
	}
	FlxTween.tween(txt, {x: x1, y: y1}, time, {ease: ease});
}

function returnLyricY(tag:String, time:Float, ease:Dynamic) {
	var p = lyricPositions.get(tag);
	if (p != null) tweenLyric(tag, {y: p.y}, time, ease);
}

function hideLyric(tag:String, time:Float, ease:Dynamic, ?move:Bool = false, ?z:Float = 0, ?x:Float = 0) {
	var props:Dynamic = {alpha: 0};
	if (move && x != null) props.x = x;
	tweenLyric(tag, props, time, ease);
}

function makeLyricCopy(tag:String, xOff:Float, yOff:Float, xTo:Float) {
	var src = getLyric(tag);
	if (src == null) return;
	var copy = new FlxText(src.x + xOff, src.y + yOff, 0, src.text, Std.int(src.size));
	copy.setFormat(Paths.font("Contb___.ttf"), Std.int(src.size), src.color, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	copy.borderSize = src.borderSize;
	copy.borderQuality = src.borderQuality;
	copy.angle = src.angle;
	copy.alpha = 0.75;
	copy.antialiasing = true;
	copy.cameras = [locoCam];
	add(copy);
	lyricCopies.push(copy);
	FlxTween.tween(copy, {x: xTo, alpha: 0}, crochetTime(0.0035), {ease: FlxEase.cubeOut, onComplete: function(_) {
		remove(copy, true);
		copy.destroy();
	}});
}

function createLyricCopies(tag:String) {
	var src = getLyric(tag);
	if (src == null) return;
	makeLyricCopy(tag, -20, -40, src.x + 50);
	makeLyricCopy(tag, 20, 40, src.x - 50);
}

function prepareSideLyrics(xBase:Float, angleBase:Float, custom:Array<String>) {
	var data = [
		["2", custom != null ? custom[0] : "TU", 200],
		["3", custom != null ? custom[1] : "TA", 350],
		["5", custom != null ? custom[2] : "NO", 500]
	];

	for (d in data) {
		var txt = getLyric(d[0]);
		if (txt == null) continue;
		setLyricText(d[0], d[1], xBase, d[2]);
		txt.angle = angleBase;
		txt.alpha = 0;
	}
}

function resetLyricTags(tags:Array<String>) {
	for (tag in tags) {
		var txt = getLyric(tag);
		if (txt == null) continue;
		txt.color = FlxColor.WHITE;
		txt.angle = 0;
		txt.x = 0;
		txt.y = -200;
		txt.alpha = 1;
	}
}

function destroyAllLyricCopies() {
	for (copy in lyricCopies) {
		if (copy == null) continue;
		FlxTween.cancelTweensOf(copy);
		remove(copy, true);
		copy.destroy();
	}
	lyricCopies = [];
}

function runLocoLyrics(s:Int, leftSide:Bool) {
	if (curStep == s) resetLyricTags(["1", "4"]);
	if (curStep == s + 4) {
		resetLyricTags(["2", "3", "5"]);
		moveLyric("1", "HOJE", 300, 750, -500, 370, 620, 0, crochetTime(0.001), FlxEase.cubeOut, FlxColor.GREEN, FlxColor.WHITE);
	} else if (curStep == s + 6) {
		moveLyric("2", "TU", 520, 750, -500, 590, 620, 0, crochetTime(0.001), FlxEase.cubeOut, FlxColor.GREEN, FlxColor.WHITE);
		returnLyricY("1", crochetTime(0.0015), FlxEase.expoIn);
	} else if (curStep == s + 8) {
		moveLyric("3", "SENTA", 650, 750, -500, 720, 620, 0, crochetTime(0.0015), FlxEase.cubeOut, FlxColor.GREEN, FlxColor.WHITE);
		returnLyricY("2", crochetTime(0.0015), FlxEase.expoIn);
	} else if (curStep == s + 11) {
		returnLyricY("3", crochetTime(0.0015), FlxEase.expoIn);
	} else if (curStep == s + 12) {
		moveLyric("4", "MULHER", 450, 750, -500, 500, 620, 0, crochetTime(0.0015), FlxEase.cubeOut);
	} else if (curStep == s + 15) {
		returnLyricY("4", crochetTime(0.001), FlxEase.expoIn);
	} else if (curStep == s + 16) {
		hideLyric("4", crochetTime(0.001), FlxEase.cubeOut);
	} else if (curStep == s + 20) {
		moveLyric("1", "QUE HOJE", 400, 750, -500, 450, 620, 0, crochetTime(0.001), FlxEase.cubeOut);
	} else if (curStep == s + 22) {
		returnLyricY("1", crochetTime(0.0015), FlxEase.expoIn);
	} else if (curStep == s + 24) {
		if (leftSide) {
			prepareSideLyrics(-50, 25, null);
			tweenLyric("2", {x: 50, alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		} else {
			prepareSideLyrics(1200, 25, ["TU", "TA", "NO"]);
			tweenLyric("2", {x: 1000, alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		}
		createLyricCopies("2");
	} else if (curStep == s + 25) {
		tweenLyric("3", {x: leftSide ? 50 : 1000, alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		createLyricCopies("3");
	} else if (curStep == s + 27) {
		tweenLyric("5", {x: leftSide ? 50 : 1000, alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		createLyricCopies("5");
	} else if (curStep == s + 28) {
		moveLyric("1", "BAILAO", leftSide ? 0 : 1100, 350, 0, leftSide ? 300 : 700, leftSide ? 350 : 300, 0, crochetTime(0.004), FlxEase.cubeOut);
		hideLyric("2", crochetTime(0.002), FlxEase.cubeIn, true, -350, leftSide ? -50 : 1200);
	} else if (curStep == s + 29) {
		hideLyric("3", crochetTime(0.002), FlxEase.cubeIn, true, -350, leftSide ? -50 : 1200);
	} else if (curStep == s + 30) {
		hideLyric("1", crochetTime(0.002), FlxEase.cubeIn, true, -350, 500);
		hideLyric("5", crochetTime(0.002), FlxEase.cubeIn, true, -350, leftSide ? -50 : 1200);
	} else if (curStep == s + 32) {
		destroyAllLyricCopies();
	} else if (curStep == s + 36) {
		var txt2 = getLyric("2");
		if (txt2 != null) {
			txt2.alpha = 1;
			txt2.angle = 0;
		}
		moveLyric("2", "OUTRO", 350, 150, -500, 320, 100, -100, crochetTime(0.001), FlxEase.cubeOut);
	} else if (curStep == s + 40) {
		var txt3 = getLyric("3");
		if (txt3 != null) {
			txt3.alpha = 1;
			txt3.angle = 0;
		}
		moveLyric("3", "MUNDO", 700, 150, -500, 680, 100, -100, crochetTime(0.001), FlxEase.cubeOut);
	} else if (curStep == s + 42) {
		var txt4 = getLyric("4");
		if (txt4 != null) {
			txt4.alpha = 1;
			txt4.angle = 0;
		}
		moveLyric("4", "NA", 500, 850, -500, 500, 500, -500, crochetTime(0.002), FlxEase.cubeOut);
	} else if (curStep == s + 44) {
		var txt1 = getLyric("1");
		if (txt1 != null) {
			txt1.alpha = 1;
			txt1.angle = 0;
		}
		hideLyric("2", crochetTime(0.002), FlxEase.cubeIn);
		hideLyric("3", crochetTime(0.002), FlxEase.cubeIn);
		hideLyric("4", crochetTime(0.001), FlxEase.cubeIn);
		moveLyric("1", "RAJADA", 350, 850, -400, 350, 500, -400, crochetTime(0.002), FlxEase.cubeOut);
	} else if (curStep == s + 48) {
		hideLyric("1", crochetTime(0.002), FlxEase.cubeIn, true, 0, 500);
	}

	if (leftSide) runExtraLocoLyrics(s);
}

function runExtraLocoLyrics(s:Int) {
	if (curStep == s + 52) {
		moveLyric("5", "DEIXA", 400, 750, -300, 400, 300, -300, crochetTime(0.002), FlxEase.cubeOut);
	} else if (curStep == s + 53) {
		var txt2 = getLyric("2");
		if (txt2 != null) txt2.angle = -25;
		moveLyric("2", "O", 800, 750, -300, 800, 300, -300, crochetTime(0.002), FlxEase.cubeOut);
		tweenLyric("2", {angle: 0}, crochetTime(0.002), FlxEase.cubeOut);
	} else if (curStep == s + 54) {
		moveLyric("1", "RABAO", 300, 750, -500, 300, 500, -500, crochetTime(0.002), FlxEase.cubeOut);
	} else if (curStep == s + 55) {
		hideLyric("5", crochetTime(0.0015), FlxEase.cubeIn);
		hideLyric("2", crochetTime(0.0015), FlxEase.cubeIn);
	} else if (curStep == s + 56) {
		hideLyric("1", crochetTime(0.002), FlxEase.cubeOut);
	} else if (curStep == s + 58) {
		prepareSideLyrics(1000, 25, ["TODO", "NO", "CHAO"]);
		tweenLyric("2", {x: 850, alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		createLyricCopies("2");
		for (tag in ["2", "3", "5"]) setLyricColor(tag, FlxColor.RED);
	} else if (curStep == s + 61) {
		tweenLyric("3", {x: 950, alpha: 1}, crochetTime(0.001), FlxEase.cubeOut);
		createLyricCopies("3");
	} else if (curStep == s + 63) {
		hideLyric("3", crochetTime(0.002), FlxEase.cubeIn);
		hideLyric("2", crochetTime(0.002), FlxEase.cubeIn);
	} else if (curStep == s + 64) {
		tweenLyric("5", {x: 850, alpha: 1}, crochetTime(0.001), FlxEase.cubeOut);
		createLyricCopies("5");
	} else if (curStep == s + 66) {
		hideLyric("5", crochetTime(0.002), FlxEase.cubeIn);
	} else if (curStep == s + 70) {
		destroyAllLyricCopies();
	}
}

function destroy() {
	clearLocoIntro();
	destroyAllLyricCopies();
	for (txt in lyricTexts) {
		if (txt == null) continue;
		remove(txt, true);
		txt.destroy();
	}
	lyricTexts.clear();
	lyricPositions.clear();
	removeLocoCamera();
}
