import flixel.input.gamepad.FlxGamepadInputID;
import funkin.options.PlayerSettings;
import funkin.backend.system.Controls;
import funkin.backend.system.Controls.Control;

import funkin.backend.assets.ModsFolderLibrary;
import funkin.backend.assets.ModsFolder;
import funkin.backend.utils.DiscordUtil;
import funkin.backend.utils.WindowUtils;
import funkin.game.PlayState;
import funkin.menus.FreeplayState;
import funkin.menus.MainMenuState;
import funkin.menus.StoryMenuState;

var redirectedInitialMenuToPortFreeplay:Bool = false;
var windowTitleBase:String = "Voiid Chronicles v3";
var lastAppliedWindowTitle:String = "";
var lastAppliedDiscordState:String = "";
var discordWasDisabled:Bool = false;

function new() {
	setVoiidWindowTitle("");
}

function destroy() {
	WindowUtils.winTitle = window.title = "Friday Night Funkin' - Codename Engine";
}

function setVoiidWindowTitle(detail:String) {
	var title = windowTitleBase;
	if (detail != null && StringTools.trim(detail) != "")
		title += " - " + detail;

	if (title == lastAppliedWindowTitle)
		return;

	lastAppliedWindowTitle = title;
	WindowUtils.winTitle = window.title = title;
}

function cleanWindowTitleName(name:String):String {
	if (name == null || name == "")
		return "";

	var slash = name.lastIndexOf("/");
	if (slash >= 0)
		name = name.substr(slash + 1);

	var dot = name.lastIndexOf(".");
	if (dot >= 0)
		name = name.substr(dot + 1);

	switch(name) {
		case "TitleState": return "Title Screen";
		case "MainMenuState" | "VoiidMainMenuState": return "Main Menu";
		case "VoiidOptionsState": return "Options Menu";
		case "VoiidKeybindState": return "Controls";
		case "StoryMenuState": return "Story Menu";
		case "FreeplayState" | "PortFreeState": return "Freeplay";
		case "OptionsMenu": return "Options Menu";
		case "CreditsMain" | "VoiidCreditsState": return "Credits Menu";
		case "VoiidAwardsState": return "Awards Menu";
		case "EditorTreeMenu": return "Editor Menu";
		case "ModchartEditor": return "Modchart Editor";
		case "StageEditor": return "Stage Editor";
		case "RTXStageEditor": return "RTX Stage Editor";
	}

	var out = "";
	for (i in 0...name.length) {
		var char = name.charAt(i);
		if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase())
			out += " ";
		out += char;
	}
	return out;
}

function getSavedBool(field:String, def:Bool):Bool {
	var value = Reflect.field(FlxG.save.data, field);
	if (value == null) {
		Reflect.setField(FlxG.save.data, field, def);
		FlxG.save.flush();
		return def;
	}
	return value == true;
}

function dynamicWindowRpcEnabled():Bool {
	return getSavedBool("voiidDynamicWindowRpc", true);
}

function discordRpcEnabled():Bool {
	return getSavedBool("voiidDiscordRpc", true);
}

function getVoiidSongDisplayName():String {
	if (PlayState.SONG == null || PlayState.SONG.meta == null)
		return "";

	var songName = PlayState.SONG.meta.displayName;
	if (songName == null || songName == "" || Std.string(songName) == "null")
		songName = PlayState.SONG.meta.name;

	return Std.string(songName);
}

function getVoiidDifficultyDisplayName():String {
	var diff = "";
	try {
		diff = Std.string(PlayState.difficulty);
	} catch(e:Dynamic) {}

	if (diff == null || diff == "" || diff == "null")
		return "";

	return diff.toUpperCase();
}

function getVoiidPlayModeName():String {
	try {
		if (PlayState.isStoryMode) {
			if (PlayState.storyWeek != null && PlayState.storyWeek.name != null && Std.string(PlayState.storyWeek.name) != "")
				return "Story Mode: " + Std.string(PlayState.storyWeek.name);
			return "Story Mode";
		}
	} catch(e:Dynamic) {}

	return "Freeplay";
}

function getVoiidGameplayTitleDetail():String {
	var songName = getVoiidSongDisplayName();
	if (songName == "")
		return "";

	var diff = getVoiidDifficultyDisplayName();
	var mode = getVoiidPlayModeName();
	var detail = songName;
	if (diff != "")
		detail += " - " + diff;
	if (mode != "")
		detail += " (" + mode + ")";

	var playState:Dynamic = PlayState.instance;
	if (playState != null && Reflect.field(playState, "paused") == true)
		detail = "Paused - " + detail;

	return detail;
}

function getCurrentWindowTitleDetail():String {
	if (Std.isOfType(FlxG.state, PlayState) && PlayState.SONG != null && PlayState.SONG.meta != null) {
		if (dynamicWindowRpcEnabled()) {
			var detail = getVoiidGameplayTitleDetail();
			if (detail != "")
				return detail;
		}

		var songName = getVoiidSongDisplayName();
		var diff = getVoiidDifficultyDisplayName();
		if (songName != "")
			return songName + (diff == "" ? "" : " (" + diff + ")");
	}

	var scriptName:Dynamic = Reflect.field(FlxG.state, "scriptName");
	if (scriptName != null && Std.string(scriptName) != "")
		return cleanWindowTitleName(Std.string(scriptName));

	var className = Type.getClassName(Type.getClass(FlxG.state));
	return cleanWindowTitleName(className);
}

function updateVoiidWindowTitle(force:Bool = false) {
	if (FlxG.state == null)
		return;

	setVoiidWindowTitle(getCurrentWindowTitleDetail());
}

function updateVoiidDiscordState(force:Bool = false) {
	if (FlxG.state == null || Std.isOfType(FlxG.state, PlayState))
		return;

	if (!discordRpcEnabled()) {
		if (!discordWasDisabled) {
			discordWasDisabled = true;
			lastAppliedDiscordState = "";
			DiscordUtil.clearPresence();
		}
		return;
	}
	discordWasDisabled = false;

	var detail = getCurrentWindowTitleDetail();
	if (detail == null || StringTools.trim(detail) == "")
		return;

	if (!force && detail == lastAppliedDiscordState)
		return;

	lastAppliedDiscordState = detail;
	DiscordUtil.changePresenceSince(detail, null);
}

function preStateSwitch() {
	
	if (Std.isOfType(FlxG.game._requestedState, FreeplayState)) {
		trace("Global redirect: FreeplayState -> PortFreeState");
		FlxG.game._requestedState = new ModState("PortFreeState");
		return;
	}

	
	
	if (Std.isOfType(FlxG.game._requestedState, MainMenuState)) {
		Reflect.setField(FlxG.save.data, "voiidReturnToPortFreeplayFromModSwitch", false);
		redirectedInitialMenuToPortFreeplay = true;
		FlxG.game._requestedState = new ModState("VoiidMainMenuState");
	}

	if (Std.isOfType(FlxG.game._requestedState, StoryMenuState)) {
		FlxG.game._requestedState = new ModState("VoiidMainMenuState");
	}
}
var ogModFolder = ModsFolder.currentModFolder;
var loadedPaths:Array<String> = [];
var init = false;
function postStateSwitch()
{
	PauseSubState.script = "data/scripts/pause";
	if (Std.isOfType(FlxG.state, StoryMenuState)) {
		FlxG.switchState(new ModState("VoiidMainMenuState"));
		return;
	}
	updateVoiidWindowTitle(true);
	updateVoiidDiscordState(true);
	
	if (init)
		return;

	init = true;


	var orderList = Assets.getText(Paths.getPath("content/order.txt"));
	var list = orderList.split("\n");
	list.reverse();
	for (folder in list) {
		var f = StringTools.trim(folder);
		Paths.assetsTree.addLibrary(ModsFolder.loadModLib(ModsFolder.modsPath + ModsFolder.currentModFolder + "/content/" + f, false, ModsFolder.currentModFolder + "/content/" + f));
		loadedPaths.push(f);
	}

	var contentFolders = Paths.getFolderDirectories("content/");
	for (f in contentFolders) {
		if (!loadedPaths.contains(f)) {
			Paths.assetsTree.addLibrary(ModsFolder.loadModLib(ModsFolder.modsPath + ModsFolder.currentModFolder + "/content/" + f, false, ModsFolder.currentModFolder + "/content/" + f));
			loadedPaths.push(f);
		}
	}
}


function normalizeAssetPath(path:String):String {
	return path == null ? "" : StringTools.replace(path, "\\", "/");
}

function isInContentFolder(fullPath:String, folder:String):Bool {
	fullPath = normalizeAssetPath(fullPath).toLowerCase();
	var contentPath = normalizeAssetPath(ModsFolder.modsPath + ogModFolder + "/content/" + folder).toLowerCase();
	var contentPathNoDot = StringTools.startsWith(contentPath, "./") ? contentPath.substr(2) : contentPath;
	var absoluteContentPath = ("/mods/" + ogModFolder + "/content/" + folder).toLowerCase();
	return StringTools.startsWith(fullPath, contentPath) || StringTools.startsWith(fullPath, contentPathNoDot) || fullPath.indexOf(absoluteContentPath) != -1;
}

public static function updateFolderFromSong(song:String) {
	var fullPath = Paths.assetsTree.getSpecificPath("assets/songs/"+song+"/meta.json");
	ModsFolder.currentModFolder = ogModFolder;
	
	var contentFolders = Paths.getFolderDirectories("content/");
	for (f in contentFolders) {
		if (isInContentFolder(fullPath, f)) {
			ModsFolder.currentModFolder = ogModFolder + "/content/" + f;
			trace(ModsFolder.currentModFolder);
		}
	}
}
public static function updateFolderFromCharacter(character:String) {
	var fullPath = Paths.assetsTree.getSpecificPath("assets/data/characters/"+character+".xml");
	ModsFolder.currentModFolder = ogModFolder;
	
	var contentFolders = Paths.getFolderDirectories("content/");
	for (f in contentFolders) {
		if (isInContentFolder(fullPath, f)) {
			ModsFolder.currentModFolder = ogModFolder + "/content/" + f;
			trace(ModsFolder.currentModFolder);
		}
	}
}
