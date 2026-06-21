import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.game.PlayState;
import lime.utils.Assets;

var bg:FlxSprite;
var camResults:FlxCamera;
var ready:Bool = false;
var acceptReleased:Bool = false;
var activeAwardPopups:Int = 0;

function create() {
	var ps = PlayState.instance;
	camResults = new FlxCamera();
	camResults.bgColor = 0;
	camResults.zoom = 1;
	camResults.scroll.set();
	FlxG.cameras.add(camResults, false);
	keepResultsCameraOnTop();
	cameras = getHudCameras();

	bg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	bg.alpha = 0;
	bg.scrollFactor.set();
	bg.cameras = getHudCameras();
	add(bg);
	FlxTween.tween(bg, {alpha: 0.58}, 0.25, {ease: FlxEase.quartOut});

	var songName = "Unknown Song";
	var diffName = "";
	if (PlayState.SONG != null && PlayState.SONG.meta != null) {
		songName = Std.string(PlayState.SONG.meta.displayName);
		if (songName == "" || songName == "null")
			songName = Std.string(PlayState.SONG.meta.name);
	}
	try {
		diffName = Std.string(PlayState.difficulty).toUpperCase();
	} catch(e:Dynamic) {}

	addText(4, 2, FlxG.width - 8, songName + (diffName == "" ? "" : " - " + diffName) + " complete! (1x)", 34, "left");

	var misses = ps == null ? 0 : ps.misses;

	var stats = getRatingStatsText(misses);
	var ratings = addText(4, 272, 360, stats, 23, "left");

	createNoteGraph(FlxG.width - 548, 26);

	var bottom = addText(0, FlxG.height - 92, FlxG.width - 6, "Press ENTER to close this menu", 36, "right");
	bottom.alpha = 0.95;

	showPendingAwards();

	new FlxTimer().start(0.25, function(_) ready = true);
}

function getHudCameras():Array<Dynamic> {
	if (camResults != null)
		return [camResults];

	try {
		if (PlayState.instance != null && PlayState.instance.camHUD != null)
			return [PlayState.instance.camHUD];
	} catch(e:Dynamic) {}
	return [FlxG.camera];
}

function isolateResultsCamera() {
	if (camResults == null)
		return;

	try {
		camResults._filters = [];
	} catch(e:Dynamic) {}

	try {
		if (camResults.flashSprite != null)
			camResults.flashSprite.filters = [];
	} catch(e:Dynamic) {}
}

function keepResultsCameraOnTop() {
	if (camResults == null)
		return;

	isolateResultsCamera();

	try {
		var cameraList = FlxG.cameras.list;
		if (cameraList != null && cameraList.length > 0 && cameraList[cameraList.length - 1] != camResults) {
			if (cameraList.contains(camResults))
				FlxG.cameras.remove(camResults, false);
			FlxG.cameras.add(camResults, false);
		}
	} catch(e:Dynamic) {}
}

function destroy() {
	if (camResults != null) {
		if (FlxG.cameras.list.contains(camResults))
			FlxG.cameras.remove(camResults, true);
		camResults = null;
	}
}

function addText(x:Float, y:Float, width:Float, text:String, size:Int, align:String):FlxText {
	var t = new FlxText(x, y, width, text, size);
	t.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, align, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	t.borderSize = 2;
	t.scrollFactor.set();
	t.cameras = getHudCameras();
	add(t);
	return t;
}

function getRank(acc:Float, misses:Int):String {
	if (acc >= 1 && misses <= 0) return "S++";
	if (acc >= 0.98) return "S+";
	if (acc >= 0.95) return "S";
	if (acc >= 0.90) return "A";
	if (acc >= 0.85) return "B";
	if (acc >= 0.80) return "C";
	if (acc >= 0.70) return "D";
	return "E";
}

function getIntResult(field:String):Int {
	if (!resultStatsMatchSong())
		return 0;
	var value = Reflect.field(FlxG.save.data, field);
	if (value == null)
		return 0;
	return Std.int(value);
}

function getFloatResult(field:String):Float {
	if (!resultStatsMatchSong())
		return 0;
	var value = Reflect.field(FlxG.save.data, field);
	if (value == null)
		return 0;
	var parsed = Std.parseFloat(Std.string(value));
	return Math.isNaN(parsed) ? 0 : parsed;
}

function resultStatsMatchSong():Bool {
	var savedSong = Reflect.field(FlxG.save.data, "voiidResultSong");
	if (savedSong == null)
		return false;

	var currentSong = "";
	try {
		if (PlayState.SONG != null && PlayState.SONG.meta != null)
			currentSong = Std.string(PlayState.SONG.meta.name).toLowerCase();
	} catch(e:Dynamic) {}

	return currentSong != "" && Std.string(savedSong).toLowerCase() == currentSong;
}

function getRatingStatsText(misses:Int):String {
	var krazy = getIntResult("voiidResultKrazy");
	var sick = getIntResult("voiidResultSick");
	var good = getIntResult("voiidResultGood");
	var bad = getIntResult("voiidResultBad");
	var shit = getIntResult("voiidResultShit");

	var maDenom = sick + good + bad + shit;
	var paDenom = good + bad + shit;
	var ma = maDenom <= 0 ? 0 : Math.round((krazy / maDenom) * 100) / 100;
	var pa = paDenom <= 0 ? 0 : Math.round(((sick + krazy) / paDenom) * 100) / 100;

	return
		"Krazy: " + krazy + "\n" +
		"Sick: " + sick + "\n" +
		"Good: " + good + "\n" +
		"Guh: " + bad + "\n" +
		"Mid: " + shit + "\n" +
		"Combo Breaks: " + misses + "\n" +
		"MA: " + ma + "\n" +
		"PA: " + pa;
}

function createNoteGraph(startX:Float, startY:Float) {
	var graphW:Int = 500;
	var graphH:Int = 252;
	var centerY:Float = startY + graphH * 0.5;

	addText(startX + graphW - 66, startY - 22, 80, "-166ms", 18, "left");
	addText(startX + 2, startY + graphH + 2, 80, "166ms", 18, "left");

	for (lineY in [0, 84, 168, 252]) {
		var line = new FlxSprite(startX, startY + lineY).makeGraphic(graphW, 4, FlxColor.GRAY);
		line.alpha = 0.9;
		line.scrollFactor.set();
		line.cameras = getHudCameras();
		add(line);
	}

	var diffs:Array<Dynamic> = Reflect.field(FlxG.save.data, "voiidResultHitDiffs");
	if (!resultStatsMatchSong() || diffs == null || diffs.length <= 0)
		return;

	var denom = Math.max(1, diffs.length - 1);
	for (i in 0...diffs.length) {
		var diff = Std.parseFloat(Std.string(diffs[i]));
		if (Math.isNaN(diff))
			diff = 0;
		if (diff < -166) diff = -166;
		if (diff > 166) diff = 166;

		var dotX = startX + (graphW * (i / denom));
		var dotY = centerY + ((diff / 166) * (graphH * 0.5));
		var dot = new FlxSprite(dotX, dotY).makeGraphic(7, 6, 0xFF00FF00);
		dot.scrollFactor.set();
		dot.cameras = getHudCameras();
		add(dot);
	}
}

function showPendingAwards() {
	var pending:Array<Dynamic> = Reflect.field(FlxG.save.data, "voiidPendingAwards");
	var pendingGloves:Array<Dynamic> = Reflect.field(FlxG.save.data, "voiidPendingGloves");
	if ((pending == null || pending.length <= 0) && (pendingGloves == null || pendingGloves.length <= 0))
		return;

	if (pending == null) pending = [];

	Reflect.setField(FlxG.save.data, "voiidPendingAwards", []);
	Reflect.setField(FlxG.save.data, "voiidPendingGloves", []);
	FlxG.save.flush();

	if (pendingGloves != null && pendingGloves.length > 0) {
		new FlxTimer().start(0.12, function(_) {
			showGloveGainPopups(pendingGloves);
		});
	}

	var delay:Float = 0.15;
	for (award in pending) {
		var popupAward = award;
		new FlxTimer().start(delay, function(_) {
			showAwardPopup(popupAward);
		});
		delay += 0.7;
	}
}

function showGloveGainPopups(gloves:Array<Dynamic>) {
	if (gloves == null || gloves.length <= 0)
		return;

	var totalW:Float = gloves.length * 170;
	var startX:Float = (FlxG.width - totalW) * 0.5;
	for (i in 0...gloves.length) {
		createGloveGainPopup(gloves[i], startX + i * 170, 72);
	}
}

function createGloveGainPopup(glove:Dynamic, x:Float, targetY:Float) {
	var objects:Array<Dynamic> = [];
	var startY = -80;
	var iconPath = glove.imagePath == null ? "main menu/freeplay/glove_white" : Std.string(glove.imagePath);
	if (!Assets.exists(Paths.image(iconPath)))
		iconPath = "main menu/freeplay/glove_white";

	var icon = new FlxSprite(x, startY).loadGraphic(Paths.image(iconPath));
	icon.setGraphicSize(64, 64);
	icon.updateHitbox();
	icon.antialiasing = Options.antialiasing;
	icon.scrollFactor.set();
	icon.cameras = getHudCameras();
	add(icon);
	objects.push(icon);

	var amount = glove.amount == null ? Std.string(glove.desc) : "+" + Std.string(glove.amount);
	var text = addText(x + 68, startY + 8, 110, amount, 38, "left");
	text.font = Paths.font("vcr.ttf");
	text.borderSize = 3;
	objects.push(text);

	function sync() {
		text.y = icon.y + 8;
	}

	FlxTween.tween(icon, {y: targetY}, 0.35, {
		ease: FlxEase.quartOut,
		onUpdate: function(_) sync(),
		onComplete: function(_) {
			new FlxTimer().start(2.2, function(_) {
				FlxTween.tween(icon, {y: -80, alpha: 0}, 0.3, {
					ease: FlxEase.quadIn,
					onUpdate: function(_) {
						sync();
						text.alpha = icon.alpha;
					},
					onComplete: function(_) {
						for (obj in objects) {
							remove(obj);
							obj.destroy();
						}
					}
				});
			});
		}
	});
}

function showAwardPopup(award:Dynamic) {
	if (award == null)
		return;

	var w:Int = 400;
	var h:Int = 120;
	var targetY:Float = activeAwardPopups * h;
	var startY:Float = -h - 8;
	var x:Float = FlxG.width - w;
	var objects:Array<Dynamic> = [];
	activeAwardPopups++;

	var popup = new FlxSprite(x, startY).makeGraphic(w, h, 0xFF000000);
	popup.scrollFactor.set();
	popup.cameras = getHudCameras();
	add(popup);
	objects.push(popup);

	var title = addText(x + 5, startY + 5, w - 110, Std.string(award.name), 32, "left");
	title.font = Paths.font("Contb___.ttf");
	objects.push(title);

	var descText = award.desc == null || Std.string(award.desc) == "" ? "Award unlocked!" : Std.string(award.desc);
	var desc = addText(x + 5, startY + 45, w - 110, descText, 16, "left");
	desc.font = Paths.font("Contb___.ttf");
	objects.push(desc);

	var iconPath = award.imagePath == null ? "awards/" + Std.string(award.image) : Std.string(award.imagePath);
	if (!Assets.exists(Paths.image(iconPath)))
		iconPath = "awards/default";

	var icon = new FlxSprite(x + w - 105, startY + 10).loadGraphic(Paths.image(iconPath));
	icon.setGraphicSize(100, 100);
	icon.updateHitbox();
	icon.antialiasing = Options.antialiasing;
	icon.scrollFactor.set();
	icon.cameras = getHudCameras();
	add(icon);
	objects.push(icon);

	function sync() {
		title.y = popup.y + 5;
		desc.y = popup.y + 45;
		icon.y = popup.y + 10;
	}

	FlxTween.tween(popup, {y: targetY}, 0.45, {
		ease: FlxEase.quartOut,
		onUpdate: function(_) {
			sync();
		},
		onComplete: function(_) {
			new FlxTimer().start(4.8, function(_) {
				FlxTween.tween(popup, {y: startY}, 0.35, {
					ease: FlxEase.quadIn,
					onUpdate: function(_) {
						sync();
					},
					onComplete: function(_) {
						for (obj in objects) {
							remove(obj);
							obj.destroy();
						}
						activeAwardPopups = Math.max(0, activeAwardPopups - 1);
					}
				});
			});
		}
	});
}

function update(elapsed:Float) {
	keepResultsCameraOnTop();

	if (!ready)
		return;

	if (!acceptReleased) {
		if (!controls.ACCEPT && !FlxG.keys.pressed.ENTER && !FlxG.keys.pressed.SPACE)
			acceptReleased = true;
		return;
	}

	if (controls.ACCEPT || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) {
		ready = false;
		close();
		try {
			PlayState.instance.scripts.call("finishVoiidResults", []);
		} catch(e:Dynamic) {
			if (PlayState.instance != null)
				PlayState.instance.endSong();
		}
	}
}
