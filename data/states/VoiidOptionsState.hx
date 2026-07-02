import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.FunkinText;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.ModSubState;
import funkin.game.PlayState;
import funkin.options.Options;
import funkin.options.OptionsMenu;

var pages:Dynamic = {};
var pageStack:Array<String> = [];
var texts:Array<FunkinText> = [];
var checkboxes:Array<Dynamic> = [];
var curSelected:Int = 0;
var leftArrow:FunkinText;
var rightArrow:FunkinText;
var title:FunkinText;
var tabText:FunkinText;
var descText:FunkinText;
var previewNotes:Array<FlxSprite> = [];
var previewBars:Array<Dynamic> = [];
var exiting:Bool = false;
var openedFromPause:Bool = false;
var transitioning:Bool = false;

function create() {
	openedFromPause = Reflect.field(FlxG.save.data, "voiidOptionsOpenedFromPause") == true;
	if (!openedFromPause)
		CoolUtil.playMenuSong();
	FlxG.mouse.visible = true;
	createPages();
	createBackdrop();
	Paths.getFrames("main menu/new/checkbox");
	Paths.getFrames("game/voiid/notes/default");

	title = makeText(0, 43, FlxG.width, "CATEGORIES", 72);
	title.alignment = "center";
	add(title);

	tabText = makeText(0, 22, FlxG.width, "", 24);
	tabText.alignment = "center";
	tabText.alpha = 0.8;
	add(tabText);

	leftArrow = makeText(0, 0, 80, "<", 72);
	rightArrow = makeText(0, 0, 80, ">", 72);
	leftArrow.alignment = "center";
	rightArrow.alignment = "center";
	add(leftArrow);
	add(rightArrow);

	descText = makeText(0, FlxG.height - 38, FlxG.width, "ENTER accept  |  left/right change values  |  ESC back", 18);
	descText.alignment = "center";
	descText.alpha = 0.82;
	add(descText);

	loadPage("Categories", false);
}

function createBackdrop() {
	var bg = new FlxSprite().loadGraphic(Paths.image("menus/freeplay/BG"));
	bg.setGraphicSize(Std.int(FlxG.width * 1.1));
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
		overlay.alpha = name == "BLACK_STAINS" ? 0.72 : 0.58;
		overlay.antialiasing = Options.antialiasing;
		add(overlay);
	}

	var topBar = new FlxSprite(0, 31).makeGraphic(FlxG.width, 108, 0x88000000);
	add(topBar);
	var tabBG = new FlxSprite(FlxG.width * 0.5 - 380, 20).makeGraphic(760, 38, 0xAA000000);
	add(tabBG);
}

function makeText(x:Float, y:Float, width:Float, text:String, size:Int):FunkinText {
	var t = new FunkinText(x, y, width, text, size, true);
	t.font = Paths.font("Contb___.ttf");
	t.borderStyle = FlxTextBorderStyle.OUTLINE;
	t.borderColor = FlxColor.BLACK;
	t.borderSize = 5;
	return t;
}

function createPages() {
	pages = {};

	setPage("Categories", [
		pageOption("MOD  SETTINGS", "Mod Settings"),
		pageOption("GAMEPLAY", "Gameplay"),
		pageOption("HUD", "HUD"),
		pageOption("GRAPHICS", "Graphics"),
		pageOption("MISC", "Misc")
	]);

	setPage("Mod Settings", [
		boolOption("Botplay", "voiidBotplay", false, false),
		boolOption("No Mechanics", "voiidNoMechanics", false, false),
		boolOption("No Death", "voiidNoDeath", false, false),
		boolOption("Modcharts", "voiidModcharts", true, false),
		boolOption("Alt Note Type Textures", "voiidAltNoteTypeTextures", false, false),
		boolOption("Center Dodge Popup", "voiidPunchCenterScreen", false, false),
		boolOption("Dynamic Window/RPC", "voiidDynamicWindowRpc", true, false),
		boolOption("Discord RPC", "voiidDiscordRpc", true, false),
		boolOption("Debug Logs", "voiidDebugLogs", false, false)
	]);

	setPage("Gameplay", [
		actionOption("Binds", function() {
			if (openedFromPause)
				openSubState(new ModSubState("VoiidKeybindState", {fromPause: true}));
			else
				FlxG.switchState(new ModState("VoiidKeybindState"));
		}),
		boolOption("Downscroll", "downscroll", false, true),
		boolOption("Ghost Tapping", "ghostTapping", true, true),
		boolOption("Camera Bounce", "camZoomOnBeat", true, true),
		boolOption("Auto Pause", "autoPause", true, true),
		numberOption("Song Offset", "songOffset", 0, -999, 999, 1, true),
		numberOption("Music Volume", "volumeMusic", 1, 0, 1, 0.1, true),
		numberOption("SFX Volume", "volumeSFX", 1, 0, 1, 0.1, true),
		boolOption("Naughtyness", "naughtyness", true, true)
	]);

	setPage("HUD", [
		choiceOption("Time Bar Style", "voiidTimeBarStyle", ["leather engine", "psych engine", "new kade engine", "old kade engine"], "leather engine", false),
		choiceOption("Time Bar Position", "voiidTimeBarPosition", ["top", "bottom"], "top", false),
		boolOption("Timer Shows Botplay", "voiidTimerFlags", true, false),
		boolOption("Color Health Bar", "colorHealthBar", true, true),
		boolOption("Bigger Score Text", "voiidBiggerScoreText", false, false),
		boolOption("Bigger Info Text", "voiidBiggerInfoText", false, false),
		boolOption("Show Rating Popup", "voiidRatingPopup", true, false),
		boolOption("Show Combo Popup", "voiidComboPopup", true, false),
		boolOption("Show MS Text", "voiidDisplayMs", false, false),
		boolOption("Show Side Ratings", "voiidSideRatings", false, false),
		choiceOption("Rating Camera", "voiidRatingCamera", ["hud", "game", "other"], "hud", false, ["HUD", "GAME", "OTHER"]),
		boolOption("Show Break Timer", "voiidBreakTimer", false, false)
	]);

	setPage("Graphics", [
		numberOption("Max FPS", "framerate", 120, 30, 240, 1, true),
		boolOption("Flashing Lights", "flashingMenu", true, true),
		boolOption("Antialiasing", "antialiasing", true, true),
		boolOption("Gameplay Shaders", "gameplayShaders", true, true),
		boolOption("Low Memory Mode", "lowMemoryMode", false, true),
		boolOption("GPU Textures", "gpuOnlyBitmaps", true, true),
		choiceOption("Quality", "quality", [0, 1, 2], 1, true, ["LOW", "HIGH", "CUSTOM"])
	]);

	setPage("Misc", [
		boolOption("Dev Mode", "devMode", false, true),
		boolOption("Allow Config Warning", "allowConfigWarning", true, true),
		boolOption("FPS Counter", "fpsCounter", true, true),
		boolOption("Freeplay Music Auto Play", "voiidFreeplayMusic", true, false),
		boolOption("Disable Debug Menus", "voiidDisableDebugMenus", false, false),
		actionOption("Codename Options", function() {
			FlxG.switchState(new OptionsMenu());
		})
	]);
}

function setPage(name:String, items:Array<Dynamic>) {
	Reflect.setField(pages, name, items);
}

function getPage(name:String):Array<Dynamic> {
	var items = Reflect.field(pages, name);
	return items == null ? [] : cast items;
}

function pageOption(name:String, page:String):Dynamic {
	return {type: "page", name: name, page: page};
}

function actionOption(name:String, callback:Dynamic):Dynamic {
	return {type: "action", name: name, callback: callback};
}

function boolOption(name:String, field:String, def:Bool, engine:Bool):Dynamic {
	ensureValue(field, def, engine);
	return {type: "bool", name: name, field: field, def: def, engine: engine};
}

function numberOption(name:String, field:String, def:Float, min:Float, max:Float, step:Float, engine:Bool):Dynamic {
	ensureValue(field, def, engine);
	return {type: "number", name: name, field: field, def: def, min: min, max: max, step: step, engine: engine};
}

function choiceOption(name:String, field:String, values:Array<Dynamic>, def:Dynamic, engine:Bool, ?display:Array<String>):Dynamic {
	ensureValue(field, def, engine);
	return {type: "choice", name: name, field: field, values: values, display: display, def: def, engine: engine};
}

function ensureValue(field:String, def:Dynamic, engine:Bool) {
	if (engine) return;
	if (Reflect.field(FlxG.save.data, field) == null) {
		Reflect.setField(FlxG.save.data, field, def);
		FlxG.save.flush();
	}
}

function getValue(option:Dynamic):Dynamic {
	if (option.engine)
		return Reflect.field(Options, option.field);
	return Reflect.field(FlxG.save.data, option.field);
}

function setValue(option:Dynamic, value:Dynamic) {
	if (option.engine)
		Reflect.setField(Options, option.field, value);
	else
		Reflect.setField(FlxG.save.data, option.field, value);
	applyOption(option);
}

function applyOption(option:Dynamic) {
	if (option.engine) {
		Options.applySettings();
		Options.save();
	} else {
		FlxG.save.flush();
	}
	refreshAssistOptionsIfNeeded(option);
	if (option.field == "volumeMusic")
		FlxG.sound.defaultMusicGroup.volume = option.engine ? Options.volumeMusic : getValue(option);
}

function refreshAssistOptionsIfNeeded(option:Dynamic) {
	if (option == null || (option.field != "voiidBotplay" && option.field != "voiidNoDeath"))
		return;

	try {
		if (PlayState.instance != null)
			PlayState.instance.scripts.call("refreshVoiidAssistOptions", []);
	} catch(e:Dynamic) {}
}

function currentPage():String {
	return pageStack[pageStack.length - 1];
}

function loadPage(pageName:String, goingBack:Bool) {
	clearTexts();
	clearPreview();
	pageStack.push(pageName);
	curSelected = 0;
	title.text = pageName.toUpperCase();
	updateTabText();

	var items = getPage(pageName);
	for (i in 0...items.length) {
		var item = items[i];
		var text = makeText(item.type == "bool" ? 95 : 0, 0, item.type == "bool" ? FlxG.width - 190 : FlxG.width, getOptionLabel(item), 62);
		text.alignment = "center";
		text.x = goingBack ? -1500 : 1500;
		add(text);
		texts.push(text);
		if (item.type == "bool") {
			var box = new FlxSprite();
			box.frames = Paths.getFrames("main menu/new/checkbox");
			box.animation.addByPrefix("checked", "Checked", 24, false);
			box.animation.addByPrefix("unchecked", "Unchecked", 24, false);
			box.animation.play(getValue(item) == true ? "checked" : "unchecked");
			box.antialiasing = Options.antialiasing;
			box.setGraphicSize(118);
			box.updateHitbox();
			add(box);
			checkboxes.push(box);
		} else {
			checkboxes.push(null);
		}
	}
	updateVisuals(true);
	updatePreview();
}

function goBack() {
	if (pageStack.length <= 1) {
		exiting = true;
		CoolUtil.playMenuSFX(2, 0.7);
		if (openedFromPause) {
			Reflect.setField(FlxG.save.data, "voiidOptionsOpenedFromPause", false);
			FlxG.save.flush();
			returnToPausedSong();
			return;
		}
		FlxG.switchState(new ModState("VoiidMainMenuState"));
		return;
	}
	var old = pageStack.pop();
	var backTo = pageStack.pop();
	CoolUtil.playMenuSFX(2, 0.7);
	loadPage(backTo, true);
}

function clearTexts() {
	for (text in texts) {
		remove(text, true);
		text.destroy();
	}
	for (box in checkboxes) {
		if (box == null) continue;
		remove(box, true);
		box.destroy();
	}
	texts = [];
	checkboxes = [];
}

function returnToPausedSong() {
	var song = Reflect.field(FlxG.save.data, "voiidPauseSong");
	if (song == null || Std.string(song) == "") {
		FlxG.switchState(new ModState("VoiidMainMenuState"));
		return;
	}

	var diff = Reflect.field(FlxG.save.data, "voiidPauseDifficulty");
	if (diff == null || Std.string(diff) == "") diff = "normal";
	var variation = Reflect.field(FlxG.save.data, "voiidPauseVariation");
	if (variation != null && Std.string(variation) == "") variation = null;

	try {
		PlayState.isStoryMode = Reflect.field(FlxG.save.data, "voiidPauseStoryMode") == true;
		PlayState.opponentMode = Reflect.field(FlxG.save.data, "voiidPauseOpponentMode") == true;
		PlayState.coopMode = Reflect.field(FlxG.save.data, "voiidPauseCoopMode") == true;
		PlayState.chartingMode = Reflect.field(FlxG.save.data, "voiidPauseChartingMode") == true;
		PlayState.__loadSong(Std.string(song), Std.string(diff), variation == null ? null : Std.string(variation));
		FlxG.switchState(new PlayState());
	} catch(e:Dynamic) {
		FlxG.switchState(new ModState("VoiidMainMenuState"));
	}
}

function updateTabText() {
	var path = "";
	for (i in 0...pageStack.length) {
		path += pageStack[i];
		if (i < pageStack.length - 1) path += " > ";
	}
	tabText.text = path;
}

function getOptionLabel(option:Dynamic):String {
	switch(option.type) {
		case "page": return option.name;
		case "action": return option.name;
		case "bool": return option.name;
		case "number": return option.name + ": " + formatNumber(getValue(option));
		case "choice": return option.name + ": " + getChoiceLabel(option);
	}
	return option.name;
}

function getChoiceLabel(option:Dynamic):String {
	var values:Array<Dynamic> = option.values;
	var idx = values.indexOf(getValue(option));
	var display:Dynamic = option.display;
	if (idx >= 0 && display != null && idx < display.length)
		return Std.string(display[idx]).toUpperCase();
	return Std.string(getValue(option)).toUpperCase();
}

function formatNumber(value:Dynamic):String {
	var n = Std.parseFloat(Std.string(value));
	if (Math.isNaN(n)) return Std.string(value);
	if (Math.abs(n - Math.round(n)) < 0.001) return Std.string(Std.int(Math.round(n)));
	return Std.string(Math.round(n * 10) / 10);
}

function update(elapsed:Float) {
	if (exiting || transitioning) return;

	if (controls.UP_P || FlxG.keys.justPressed.UP)
		changeSelection(-1);
	if (controls.DOWN_P || FlxG.keys.justPressed.DOWN)
		changeSelection(1);
	if (FlxG.mouse.wheel != 0)
		changeSelection(-FlxG.mouse.wheel);
	if (controls.LEFT_P || FlxG.keys.justPressed.LEFT)
		changeValue(-1);
	if (controls.RIGHT_P || FlxG.keys.justPressed.RIGHT)
		changeValue(1);
	if (controls.ACCEPT || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
		accept();
	if (controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
		goBack();

	updateVisuals(false, elapsed);
}

function changeSelection(change:Int) {
	var items = getPage(currentPage());
	curSelected = FlxMath.wrap(curSelected + change, 0, items.length - 1);
	CoolUtil.playMenuSFX(0, 0.7);
	updatePreview();
}

function accept() {
	var option = getPage(currentPage())[curSelected];
	switch(option.type) {
		case "page":
			selectThen(function() loadPage(option.page, false));
		case "action":
			selectThen(function() option.callback());
		case "bool":
			changeValue(1);
		case "choice":
			changeValue(1);
	}
}

function selectThen(callback:Void->Void) {
	if (transitioning) return;
	transitioning = true;
	CoolUtil.playMenuSFX(1, 0.7);
	for (i in 0...texts.length) {
		if (i == curSelected) continue;
		FlxTween.tween(texts[i], {alpha: 0}, 0.16, {ease: FlxEase.quadOut});
		if (checkboxes[i] != null)
			FlxTween.tween(checkboxes[i], {alpha: 0}, 0.16, {ease: FlxEase.quadOut});
	}
	FlxFlicker.flicker(texts[curSelected], 0.42, 0.055, true);
	if (checkboxes[curSelected] != null)
		FlxFlicker.flicker(checkboxes[curSelected], 0.42, 0.055, true);
	new FlxTimer().start(0.55, function(_) {
		transitioning = false;
		callback();
	});
}

function changeValue(change:Int) {
	var option = getPage(currentPage())[curSelected];
	switch(option.type) {
		case "bool":
			setValue(option, !(getValue(option) == true));
		case "number":
			var value = Std.parseFloat(Std.string(getValue(option)));
			if (Math.isNaN(value)) value = option.def;
			value = FlxMath.bound(value + option.step * change, option.min, option.max);
			if (option.step >= 1) value = Std.int(Math.round(value));
			setValue(option, value);
		case "choice":
			var values:Array<Dynamic> = option.values;
			var idx = values.indexOf(getValue(option));
			if (idx < 0) idx = 0;
			idx = FlxMath.wrap(idx + change, 0, values.length - 1);
			setValue(option, values[idx]);
		default:
			return;
	}
	CoolUtil.playMenuSFX(0, 0.7);
	refreshLabels(curSelected);
	updatePreview();
}

function refreshLabels(changedIndex:Int = -1) {
	var items = getPage(currentPage());
	for (i in 0...texts.length) {
		texts[i].text = getOptionLabel(items[i]);
		if (checkboxes[i] != null && i == changedIndex)
			checkboxes[i].animation.play(getValue(items[i]) == true ? "checked" : "unchecked", true);
	}
}

function getRowHalfWidth(index:Int):Float {
	if (index < 0 || index >= texts.length) return 260;
	var half = Math.min(500, texts[index].text.length * 17);
	if (checkboxes[index] != null)
		half += 96;
	return half;
}

function updateVisuals(force:Bool = false, elapsed:Float = 1) {
	for (i in 0...texts.length) {
		var offset = i - curSelected;
		var targetY = 395 + offset * 88;
		var targetX = 0.0;
		texts[i].x = force ? targetX : FlxMath.lerp(texts[i].x, targetX, elapsed * 10);
		texts[i].y = force ? targetY : FlxMath.lerp(texts[i].y, targetY, elapsed * 12);
		texts[i].alpha = Math.abs(offset) > 2 ? 0 : (i == curSelected ? 1 : 0.45);
		texts[i].scale.set(i == curSelected ? 1.05 : 0.94, i == curSelected ? 1.05 : 0.94);
		if (checkboxes[i] != null) {
			var labelHalf = Math.min(235, texts[i].text.length * 10);
			checkboxes[i].x = FlxG.width * 0.5 + labelHalf + 2;
			checkboxes[i].y = texts[i].y - 10;
			checkboxes[i].alpha = texts[i].alpha;
			checkboxes[i].scale.set(i == curSelected ? 0.86 : 0.76, i == curSelected ? 0.86 : 0.76);
		}
	}

	if (texts.length <= 0) return;
	var selectedText = texts[curSelected];
	var center = FlxG.width * 0.5;
	var halfWidth = getRowHalfWidth(curSelected);
	leftArrow.x = center - halfWidth - 130;
	rightArrow.x = center + halfWidth + 14;
	leftArrow.y = rightArrow.y = selectedText.y - 8;
}

function updatePreview() {
	clearPreview();
	var option = getPage(currentPage())[curSelected];
	switch(option.name) {
		case "Downscroll" | "Time Bar Position":
			createHudPreview();
		case "Time Bar Style":
			createTimerPreview();
		case "Alt Note Type Textures":
			createAltPunchPreview();
		case "Binds":
			createNotePreview();
	}
}

function clearPreview() {
	for (spr in previewNotes) {
		remove(spr, true);
		spr.destroy();
	}
	for (spr in previewBars) {
		remove(spr, true);
		spr.destroy();
	}
	previewNotes = [];
	previewBars = [];
}

function createHudPreview() {
	createNotePreview();
	var y = Reflect.field(FlxG.save.data, "voiidTimeBarPosition") == "bottom" ? FlxG.height - 100 : 170;
	var barBG = new FlxSprite(FlxG.width * 0.5 - 190, y).makeGraphic(380, 12, 0xCC000000);
	var barFill = new FlxSprite(barBG.x + 4, barBG.y + 4).makeGraphic(260, 4, 0xFFB943FF);
	add(barBG);
	add(barFill);
	previewBars.push(barBG);
	previewBars.push(barFill);
}

function createTimerPreview() {
	var style = Std.string(Reflect.field(FlxG.save.data, "voiidTimeBarStyle"));
	var pos = Std.string(Reflect.field(FlxG.save.data, "voiidTimeBarPosition"));
	var barHeight = style == "psych engine" ? 22 : (style == "old kade engine" ? 8 : 14);
	var fillHeight = style == "old kade engine" ? 4 : 6;
	var width = style == "old kade engine" ? 420 : 600;
	var y = pos == "bottom" ? FlxG.height - 132 : 146;
	var label = makeText(0, 165, FlxG.width, "Punch And Gun - VOIID (2:17) (BOT)", 22);
	label.alignment = "center";
	label.y = y + barHeight + 6;
	add(label);
	previewBars.push(label);
	var barBG = new FlxSprite(FlxG.width * 0.5 - (width * 0.5), y).makeGraphic(Std.int(width), Std.int(barHeight), 0xDD000000);
	var barFill = new FlxSprite(barBG.x + 4, barBG.y + ((barHeight - fillHeight) * 0.5)).makeGraphic(Std.int(width * 0.48), Std.int(fillHeight), 0xFFC05CFF);
	add(barBG);
	add(barFill);
	previewBars.push(barBG);
	previewBars.push(barFill);
}

function createAltPunchPreview() {
	var enabled = Reflect.field(FlxG.save.data, "voiidAltNoteTypeTextures") == true;
	var normal = makePunchPreviewSprite("Wiik3Punch", FlxG.width * 0.5 - 170, 145);
	var alt = makePunchPreviewSprite("Wiik3Punch-Alt", FlxG.width * 0.5 + 40, 145);
	for (spr in [normal, alt]) {
		spr.alpha = 0.45;
		add(spr);
		previewNotes.push(spr);
	}
	if (enabled) alt.alpha = 1; else normal.alpha = 1;
}

function makePunchPreviewSprite(asset:String, x:Float, y:Float):FlxSprite {
	var spr = new FlxSprite(x, y);
	spr.frames = Paths.getFrames("game/voiid/notes/" + asset);
	spr.animation.addByPrefix("idle", "square0", 24, true);
	spr.animation.play("idle");
	spr.antialiasing = Options.antialiasing;
	spr.setGraphicSize(140);
	spr.updateHitbox();
	return spr;
}

function createNotePreview() {
	var anims = ["left static", "down static", "up static", "right static"];
	var noteSize = 78;
	var gap = 116;
	var totalWidth = (anims.length - 1) * gap + noteSize;
	var startX = (FlxG.width - totalWidth) * 0.5;
	for (i in 0...4) {
		var spr = new FlxSprite();
		spr.frames = Paths.getFrames("game/voiid/notes/default");
		spr.animation.addByPrefix("idle", anims[i], 24, true);
		spr.animation.play("idle");
		spr.setGraphicSize(noteSize);
		spr.updateHitbox();
		spr.x = startX + i * gap;
		spr.y = Reflect.field(Options, "downscroll") == true ? FlxG.height - 130 : 160;
		spr.alpha = 0.7;
		add(spr);
		previewNotes.push(spr);
	}
}
