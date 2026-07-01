import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;

var camFD:FlxCamera;

var locoImages:Array<FlxSprite> = [];
var locoImageByName:Map<String, FlxSprite> = [];
var locoBg:FlxSprite = null;

var locoFloatTime:Float = 0;
var locoFloatEnabled:Bool = true;

var locoStartZoom:Float = 1;
var locoFloatBaseZoom:Float = 0.95;
var locoEndZoom:Float = 0.6;

var scene1DropStarted:Bool = false;

var lyricTexts:Map<String, FlxText> = [];
var lyricPositions:Map<String, Dynamic> = [];
var lyricCopies:Array<FlxText> = [];
var lyricCopyPool:Array<FlxText> = [];
var lyricCopyPoolIndex:Int = 0;
var lyricCopyPoolSize:Int = 24;

var sideLyricEdgeAmount:Float = 0.35;
var sideLyricOffscreenPad:Float = 140;

function getTextApproxWidth(txt:FlxText):Float {
	if (txt == null) return 120;

	var w = txt.width;

	// Por si FlxText todavía no actualizó bien el width.
	if (w <= 0)
		w = txt.text.length * txt.size * 0.6;

	return w;
}

function getSideLyricX(tag:String, leftSide:Bool, visible:Bool):Float {
	var txt = getLyric(tag);
	var w = getTextApproxWidth(txt);

	if (leftSide) {
		// Visible: un poco salido del borde izquierdo.
		// Oculto: completamente fuera.
		return visible ? -w * sideLyricEdgeAmount : -w - sideLyricOffscreenPad;
	} else {
		// Visible: pegado/saliendo del borde derecho.
		// Oculto: completamente fuera.
		return visible ? FlxG.width - (w * (1 - sideLyricEdgeAmount)) : FlxG.width + sideLyricOffscreenPad;
	}
}




function postCreate() {
	camHUD.alpha = 0;

	createCamFD();

	createLocoIntro();
	createLocoLyrics();
	createLyricCopyPool();
}

function createCamFD() {
	camFD = new FlxCamera();
	camFD.bgColor = 0x00000000;
	camFD.zoom = locoStartZoom;
	camFD.alpha = 1;

	FlxG.cameras.add(camFD, false);
}

function createLocoIntro() {
	if (camFD != null)
		camFD.zoom = locoStartZoom;

	locoBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	locoBg.scale.set(1.5, 1.5);
	locoBg.updateHitbox();
	locoBg.scrollFactor.set(0, 0);
	locoBg.screenCenter();
	locoBg.cameras = [camFD];
	insert(0, locoBg);

	for (name in ["mark", "scene1", "scene2", "scene3", "scene4", "scene5"]) {
		var spr = new FlxSprite().loadGraphic(Paths.image("songs img/Final Destination VIP/" + name));

		spr.scrollFactor.set(0, 0);
		spr.screenCenter();
		spr.x += 620;
		spr.y -= 320;

		// scene1 es la imagen que baja al inicio.
		// scene5 sigue empezando invisible como en el original.
		if (name == "scene1") {
			spr.alpha = 0;
			spr.y -= 150;
		} else {
			spr.alpha = name == "scene5" ? 0 : 1;
		}

		spr.cameras = [camFD];

		insert(members.indexOf(locoBg) + 1 + locoImages.length, spr);

		locoImages.push(spr);
		locoImageByName.set(name, spr);
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
		txt.cameras = [camHUD];
		add(txt);
		lyricTexts.set(id, txt);
	}
}

function createLyricCopyPool() {
	for (i in 0...lyricCopyPoolSize) {
		var copy = new FlxText(0, -200, 0, "", 85);
		copy.setFormat(Paths.font("Contb___.ttf"), 85, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		copy.borderSize = 4;
		copy.borderQuality = 3;
		copy.antialiasing = true;
		copy.alpha = 0;
		copy.visible = false;
		copy.active = false;
		copy.cameras = [camFD];
		add(copy);
		lyricCopyPool.push(copy);
	}
}

function startSong() {
	playScene1Drop();
}

// Por si tu build de CNE usa este callback.
function onSongStart() {
	playScene1Drop();
}

function playScene1Drop() {
	if (scene1DropStarted) return;
	scene1DropStarted = true;

	var spr = locoImageByName.get("scene1");
	if (spr == null) return;

	FlxTween.cancelTweensOf(spr);

	// Original 300 BPM: crochet * 0.008
	// Ahora 150 BPM: mitad para mantener la misma duración real.
	var dur = Conductor.crochet * 0.004;

	FlxTween.tween(
		spr,
		{y: spr.y + 150, alpha: 1},
		dur,
		{ease: FlxEase.cubeOut}
	);
}

function update(elapsed:Float) {
	if (!locoFloatEnabled) return;

	locoFloatTime += elapsed;

	var t = locoFloatTime * 1.25;
	var zoomT = locoFloatTime;
	var floatX = Math.sin(t) * 40;
	var floatY = Math.sin(t) * Math.cos(t) * 40;

	for (spr in locoImages) {
		if (spr != null)
			spr.offset.set(-floatX, -floatY);
	}

	if (camFD != null)
		camFD.zoom = locoFloatBaseZoom + Math.sin(zoomT) * 0.075;
}

function stepHit() {
	// Seguridad por si startSong/onSongStart no se ejecuta en esta versión.
	if (curStep == 1)
		playScene1Drop();

	switch (curStep) {
		// Original 300 BPM:
		// 54, 120, 184, 208, 256
		// Convertido a 150 BPM:
		// 27, 60, 92, 104, 128

		case 27:
			moveLocoImages(-1300, 0, crochetTime(0.002));

		case 60:
			moveLocoImages(0, 700, crochetTime(0.002));

		case 92:
			moveLocoImages(1300, 0, crochetTime(0.002));

		case 104:
			moveLocoImages(-620, -500, crochetTime(0.0015), 1);

		case 128:
			resetLocoIntro();
			clearLocoIntro();

			if (camFD != null)
				camFD.flash(FlxColor.WHITE, 1);

			camHUD.alpha = 1;
	}

	runLocoLyrics(1568, true);
	runLocoLyrics(1632, false);
}

function crochetTime(mult:Float):Float {
	return Conductor.crochet * mult;
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

	if (camFD != null) {
		FlxTween.cancelTweensOf(camFD);
		camFD.zoom = locoEndZoom;
	}
}

function clearLocoIntro() {
	for (spr in locoImages) {
		if (spr == null) continue;

		FlxTween.cancelTweensOf(spr);
		remove(spr, true);
		spr.destroy();
	}

	locoImages = [];
	locoImageByName = [];

	if (locoBg != null) {
		FlxTween.cancelTweensOf(locoBg);
		remove(locoBg, true);
		locoBg.destroy();
		locoBg = null;
	}
}

function getLyric(tag:String):FlxText {
	return lyricTexts.get(tag);
}

function setLyricText(tag:String, content:String, x:Float, y:Float, ?z:Float = 0) {
	var txt = getLyric(tag);
	if (txt == null) return;

	if (content != null)
		txt.text = content;

	txt.x = x;
	txt.y = y;
	txt.alpha = 1;

	lyricPositions.set(tag, {x: x, y: y, z: z});
}

function setLyricColor(tag:String, color:FlxColor) {
	var txt = getLyric(tag);
	if (txt != null)
		txt.color = color;
}

function tweenLyric(tag:String, props:Dynamic, time:Float, ease:Dynamic) {
	var txt = getLyric(tag);
	if (txt != null)
		FlxTween.tween(txt, props, time, {ease: ease});
}

function moveLyric(
	tag:String,
	content:String,
	x0:Float,
	y0:Float,
	z0:Float,
	x1:Float,
	y1:Float,
	z1:Float,
	time:Float,
	ease:Dynamic,
	?fromColor:FlxColor,
	?toColor:FlxColor
) {
	setLyricText(tag, content, x0, y0, z0);

	var txt = getLyric(tag);
	if (txt == null) return;

	if (fromColor != null) {
		txt.color = fromColor;
		FlxTween.color(
			txt,
			time,
			fromColor,
			toColor == null ? FlxColor.WHITE : toColor,
			{ease: ease}
		);
	}

	FlxTween.tween(txt, {x: x1, y: y1}, time, {ease: ease});
}

function returnLyricY(tag:String, time:Float, ease:Dynamic) {
	var p = lyricPositions.get(tag);
	if (p != null)
		tweenLyric(tag, {y: p.y}, time, ease);
}

function hideLyric(tag:String, time:Float, ease:Dynamic, ?move:Bool = false, ?z:Float = 0, ?x:Float = 0) {
	var props:Dynamic = {alpha: 0};

	if (move && x != null)
		props.x = x;

	tweenLyric(tag, props, time, ease);
}

function makeLyricCopy(tag:String, xOff:Float, yOff:Float, xTo:Float) {
	var src = getLyric(tag);
	if (src == null) return;

	var copy = getLyricCopyFromPool();
	if (copy == null) return;

	FlxTween.cancelTweensOf(copy);
	copy.text = src.text;
	copy.size = Std.int(src.size);
	copy.borderSize = src.borderSize;
	copy.borderQuality = src.borderQuality;
	copy.color = src.color;
	copy.angle = src.angle;
	copy.alpha = 0.75;
	copy.visible = true;
	copy.active = true;
	copy.cameras = [camFD];
	copy.x = src.x + xOff;
	copy.y = src.y + yOff;
	copy.updateHitbox();
	lyricCopies.push(copy);

	FlxTween.tween(copy, {x: xTo, alpha: 0}, crochetTime(0.0035), {
		ease: FlxEase.cubeOut,
		onComplete: function(_) {
			releaseLyricCopy(copy);
		}
	});
}

function getLyricCopyFromPool():FlxText {
	if (lyricCopyPool.length <= 0) return null;

	for (i in 0...lyricCopyPool.length) {
		var index = (lyricCopyPoolIndex + i) % lyricCopyPool.length;
		var copy = lyricCopyPool[index];
		if (copy != null && !copy.visible) {
			lyricCopyPoolIndex = (index + 1) % lyricCopyPool.length;
			return copy;
		}
	}

	var copy = lyricCopyPool[lyricCopyPoolIndex];
	lyricCopyPoolIndex = (lyricCopyPoolIndex + 1) % lyricCopyPool.length;
	return copy;
}

function releaseLyricCopy(copy:FlxText) {
	if (copy == null) return;
	FlxTween.cancelTweensOf(copy);
	copy.alpha = 0;
	copy.visible = false;
	copy.active = false;
	lyricCopies.remove(copy);
}

function createLyricCopies(tag:String) {
	var src = getLyric(tag);
	if (src == null) return;

	makeLyricCopy(tag, -20, -40, src.x + 50);
	makeLyricCopy(tag, 20, 40, src.x - 50);
}

function prepareSideLyrics(leftSide:Bool, angleBase:Float, custom:Array<String>) {
	var data = [
		["2", custom != null ? custom[0] : "TU", 200],
		["3", custom != null ? custom[1] : "TA", 350],
		["5", custom != null ? custom[2] : "NO", 500]
	];

	for (d in data) {
		var tag = d[0];
		var txt = getLyric(tag);
		if (txt == null) continue;

		setLyricText(tag, d[1], 0, d[2]);
		txt.angle = angleBase;
		txt.alpha = 0;

		// Ahora empieza realmente fuera del borde correspondiente.
		txt.x = getSideLyricX(tag, leftSide, false);
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
	var copies = lyricCopies.copy();
	for (copy in copies) {
		if (copy == null) continue;

		releaseLyricCopy(copy);
	}

	lyricCopies = [];
}

function runLocoLyrics(s:Int, leftSide:Bool) {
	if (curStep == s)
		resetLyricTags(["1", "4"]);

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
			prepareSideLyrics(true, 25, null);
			tweenLyric("2", {x: getSideLyricX("2", true, true), alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		} else {
			prepareSideLyrics(false, 25, ["TU", "TA", "NO"]);
			tweenLyric("2", {x: getSideLyricX("2", false, true), alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		}

		createLyricCopies("2");

	} else if (curStep == s + 25) {
		tweenLyric("3", {x: getSideLyricX("3", leftSide, true), alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		createLyricCopies("3");

	} else if (curStep == s + 27) {
		tweenLyric("5", {x: getSideLyricX("5", leftSide, true), alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		createLyricCopies("5");

	} else if (curStep == s + 28) {
		moveLyric(
			"1",
			"BAILAO",
			leftSide ? 0 : 1100,
			350,
			0,
			leftSide ? 300 : 700,
			leftSide ? 350 : 300,
			0,
			crochetTime(0.004),
			FlxEase.cubeOut
		);

		hideLyric("2", crochetTime(0.002), FlxEase.cubeIn, true, -350, getSideLyricX("2", leftSide, false));

	} else if (curStep == s + 29) {
		hideLyric("3", crochetTime(0.002), FlxEase.cubeIn, true, -350, getSideLyricX("3", leftSide, false));

	} else if (curStep == s + 30) {
		hideLyric("1", crochetTime(0.002), FlxEase.cubeIn, true, -350, 500);
		hideLyric("5", crochetTime(0.002), FlxEase.cubeIn, true, -350, getSideLyricX("5", leftSide, false));

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

	if (leftSide)
		runExtraLocoLyrics(s);
}

function runExtraLocoLyrics(s:Int) {
	if (curStep == s + 52) {
		moveLyric("5", "DEIXA", 400, 750, -300, 400, 300, -300, crochetTime(0.002), FlxEase.cubeOut);

	} else if (curStep == s + 53) {
		var txt2 = getLyric("2");
		if (txt2 != null)
			txt2.angle = -25;

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
		prepareSideLyrics(false, 25, ["TODO", "NO", "CHAO"]);
		tweenLyric("2", {x: getSideLyricX("2", false, true), alpha: 1}, crochetTime(0.002), FlxEase.cubeOut);
		createLyricCopies("2");

		for (tag in ["2", "3", "5"])
			setLyricColor(tag, FlxColor.RED);

	} else if (curStep == s + 61) {
		tweenLyric("3", {x: getSideLyricX("3", false, true), alpha: 1}, crochetTime(0.001), FlxEase.cubeOut);
		createLyricCopies("3");

	} else if (curStep == s + 63) {
		hideLyric("3", crochetTime(0.002), FlxEase.cubeIn);
		hideLyric("2", crochetTime(0.002), FlxEase.cubeIn);

	} else if (curStep == s + 64) {
		tweenLyric("5", {x: getSideLyricX("5", false, true), alpha: 1}, crochetTime(0.001), FlxEase.cubeOut);
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
	for (copy in lyricCopyPool) {
		if (copy == null) continue;
		FlxTween.cancelTweensOf(copy);
		remove(copy, true);
		copy.destroy();
	}
	lyricCopyPool = [];

	if (camFD != null) {
		if (FlxG.cameras.list.contains(camFD))
			FlxG.cameras.remove(camFD, true);
		camFD = null;
	}
}
