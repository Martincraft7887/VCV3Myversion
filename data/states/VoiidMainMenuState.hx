import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.FunkinText;
import funkin.backend.scripting.ModState;
import funkin.editors.EditorPicker;
import funkin.game.PlayState;
import funkin.menus.TitleState;
import funkin.menus.ModSwitchMenu;
import lime.utils.Assets;

using StringTools;

var wiikList:Array<String> = ["Wiik 1", "Wiik 2", "Wiik 3", "Wiik 100"];
var wiikNumbers:Array<String> = ["1", "2", "3", "100"];
var wiiks:Array<Array<String>> = [
	["Light It Up", "Ruckus", "Target Practice"],
	["Burnout", "Sporting", "Boxing Match"],
	["Fisticuffs", "Blastout", "Immortal", "King Hit"],
	["Mat", "Banger", "Edgy"]
];

var selectedWiik:Int = 0;
var selectedItem:Int = 0;
var selectedSomething:Bool = false;
var buttons:Array<Dynamic> = [];
var storySelected:Array<FlxSprite> = [];
var storyUnselected:Array<FlxSprite> = [];
var storyLocks:Array<FlxSprite> = [];
var wiikBGs:Array<FlxSprite> = [];
var rain:Array<FlxSprite> = [];
var upArrow:FlxSprite;
var downArrow:FlxSprite;
var logo:FlxSprite;
var versionText:FunkinText;
var helpText:FunkinText;
var continuePrompt:Bool = false;
var continueChoice:Bool = true;
var continuePromptObjects:Array<Dynamic> = [];

function create() {
	CoolUtil.playMenuSong();
	FlxG.mouse.visible = true;

	var lockedBG = fullImage("main menu/new/LOCKED_BG");
	add(lockedBG);

	for (i in 0...wiikNumbers.length) {
		var bg = fullImage("main menu/new/" + wiikNumbers[i] + "_BG");
		bg.alpha = i == selectedWiik ? 1 : 0;
		add(bg);
		wiikBGs.push(bg);
	}

	makeRain();

	for (name in ["DOT_DOWN", "DOT_UP", "BLACK_STAINS"])
		add(fullImage("main menu/new/" + name));

	logo = new FlxSprite().loadGraphic(Paths.image("main menu/new/LOGO_V2"));
	logo.antialiasing = Options.antialiasing;
	logo.setGraphicSize(Std.int(logo.width * 0.7));
	logo.updateHitbox();
	logo.screenCenter(FlxAxes.X);
	logo.y = 0;
	add(logo);

	makeStoryButton();
	makeMenuButton("credits", 50, FlxG.height - 270, function() switchAfter("VoiidCreditsState"));
	makeMenuButton("freeplay", 257, FlxG.height - 270, function() switchAfter("PortFreeState"));
	makeMenuButton("awards", FlxG.width - 464, FlxG.height - 270, function() switchAfter("VoiidAwardsState"));
	makeMenuButton("options", FlxG.width - 242, FlxG.height - 270, function() switchAfter("VoiidOptionsState"));

	makeHitButton("weekUp", FlxG.width * 0.5 - 181, FlxG.height * 0.5 - 225, 363, 100, function() changeWeek(-1));
	makeHitButton("weekDown", FlxG.width * 0.5 - 181, FlxG.height * 0.5 + 235, 363, 100, function() changeWeek(1));

	downArrow = fullImage("main menu/new/DOWN_ARROW");
	upArrow = fullImage("main menu/new/UP_ARROW");
	add(downArrow);
	add(upArrow);

	var bar = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
	bar.alpha = 0.6;
	add(bar);

	helpText = new FunkinText(0, FlxG.height - 23, FlxG.width, "UP/DOWN change Wiik  |  ENTER/click select  |  ESC back to title", 16, true);
	helpText.alignment = "center";
	helpText.font = Paths.font("vcr.ttf");
	add(helpText);

	versionText = new FunkinText(0, 6, 0, "Voiid Chronicles v3\nCodename Engine", 16, true);
	versionText.alignment = "right";
	versionText.font = Paths.font("vcr.ttf");
	versionText.x = FlxG.width - versionText.width - 8;
	add(versionText);

	updateSelection(0, true);
	changeWeek(0, true);
	showPendingAwards();
}

function normalSongKey(name:String):String {
	if (name == null) return "";
	var key = Std.string(name).toLowerCase().trim();
	key = key.replace(" ", "");
	key = key.replace("-", "");
	key = key.replace("_", "");
	key = key.replace("'", "");
	key = key.replace("\"", "");
	return key;
}

function weekCompleteField(weekName:String):String {
	return "voiid_story_complete_" + normalSongKey(weekName);
}

function weekProgressField(weekName:String):String {
	return "voiid_story_progress_" + normalSongKey(weekName);
}

function getWeekProgress(weekIndex:Int):Int {
	if (weekIndex < 0 || weekIndex >= wiikList.length) return 0;
	var value = Reflect.field(FlxG.save.data, weekProgressField(wiikList[weekIndex]));
	var parsed = Std.parseInt(Std.string(value));
	if (parsed == null) {
		var nextSong = Reflect.field(FlxG.save.data, "voiid_story_progress_song_" + normalSongKey(wiikList[weekIndex]));
		if (nextSong == null) return 0;
		var nextKey = normalSongKey(Std.string(nextSong));
		for (i in 0...wiiks[weekIndex].length)
			if (normalSongKey(wiiks[weekIndex][i]) == nextKey)
				return i;
		return 0;
	}
	return FlxMath.wrap(parsed, 0, wiiks[weekIndex].length - 1);
}

function isWiikUnlocked(index:Int):Bool {
	if (index <= 0) return true;
	var prev = wiikList[index - 1];
	return Reflect.field(FlxG.save.data, weekCompleteField(prev)) == true
		|| Reflect.field(FlxG.save.data, "voiid_award_beat_" + prev.toLowerCase()) == true;
}

function clearWeekProgress(weekIndex:Int) {
	if (weekIndex < 0 || weekIndex >= wiikList.length) return;
	Reflect.deleteField(FlxG.save.data, weekProgressField(wiikList[weekIndex]));
	Reflect.deleteField(FlxG.save.data, "voiid_story_progress_song_" + normalSongKey(wiikList[weekIndex]));
	FlxG.save.flush();
}

function fullImage(path:String):FlxSprite {
	var spr = new FlxSprite().loadGraphic(Paths.image(path));
	spr.setGraphicSize(FlxG.width);
	spr.updateHitbox();
	spr.screenCenter();
	spr.antialiasing = Options.antialiasing;
	return spr;
}

function makeHitButton(id:String, x:Float, y:Float, w:Int, h:Int, callback:Void->Void) {
	var hit = new FlxSprite(x, y).makeGraphic(w, h, 0x01000000);
	hit.visible = false;
	add(hit);
	buttons.push({id: id, hit: hit, selected: null, unselected: null, callback: callback, enabled: true, selectable: false});
}

function makeMenuButton(type:String, x:Float, y:Float, callback:Void->Void) {
	var hit = new FlxSprite(x, y).makeGraphic(177, 235, 0x01000000);
	hit.visible = false;
	add(hit);

	var suffix = "";
	if (type == "credits") {
		var list = ["MEL", "MLOM", "RHYS", "ZORO"];
		suffix = "_" + list[FlxG.random.int(0, list.length - 1)];
	}

	var key = type.toUpperCase() + suffix;
	var unselected = fullImage("main menu/new/BOXES/UNSELECTED/" + key);
	var selected = fullImage("main menu/new/BOXES/SELECTED/" + key);
	selected.alpha = 0;
	add(unselected);
	add(selected);

	buttons.push({id: type, hit: hit, selected: selected, unselected: unselected, callback: callback, enabled: true, selectable: true});
}

function makeStoryButton() {
	var hit = new FlxSprite(0, 0).makeGraphic(363, 363, 0x01000000);
	hit.screenCenter();
	hit.y += 60;
	hit.visible = false;
	add(hit);

	for (i in 0...wiikNumbers.length) {
		var unselected = fullImage("main menu/new/STORYMODE/SM UNSELECTED/WIIK_" + wiikNumbers[i]);
		var selected = fullImage("main menu/new/STORYMODE/SELECTED/WIIK_" + wiikNumbers[i]);
		unselected.alpha = selected.alpha = 0;
		add(unselected);
		add(selected);
		storyUnselected.push(unselected);
		storySelected.push(selected);

		var lockPath = "main menu/new/STORYMODE/SM LOCKED/WIIK_" + wiikNumbers[i];
		if (!Assets.exists(Paths.image(lockPath)))
			lockPath = "main menu/new/STORYMODE/SM LOCKED/LOCK";
		var lock = fullImage(lockPath);
		lock.alpha = 0;
		add(lock);
		storyLocks.push(lock);
	}

	buttons.push({id: "story", hit: hit, selected: null, unselected: null, callback: startSelectedWiik, enabled: true, selectable: true});
}

function makeRain() {
	for (i in 0...80) {
		var drop = new FlxSprite(0, -1000).makeGraphic(60, 3, 0xFFFFFFFF);
		drop.angle = 140;
		drop.alpha = 0;
		add(drop);
		rain.push(drop);
	}
}

function emitRain(elapsed:Float) {
	if (wiikList[selectedWiik] != "Wiik 100") {
		for (drop in rain) drop.alpha = FlxMath.lerp(drop.alpha, 0, elapsed * 8);
		return;
	}

	for (drop in rain) {
		if (drop.alpha <= 0.02 || drop.y > FlxG.height + 80 || drop.x < -120) {
			drop.x = FlxG.random.float(500, 3000);
			drop.y = FlxG.random.float(-300, -20);
			drop.alpha = FlxG.random.float(0.25, 0.7);
		}
		drop.x += Math.cos(drop.angle * Math.PI / 180) * 5000 * elapsed;
		drop.y += Math.sin(drop.angle * Math.PI / 180) * 5000 * elapsed;
	}
}

function update(elapsed:Float) {
	if (continuePrompt) {
		updateContinuePrompt(elapsed);
		return;
	}
	if (selectedSomething) return;

	emitRain(elapsed);

	if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
		changeWeek(-1);
	if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
		changeWeek(1);
	if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
		updateSelection(-1);
	if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
		updateSelection(1);
	if (FlxG.keys.justPressed.ESCAPE || controls.BACK)
		FlxG.switchState(new TitleState());
	if (FlxG.keys.justPressed.SEVEN) {
		persistentUpdate = false;
		persistentDraw = true;
		openSubState(new EditorPicker());
	}
	if (FlxG.keys.justPressed.TAB) {
		persistentUpdate = false;
		persistentDraw = true;
		openSubState(new ModSwitchMenu());
	}
	if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || controls.ACCEPT)
		pressCurrent();

	if (FlxG.mouse.wheel != 0)
		changeWeek(-FlxG.mouse.wheel);

	for (i in 0...buttons.length) {
		var b = buttons[i];
		if (FlxG.mouse.overlaps(b.hit)) {
			if (b.selectable)
				selectedItem = i;
			if (FlxG.mouse.justPressed)
				Reflect.callMethod(null, b.callback, []);
		}
	}

	for (i in 0...wiikBGs.length) {
		var target = i == selectedWiik ? 1 : 0;
		wiikBGs[i].alpha = FlxMath.lerp(wiikBGs[i].alpha, target, elapsed * 10);
	}

	for (i in 0...storyUnselected.length) {
		storyUnselected[i].alpha = FlxMath.lerp(storyUnselected[i].alpha, i == selectedWiik ? 1 : 0, elapsed * 12);
		var targetSelected = (i == selectedWiik && (selectedItem == getButtonIndex("story") || FlxG.mouse.overlaps(buttons[getButtonIndex("story")].hit))) ? 1 : 0;
		storySelected[i].alpha = FlxMath.lerp(storySelected[i].alpha, targetSelected, elapsed * 12);
		if (i < storyLocks.length) {
			storyLocks[i].alpha = FlxMath.lerp(storyLocks[i].alpha, (i == selectedWiik && !isWiikUnlocked(i)) ? 1 : 0, elapsed * 12);
		}
	}

	for (i in 0...buttons.length) {
		var b = buttons[i];
		if (b.selected != null) {
			var target = (i == selectedItem || FlxG.mouse.overlaps(b.hit)) ? 1 : 0;
			b.selected.alpha = FlxMath.lerp(b.selected.alpha, target, elapsed * 12);
		}
	}

	upArrow.y = FlxMath.lerp(upArrow.y, 0, elapsed * 9);
	downArrow.y = FlxMath.lerp(downArrow.y, 0, elapsed * 9);
}

function getButtonIndex(id:String):Int {
	for (i in 0...buttons.length)
		if (buttons[i].id == id)
			return i;
	return 0;
}

function updateSelection(change:Int = 0, force:Bool = false) {
	if (change == 0 && !force) return;
	do {
		selectedItem = FlxMath.wrap(selectedItem + change, 0, buttons.length - 1);
	} while (!buttons[selectedItem].selectable);
	if (!force) CoolUtil.playMenuSFX(0, 0.7);
}

function changeWeek(change:Int = 0, force:Bool = false) {
	if (change == 0 && !force) return;
	selectedWiik = FlxMath.wrap(selectedWiik + change, 0, wiikList.length - 1);
	if (!force) CoolUtil.playMenuSFX(0, 0.7);
	if (change < 0) upArrow.y -= 20;
	if (change > 0) downArrow.y += 20;
}

function pressCurrent() {
	var b = buttons[selectedItem];
	if (b != null && b.enabled)
		Reflect.callMethod(null, b.callback, []);
}

function onSelectItem() {
	selectedSomething = true;
	FlxG.mouse.visible = false;
	CoolUtil.playMenuSFX(1, 0.7);
	var selected = buttons[selectedItem];
	for (i in 0...buttons.length) {
		var b = buttons[i];
		if (i == selectedItem) continue;
		if (b.selected != null) FlxTween.tween(b.selected, {alpha: 0}, 0.18, {ease: FlxEase.quadOut});
		if (b.unselected != null) FlxTween.tween(b.unselected, {alpha: 0}, 0.18, {ease: FlxEase.quadOut});
	}
	if (selected.selected != null)
		FlxFlicker.flicker(selected.selected, 0.48, 0.06, true);
	if (selected.unselected != null)
		FlxTween.tween(selected.unselected, {alpha: 0}, 0.2, {ease: FlxEase.quadOut});
	if (selected.id == "story" && selectedWiik < storySelected.length)
		FlxFlicker.flicker(storySelected[selectedWiik], 0.48, 0.06, true);
}

function switchAfter(stateName:String) {
	onSelectItem();
	new FlxTimer().start(0.85, function(_) FlxG.switchState(new ModState(stateName)));
}

function startSelectedWiik() {
	if (!isWiikUnlocked(selectedWiik)) {
		CoolUtil.playMenuSFX(2, 0.7);
		return;
	}
	var progress = getWeekProgress(selectedWiik);
	if (progress > 0 && progress < wiiks[selectedWiik].length) {
		showContinuePrompt();
		return;
	}
	startWiikFromIndex(0);
}

function startWiikFromIndex(startIndex:Int) {
	onSelectItem();
	if (startIndex <= 0) clearWeekProgress(selectedWiik);
	var playlist = wiiks[selectedWiik].slice(startIndex);
	var diff = "voiid";

	PlayState.storyWeek = {
		name: wiikList[selectedWiik],
		id: wiikList[selectedWiik].toLowerCase().replace(" ", "-"),
		sprite: "",
		chars: [null, null, null],
		songs: [for (song in wiiks[selectedWiik]) {name: song}],
		difficulties: [diff],
		bgColor: FlxColor.BLACK
	};
	PlayState.storyPlaylist = playlist;
	var variations:Array<String> = [];
	for (song in playlist)
		variations.push(null);
	PlayState.storyVariations = variations;
	PlayState.isStoryMode = true;
	PlayState.campaignScore = 0;
	PlayState.campaignMisses = 0;
	PlayState.campaignAccuracyTotal = 0;
	PlayState.campaignAccuracyCount = 0;
	PlayState.chartingMode = false;
	PlayState.opponentMode = false;
	PlayState.coopMode = false;
	PlayState.__loadSong(playlist[0], diff, null);

	new FlxTimer().start(0.85, function(_) FlxG.switchState(new PlayState()));
}

function showContinuePrompt() {
	continuePrompt = true;
	continueChoice = true;
	CoolUtil.playMenuSFX(0, 0.7);

	var shade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xDD000000);
	add(shade);
	continuePromptObjects.push(shade);

	var question = new FunkinText(0, 54, FlxG.width, "Do you want to continue from\nwhere you left off?", 56, true);
	question.alignment = "center";
	question.font = Paths.font("Contb___.ttf");
	question.borderStyle = FlxTextBorderStyle.OUTLINE;
	question.borderColor = 0xFF000000;
	question.borderSize = 4;
	add(question);
	continuePromptObjects.push(question);

	var yes = new FunkinText(260, 300, 260, "Yes", 58, true);
	yes.font = Paths.font("Contb___.ttf");
	yes.borderStyle = FlxTextBorderStyle.OUTLINE;
	yes.borderColor = 0xFF000000;
	yes.borderSize = 4;
	add(yes);
	continuePromptObjects.push(yes);

	var no = new FunkinText(920, 300, 220, "No", 58, true);
	no.font = Paths.font("Contb___.ttf");
	no.borderStyle = FlxTextBorderStyle.OUTLINE;
	no.borderColor = 0xFF000000;
	no.borderSize = 4;
	add(no);
	continuePromptObjects.push(no);
}

function updateContinuePrompt(elapsed:Float) {
	var yes = continuePromptObjects.length > 2 ? continuePromptObjects[2] : null;
	var no = continuePromptObjects.length > 3 ? continuePromptObjects[3] : null;
	if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.A || FlxG.keys.justPressed.D) {
		continueChoice = !continueChoice;
		CoolUtil.playMenuSFX(0, 0.7);
	}
	if (yes != null) yes.alpha = FlxMath.lerp(yes.alpha, continueChoice ? 1 : 0.45, elapsed * 12);
	if (no != null) no.alpha = FlxMath.lerp(no.alpha, continueChoice ? 0.45 : 1, elapsed * 12);
	if (FlxG.keys.justPressed.ESCAPE || controls.BACK) {
		closeContinuePrompt();
		CoolUtil.playMenuSFX(2, 0.7);
		return;
	}
	if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || controls.ACCEPT) {
		var startIndex = continueChoice ? getWeekProgress(selectedWiik) : 0;
		closeContinuePrompt();
		startWiikFromIndex(startIndex);
	}
}

function closeContinuePrompt() {
	continuePrompt = false;
	for (obj in continuePromptObjects) {
		remove(obj);
		obj.destroy();
	}
	continuePromptObjects = [];
}

function showPendingAwards() {
	var pending:Array<Dynamic> = Reflect.field(FlxG.save.data, "voiidPendingAwards");
	if (pending == null || pending.length <= 0)
		return;

	Reflect.setField(FlxG.save.data, "voiidPendingAwards", []);
	FlxG.save.flush();

	var delay = 0.25;
	for (award in pending) {
		new FlxTimer().start(delay, function(_) showAwardPopup(award));
		delay += 0.55;
	}
}

function showAwardPopup(award:Dynamic) {
	var popup = new FlxSprite(FlxG.width + 20, 90).makeGraphic(400, 112, 0xEE000000);
	add(popup);

	var title = new FunkinText(popup.x + 18, popup.y + 10, 270, "Award unlocked!", 20, true);
	title.font = Paths.font("vcr.ttf");
	add(title);

	var name = new FunkinText(popup.x + 18, popup.y + 42, 270, Std.string(award.name), 30, true);
	name.font = Paths.font("Contb___.ttf");
	add(name);

	var iconPath = "awards/" + Std.string(award.image);
	if (!Assets.exists(Paths.image(iconPath))) iconPath = "awards/default";
	var icon = new FlxSprite(popup.x + 300, popup.y + 13).loadGraphic(Paths.image(iconPath));
	icon.setGraphicSize(86, 86);
	icon.updateHitbox();
	icon.antialiasing = Options.antialiasing;
	add(icon);

	function sync() {
		title.x = popup.x + 18;
		name.x = popup.x + 18;
		icon.x = popup.x + 300;
	}

	FlxTween.tween(popup, {x: FlxG.width - 420}, 0.45, {ease: FlxEase.quartOut, onUpdate: function(_) sync(), onComplete: function(_) {
		new FlxTimer().start(3.0, function(_) {
			FlxTween.tween(popup, {x: FlxG.width + 24}, 0.35, {ease: FlxEase.quadIn, onUpdate: function(_) sync(), onComplete: function(_) {
				for (obj in [popup, title, name, icon]) {
					remove(obj);
					obj.destroy();
				}
			}});
		});
	}});
}
