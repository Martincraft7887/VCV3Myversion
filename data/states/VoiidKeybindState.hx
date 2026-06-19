import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxColor;
import funkin.backend.FunkinText;
import funkin.backend.scripting.ModState;
import Xml;

var keyGroups:Array<Dynamic> = [];
var curKeyCount:Int = 3;
var curBind:Int = 0;
var waitingIndex:Int = -1;
var playerTwo:Bool = false;

var receptors:Array<FlxSprite> = [];
var labels:Array<FunkinText> = [];
var selector:FlxSprite;
var title:FunkinText;
var subtitle:FunkinText;
var prompt:FunkinText;
var leftArrow:FunkinText;
var rightArrow:FunkinText;
var openedFromPause:Bool = false;

function create() {
	openedFromPause = data != null && Reflect.field(data, "fromPause") == true;
	if (!openedFromPause)
		CoolUtil.playMenuSong();
	FlxG.mouse.visible = true;
	importScript("data/scripts/controlsCheck.hx");
	loadKeyData();

	var bg = new FlxSprite().loadGraphic(Paths.image("menus/freeplay/BG"));
	bg.setGraphicSize(FlxG.width);
	bg.updateHitbox();
	bg.screenCenter();
	bg.color = 0xFFEA71FD;
	bg.alpha = 0.82;
	bg.antialiasing = Options.antialiasing;
	add(bg);

	add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x8A321742));
	for (name in ["DOT_UP", "DOT_DOWN", "BLACK_STAINS"]) {
		var overlay = new FlxSprite().loadGraphic(Paths.image("main menu/new/" + name));
		overlay.setGraphicSize(FlxG.width);
		overlay.updateHitbox();
		overlay.screenCenter();
		overlay.alpha = name == "BLACK_STAINS" ? 0.72 : 0.55;
		overlay.antialiasing = Options.antialiasing;
		add(overlay);
	}

	var topBar = new FlxSprite(0, 31).makeGraphic(FlxG.width, 108, 0x88000000);
	add(topBar);

	title = makeText(0, 43, FlxG.width, "CONTROLS", 72);
	title.alignment = "center";
	add(title);

	leftArrow = makeText(122, 208, 80, "<", 72);
	rightArrow = makeText(FlxG.width - 202, 208, 80, ">", 72);
	leftArrow.alignment = "center";
	rightArrow.alignment = "center";
	add(leftArrow);
	add(rightArrow);

	subtitle = makeText(0, 220, FlxG.width, "", 48);
	subtitle.alignment = "center";
	add(subtitle);

	selector = new FlxSprite().makeGraphic(106, 106, 0x00FFFFFF);
	selector.alpha = 0;
	add(selector);

	prompt = makeText(0, FlxG.height - 88, FlxG.width, "", 23);
	prompt.alignment = "center";
	add(prompt);

	var help = new FunkinText(0, FlxG.height - 35, FlxG.width, "click/up/down receptor  |  enter + key  |  left/right keycount  |  P toggles P1/P2  |  R reset  |  ESC back", 18, true);
	help.alignment = "center";
	help.font = Paths.font("Contb___.ttf");
	help.alpha = 0.82;
	add(help);

	buildReceptors();
}

function makeText(x:Float, y:Float, width:Float, text:String, size:Int):FunkinText {
	var t = new FunkinText(x, y, width, text, size, true);
	t.font = Paths.font("Contb___.ttf");
	t.borderStyle = FlxTextBorderStyle.OUTLINE;
	t.borderColor = FlxColor.BLACK;
	t.borderSize = 5;
	return t;
}

function loadKeyData() {
	keyGroups = [];
	var xmlPath = Paths.xml("multikeyData");
	if (!Assets.exists(xmlPath)) {
		prompt = makeText(0, FlxG.height * 0.5, FlxG.width, "multikeyData.xml missing", 24);
		add(prompt);
		return;
	}

	var mainXML = Xml.parse(Assets.getText(xmlPath));
	var binds:Array<Dynamic> = [];
	var notes:Array<Dynamic> = [];

	for (keyData in mainXML.elementsNamed("defaultBinds")) {
		for (keyGroup in keyData.elementsNamed("keyGroup")) {
			var group:Array<Dynamic> = [];
			for (key in keyGroup.elementsNamed("key"))
				group.push({name: key.get("name"), bind: key.get("bind"), bindP2: key.get("bindP2")});
			binds.push({name: keyGroup.get("name"), keys: group});
		}
	}

	for (keyData in mainXML.elementsNamed("keyData")) {
		for (keyGroup in keyData.elementsNamed("keyGroup")) {
			var group:Array<Dynamic> = [];
			for (key in keyGroup.elementsNamed("key"))
				group.push({note: key.get("note"), strum: key.get("strumStatic")});
			notes.push({
				scale: Std.parseFloat(keyGroup.get("scale")),
				gapWidth: Std.parseFloat(keyGroup.get("gapWidth")),
				xOffset: Std.parseFloat(keyGroup.get("xOffset")),
				keys: group
			});
		}
	}

	var groupCount = Std.int(Math.min(binds.length, notes.length));
	for (i in 0...groupCount) {
		var keys:Array<Dynamic> = [];
		for (k in 0...binds[i].keys.length) {
			var savePath = (i + 1) + "k" + k;
			keys.push({
				name: binds[i].keys[k].name,
				note: notes[i].keys[k].note,
				strum: notes[i].keys[k].strum,
				savePath: savePath
			});
			if (Reflect.getProperty(FlxG.save.data, savePath) == null) {
				var bind = binds[i].keys[k].bind;
				Reflect.setProperty(FlxG.save.data, savePath, bind != "" ? FlxKey.fromString(bind) : 0);
			}
			if (Reflect.getProperty(FlxG.save.data, savePath + "p2") == null) {
				var bindP2 = binds[i].keys[k].bindP2;
				Reflect.setProperty(FlxG.save.data, savePath + "p2", bindP2 != "" ? FlxKey.fromString(bindP2) : 0);
			}
		}
		keyGroups.push({
			name: binds[i].name,
			scale: notes[i].scale,
			gapWidth: notes[i].gapWidth,
			xOffset: notes[i].xOffset,
			keys: keys
		});
	}
	FlxG.save.flush();
}

function update(elapsed:Float) {
	if (waitingIndex >= 0) {
		var key = FlxG.keys.firstJustPressed();
		if (key > 0) {
			if (key == FlxKey.ESCAPE && !FlxG.keys.pressed.SHIFT) {
				waitingIndex = -1;
				updatePrompt();
			} else {
				var savePath = getSavePath(waitingIndex);
				Reflect.setProperty(FlxG.save.data, savePath, key);
				FlxG.save.flush();
				waitingIndex = -1;
				CoolUtil.playMenuSFX(1, 0.7);
				buildReceptors();
			}
		}
		return;
	}

	if (controls.LEFT_P || FlxG.keys.justPressed.LEFT)
		changeKeyCount(-1);
	if (controls.RIGHT_P || FlxG.keys.justPressed.RIGHT)
		changeKeyCount(1);
	if (controls.UP_P || FlxG.keys.justPressed.UP)
		changeBind(-1);
	if (controls.DOWN_P || FlxG.keys.justPressed.DOWN)
		changeBind(1);
	if (controls.ACCEPT || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
		startRebind(curBind);
	if (FlxG.keys.justPressed.P) {
		playerTwo = !playerTwo;
		CoolUtil.playMenuSFX(0, 0.7);
		buildReceptors();
	}
	if (FlxG.keys.justPressed.R) {
		resetCurrentKeyCount();
		buildReceptors();
	}
	if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
	{
		if (openedFromPause) {
			try {
				close();
			} catch(e:Dynamic) {
				FlxG.switchState(new ModState("VoiidOptionsState"));
			}
		} else {
			FlxG.switchState(new ModState("VoiidOptionsState"));
		}
	}

	for (i in 0...receptors.length)
	{
		var spr = receptors[i];
		if (FlxG.mouse.overlaps(spr)) {
			if (curBind != i) {
				curBind = i;
				updatePrompt();
			}
			if (FlxG.mouse.justPressed)
				startRebind(i);
		}
		spr.alpha = i == curBind ? 1 : 0.62;
	}
}

function changeKeyCount(change:Int) {
	if (keyGroups.length <= 0) return;
	curKeyCount = FlxMath.wrap(curKeyCount + change, 0, keyGroups.length - 1);
	curBind = 0;
	CoolUtil.playMenuSFX(0, 0.7);
	buildReceptors();
}

function changeBind(change:Int) {
	if (receptors.length <= 0) return;
	curBind = FlxMath.wrap(curBind + change, 0, receptors.length - 1);
	CoolUtil.playMenuSFX(0, 0.7);
	updatePrompt();
}

function clearReceptors() {
	for (spr in receptors) {
		remove(spr, true);
		spr.destroy();
	}
	for (label in labels) {
		remove(label, true);
		label.destroy();
	}
	receptors = [];
	labels = [];
}

function buildReceptors() {
	clearReceptors();
	if (keyGroups.length <= 0) return;

	var group = keyGroups[curKeyCount];
	curBind = Std.int(FlxMath.bound(curBind, 0, group.keys.length - 1));
	subtitle.text = group.name + "  " + (playerTwo ? "P2" : "P1");

	var keys:Array<Dynamic> = group.keys;
	var gap = Math.max(72, group.gapWidth);
	var scale = Math.max(0.36, group.scale);
	var totalWidth = (keys.length - 1) * gap;
	var startX = (FlxG.width - totalWidth) * 0.5 + group.xOffset;
	var baseY = 360;

	for (i in 0...keys.length) {
		var spr = new FlxSprite();
		spr.frames = Paths.getFrames("game/voiid/notes/default");
		spr.antialiasing = Options.antialiasing;
		var animName = keys[i].strum;
		if (animName == null || animName == "")
			animName = keys[i].note + "0";
		spr.animation.addByPrefix("idle", animName, 24, true);
		spr.animation.play("idle");
		spr.setGraphicSize(Std.int(128 * scale / 0.7));
		spr.updateHitbox();
		spr.x = startX + i * gap - spr.width * 0.5;
		spr.y = baseY - spr.height * 0.5;
		spr.alpha = i == curBind ? 1 : 0.62;
		add(spr);
		receptors.push(spr);

		var label = makeText(spr.x - 45, spr.y + spr.height + 14, spr.width + 90, getBindText(i), 24);
		label.alignment = "center";
		add(label);
		labels.push(label);
	}

	updatePrompt();
}

function getSavePath(index:Int):String {
	var path = keyGroups[curKeyCount].keys[index].savePath;
	return playerTwo ? path + "p2" : path;
}

function getBindText(index:Int):String {
	var value = Reflect.getProperty(FlxG.save.data, getSavePath(index));
	var text = CoolUtil.keyToString(value);
	if (text == null || text == "") text = "---";
	return text;
}

function startRebind(index:Int) {
	waitingIndex = index;
	curBind = index;
	CoolUtil.playMenuSFX(1, 0.7);
	updatePrompt();
}

function updatePrompt() {
	if (waitingIndex >= 0) {
		var key = keyGroups[curKeyCount].keys[waitingIndex];
		prompt.text = "Press a key for " + key.name + " " + (playerTwo ? "P2" : "P1") + "  |  ESC cancels";
		return;
	}
	if (keyGroups.length > 0)
		prompt.text = "Receptor: " + keyGroups[curKeyCount].keys[curBind].name + "  |  ENTER to change";
	else
		prompt.text = "No se encontro multikeyData.xml";
}

function resetCurrentKeyCount() {
	var group = keyGroups[curKeyCount];
	for (i in 0...group.keys.length) {
		Reflect.setProperty(FlxG.save.data, group.keys[i].savePath, null);
		Reflect.setProperty(FlxG.save.data, group.keys[i].savePath + "p2", null);
	}
	loadKeyData();
	FlxG.save.flush();
	CoolUtil.playMenuSFX(2, 0.7);
}
