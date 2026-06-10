import flixel.input.gamepad.FlxGamepadInputID;
import funkin.options.PlayerSettings;
import funkin.backend.system.Controls;
import funkin.backend.system.Controls.Control;

import funkin.backend.assets.ModsFolderLibrary;
import funkin.backend.assets.ModsFolder;
import funkin.menus.FreeplayState;
import funkin.menus.MainMenuState;

var redirectedInitialMenuToPortFreeplay:Bool = false;

function preStateSwitch() {
	if (Std.isOfType(FlxG.game._requestedState, FreeplayState)) {
		trace("Global redirect: FreeplayState -> PortFreeState");
		FlxG.game._requestedState = new ModState("PortFreeState");
		return;
	}

	var forcePortFreeplay = Reflect.field(FlxG.save.data, "voiidReturnToPortFreeplayFromModSwitch") == true;
	if ((forcePortFreeplay || !redirectedInitialMenuToPortFreeplay) && Std.isOfType(FlxG.game._requestedState, MainMenuState)) {
		Reflect.setField(FlxG.save.data, "voiidReturnToPortFreeplayFromModSwitch", false);
		redirectedInitialMenuToPortFreeplay = true;
		trace("Global redirect: MainMenuState -> PortFreeState");
		FlxG.game._requestedState = new ModState("PortFreeState");
	}
}

var ogModFolder = ModsFolder.currentModFolder;
var loadedPaths:Array<String> = [];
var init = false;
function postStateSwitch()
{
	PauseSubState.script = "data/scripts/pause";
	
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
//make sure that saving charts/characters go to the correct content folder
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
