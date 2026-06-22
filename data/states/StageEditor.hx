import funkin.editors.stage.StageEditor;
import funkin.editors.stage.elements.StageCharacterButton;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIDropDown;
import funkin.editors.SaveWarning;
import funkin.game.Character;
import funkin.backend.system.Flags;
import funkin.backend.utils.CoolUtil;
import haxe.io.Path;
import sys.FileSystem;
import StringTools;

var vcStageEditorOffsetID:String = "voiidLECharacterOffsetApplied";
var vcPreviewPanel:Array<Dynamic> = [];
var vcPreviewPanelVisible:Bool = true;
var vcCharacterPacks:Array<Dynamic> = null;
var vcPreviewPages:Map<String, Int> = [];
var vcPreviewDropdowns:Map<String, UIDropDown> = [];
var vcSaveTargets:Array<Dynamic> = null;
var vcSaveTargetIndex:Int = 0;
var vcSaveDeleteOld:Bool = false;
var vcOriginalSaveRoot:String = null;
var vcLastSavePath:String = null;

function postCreate() {
	createVCPreviewPanel();
	SaveWarning.saveFunc = saveVCStageToSelectedTarget;
	applyVCStageEditorOffsets();
}

function postUpdate(elapsed:Float) {
	applyVCStageEditorOffsets();
}

function applyVCStageEditorOffsets() {
	var editor = StageEditor.instance;
	if (editor == null || editor.chars == null)
		return;

	for (char in editor.chars) {
		if (char == null || char.extra == null)
			continue;

		var offsetX = (char.frameWidth * char.scale.x) / 2;
		var offsetY = char.frameHeight * char.scale.y;
		var data = char.extra.get(vcStageEditorOffsetID);

		if (data == null) {
			data = {
				baseX: char.globalOffset.x,
				baseY: char.globalOffset.y,
				offsetX: offsetX,
				offsetY: offsetY
			};
			char.extra.set(vcStageEditorOffsetID, data);
		}

		var targetX:Float = Reflect.field(data, "baseX") - offsetX;
		var targetY:Float = Reflect.field(data, "baseY") - offsetY;
		if (char.globalOffset.x != targetX || char.globalOffset.y != targetY || Reflect.field(data, "offsetX") != offsetX || Reflect.field(data, "offsetY") != offsetY) {
			char.globalOffset.x = targetX;
			char.globalOffset.y = targetY;
			Reflect.setField(data, "offsetX", offsetX);
			Reflect.setField(data, "offsetY", offsetY);
			refreshVCStageEditorCharacter(char);
		}
	}
}

function createVCPreviewPanel() {
	var editor = StageEditor.instance;
	if (editor == null || editor.uiCamera == null)
		return;

	var packs = getVCCharacterPacks();
	var y = 34;
	var toggle = new UIButton(8, y, "Voiid preview", function() {
		toggleVCPreviewPanel();
	}, 126, 28);
	addVCPreviewControl(toggle);

	makeVCPreviewDropdown("dad", "NO_DELETE_dad", 8, y + 34, packs);
	makeVCPreviewDropdown("bf", "NO_DELETE_boyfriend", 8, y + 70, packs);
	makeVCPreviewDropdown("gf", "NO_DELETE_girlfriend", 8, y + 106, packs);
	createVCStageSavePanel(8, y + 144);
}

function addVCPreviewControl(control:Dynamic) {
	var editor = StageEditor.instance;
	if (editor != null && editor.uiCamera != null)
		control.cameras = [editor.uiCamera];
	vcPreviewPanel.push(control);
	add(control);
}

function makeVCPreviewDropdown(label:String, charKey:String, x:Float, y:Float, packs:Array<Dynamic>) {
	vcPreviewPages.set(charKey, 0);
	var dropdown = new UIDropDown(x, y, 188, 28, getVCPreviewPageOptions(label, charKey, packs), 0);
	dropdown.onChange = function(i) {
		if (i <= 0)
			resetVCPreviewCharacter(charKey);
		else
			changeVCPreviewCharacter(charKey, dropdown.options[i]);
	};
	vcPreviewDropdowns.set(charKey, dropdown);
	addVCPreviewControl(dropdown);

	var prev = new UIButton(x + 194, y, "<", function() {
		changeVCPreviewPage(label, charKey, packs, -1);
	}, 28, 28);
	addVCPreviewControl(prev);

	var next = new UIButton(x + 226, y, ">", function() {
		changeVCPreviewPage(label, charKey, packs, 1);
	}, 28, 28);
	addVCPreviewControl(next);
}

function getVCPreviewPageOptions(label:String, charKey:String, packs:Array<Dynamic>):Array<String> {
	var page = vcPreviewPages.exists(charKey) ? vcPreviewPages.get(charKey) : 0;
	var pageCount = getVCPreviewPageCount(packs);
	if (page < 0)
		page = pageCount - 1;
	if (page >= pageCount)
		page = 0;
	vcPreviewPages.set(charKey, page);

	var pack = packs[page];
	var packName:String = cast Reflect.field(pack, "name");
	var chars:Array<String> = cast Reflect.field(pack, "chars");
	var options = [label + ": " + packName + " " + (page + 1) + "/" + pageCount];
	for (char in chars)
		options.push(char);
	return options;
}

function getVCPreviewPageCount(packs:Array<Dynamic>):Int {
	if (packs == null || packs.length <= 0)
		return 1;
	return packs.length;
}

function changeVCPreviewPage(label:String, charKey:String, packs:Array<Dynamic>, dir:Int) {
	var dropdown = vcPreviewDropdowns.get(charKey);
	if (dropdown == null)
		return;

	var page = vcPreviewPages.exists(charKey) ? vcPreviewPages.get(charKey) : 0;
	vcPreviewPages.set(charKey, page + dir);
	var options = getVCPreviewPageOptions(label, charKey, packs);
	dropdown.items = UIDropDown.getItems(options);
	dropdown.options = options;
	dropdown.index = 0;
	dropdown.label.text = options[0];
}

function createVCStageSavePanel(x:Float, y:Float) {
	var targets = getVCStageSaveTargets();
	var options = [for (target in targets) Std.string(Reflect.field(target, "label"))];
	var dropdown = new UIDropDown(x, y, 254, 28, options, vcSaveTargetIndex);
	dropdown.onChange = function(i) {
		vcSaveTargetIndex = i;
	};
	addVCPreviewControl(dropdown);

	var deleteOld = new UICheckbox(x, y + 34, "delete old", vcSaveDeleteOld, 118, true);
	deleteOld.onChecked = function(checked) {
		vcSaveDeleteOld = checked;
	};
	addVCPreviewControl(deleteOld);

	var saveHere = new UIButton(x + 126, y + 34, "save here", function() {
		saveVCStageToSelectedTarget();
	}, 84, 24);
	addVCPreviewControl(saveHere);

	var saveCurrent = new UIButton(x + 214, y + 34, "current", function() {
		saveVCStageToCurrentTarget();
	}, 62, 24);
	addVCPreviewControl(saveCurrent);
}

function saveVCStageToSelectedTarget() {
	var targets = getVCStageSaveTargets();
	if (targets == null || targets.length <= 0)
		return;

	if (vcSaveTargetIndex < 0)
		vcSaveTargetIndex = 0;
	if (vcSaveTargetIndex >= targets.length)
		vcSaveTargetIndex = targets.length - 1;

	saveVCStageToRoot(cast Reflect.field(targets[vcSaveTargetIndex], "root"), vcSaveDeleteOld);
}

function saveVCStageToCurrentTarget() {
	saveVCStageToRoot(getVCCurrentSaveRoot(), false);
}

function saveVCStageToRoot(root:String, deleteOld:Bool) {
	var editor = StageEditor.instance;
	if (editor == null || root == null || root.length <= 0)
		return;

	var stageName = getVCStageFileName();
	var targetPath = normalizeVCPath(root) + "/data/stages/" + stageName + ".xml";
	var oldPath = vcLastSavePath != null ? vcLastSavePath : getVCCurrentStageSavePath();
	var buildStage = Reflect.field(editor, "buildStage");
	if (buildStage == null)
		return;
	var stageData:String = cast Reflect.callMethod(editor, buildStage, []);

	FlxG.sound.play(Paths.sound("editors/save"));
	CoolUtil.safeSaveFile(targetPath, stageData);
	if (deleteOld && oldPath != null && normalizeVCPath(oldPath) != normalizeVCPath(targetPath) && FileSystem.exists(oldPath)) {
		try {
			FileSystem.deleteFile(oldPath);
		} catch(e:Dynamic) {}
	}

	vcLastSavePath = targetPath;
	try {
		var undos = Reflect.field(editor, "undos");
		if (undos != null) {
			var save = Reflect.field(undos, "save");
			if (save != null)
				Reflect.callMethod(undos, save, []);
		}
	} catch(e:Dynamic) {}
	SaveWarning.showWarning = false;
}

function getVCStageSaveTargets():Array<Dynamic> {
	if (vcSaveTargets != null)
		return vcSaveTargets;

	var targets:Array<Dynamic> = [];
	var found:Map<String, Bool> = [];
	var currentRoot = getVCCurrentSaveRoot();
	var modRoot = getVCModRoot();

	addVCStageSaveTarget(targets, found, "No content", modRoot);
	addVCStageSaveTarget(targets, found, "Engine current", currentRoot);
	collectVCStageSaveTargets(modRoot + "/content", targets, found, "");

	vcSaveTargets = targets;
	for (i in 0...targets.length) {
		if (normalizeVCPath(cast Reflect.field(targets[i], "root")) == normalizeVCPath(currentRoot))
			vcSaveTargetIndex = i;
	}
	return vcSaveTargets;
}

function collectVCStageSaveTargets(contentPath:String, targets:Array<Dynamic>, found:Map<String, Bool>, parentName:String) {
	if (contentPath == null || !FileSystem.exists(contentPath) || !FileSystem.isDirectory(contentPath))
		return;

	try {
		for (folder in FileSystem.readDirectory(contentPath)) {
			var packPath = contentPath + "/" + folder;
			if (FileSystem.isDirectory(packPath)) {
				var packName = parentName.length > 0 ? parentName + "/" + folder : folder;
				addVCStageSaveTarget(targets, found, packName, packPath);
				collectVCStageSaveTargets(packPath + "/content", targets, found, packName);
			}
		}
	} catch(e:Dynamic) {}
}

function addVCStageSaveTarget(targets:Array<Dynamic>, found:Map<String, Bool>, label:String, root:String) {
	if (root == null || root.length <= 0)
		return;

	var normalized = normalizeVCPath(root);
	if (found.exists(normalized))
		return;

	found.set(normalized, true);
	targets.push({label: label, root: normalized});
}

function getVCCurrentSaveRoot():String {
	if (vcOriginalSaveRoot == null)
		vcOriginalSaveRoot = normalizeVCPath(Paths.getAssetsRoot());
	return vcOriginalSaveRoot;
}

function getVCModRoot():String {
	var normalized = normalizeVCPath(Paths.getAssetsRoot());
	var contentIndex = normalized.indexOf("/content/");
	if (contentIndex >= 0)
		return normalized.substr(0, contentIndex);
	return normalized;
}

function getVCCurrentStageSavePath():String {
	return getVCCurrentSaveRoot() + "/data/stages/" + getVCStageFileName() + ".xml";
}

function getVCStageFileName():String {
	try {
		var name = Reflect.field(StageEditor, "__stage");
		if (name != null && Std.string(name).length > 0)
			return Std.string(name);
	} catch(e:Dynamic) {}

	var editor = StageEditor.instance;
	if (editor != null && editor.stage != null && editor.stage.stageName != null && editor.stage.stageName.length > 0)
		return editor.stage.stageName;
	return "stage";
}

function normalizeVCPath(path:String):String {
	if (path == null)
		return "";
	var normalized = path.split("\\").join("/");
	while (StringTools.endsWith(normalized, "/"))
		normalized = normalized.substr(0, normalized.length - 1);
	return normalized;
}

function toggleVCPreviewPanel() {
	vcPreviewPanelVisible = !vcPreviewPanelVisible;
	for (i in 1...vcPreviewPanel.length) {
		vcPreviewPanel[i].visible = vcPreviewPanelVisible;
		vcPreviewPanel[i].active = vcPreviewPanelVisible;
	}
}

function resetVCPreviewCharacter(charKey:String) {
	var fallback = switch(charKey) {
		case "NO_DELETE_boyfriend": Flags.DEFAULT_CHARACTER;
		case "NO_DELETE_girlfriend": Flags.DEFAULT_GIRLFRIEND;
		default: Flags.DEFAULT_OPPONENT;
	}
	changeVCPreviewCharacter(charKey, fallback);
}

function changeVCPreviewCharacter(charKey:String, characterName:String) {
	var editor = StageEditor.instance;
	if (editor == null || editor.charMap == null || !editor.charMap.exists(charKey))
		return;

	var oldChar:Character = editor.charMap.get(charKey);
	if (oldChar == null || oldChar.extra == null)
		return;

	var button:StageCharacterButton = cast oldChar.extra.get(StageEditor.exID("button"));
	if (button == null)
		return;

	var slotName = getVCPreviewSlotName(charKey);
	var pose = getVCPreviewPose(editor, characterName, slotName);
	var memberIndex = editor.members.indexOf(oldChar);
	var charIndex = editor.chars.indexOf(oldChar);
	var wasSelected = editor.selection != null && editor.selection.contains(oldChar);
	var isPlayer = getVCPreviewFlip(charKey, pose);
	var newChar = new Character(oldChar.x, oldChar.y, characterName, isPlayer, true);
	newChar.name = oldChar.name;
	newChar.debugMode = true;
	newChar.visible = oldChar.visible;
	newChar.alpha = 0.75;

	for (key in oldChar.extra.keys()) {
		if (key != vcStageEditorOffsetID)
			newChar.extra.set(key, oldChar.extra.get(key));
	}
	newChar.extra.set("voiidStageEditorPreviewCharacter", characterName);

	applyVCPreviewStagePosition(newChar, oldChar, pose);
	playVCStageEditorPreviewAnim(newChar);

	editor.remove(oldChar, true);
	if (memberIndex >= 0)
		editor.insert(memberIndex, newChar);
	else
		editor.add(newChar);

	if (charIndex >= 0)
		editor.chars[charIndex] = newChar;
	else
		editor.chars.push(newChar);

	editor.charMap.set(charKey, newChar);
	if (editor.xmlMap != null) {
		editor.xmlMap.remove(oldChar);
		editor.xmlMap.set(newChar, button.xml);
	}

	button.char = newChar;
	newChar.extra.set(StageEditor.exID("button"), button);

	if (wasSelected) {
		editor.selection.remove(oldChar);
		editor.selection.push(newChar);
		button.selected = true;
		newChar.extra.set(StageEditor.exID("selected"), true);
	}

	button.updateInfo();
	oldChar.destroy();
	applyVCStageEditorOffsets();
}

function getVCPreviewSlotName(charKey:String):String {
	return switch(charKey) {
		case "NO_DELETE_boyfriend": "boyfriend";
		case "NO_DELETE_girlfriend": "girlfriend";
		default: "dad";
	}
}

function getVCPreviewPose(editor:StageEditor, characterName:String, slotName:String):Dynamic {
	if (editor == null || editor.stage == null || editor.stage.characterPoses == null)
		return null;
	if (editor.stage.characterPoses.exists(characterName))
		return editor.stage.characterPoses.get(characterName);
	if (editor.stage.characterPoses.exists(slotName))
		return editor.stage.characterPoses.get(slotName);
	return null;
}

function getVCPreviewFlip(charKey:String, pose:Dynamic):Bool {
	if (pose != null) {
		try {
			return pose.flipX;
		} catch(e:Dynamic) {}
	}
	return charKey == "NO_DELETE_boyfriend";
}

function applyVCPreviewStagePosition(char:Character, oldChar:Character, pose:Dynamic) {
	char.setPosition(oldChar.x, oldChar.y);
	char.scale.set(oldChar.scale.x, oldChar.scale.y);
	char.scrollFactor.set(oldChar.scrollFactor.x, oldChar.scrollFactor.y);
	char.cameraOffset.set(oldChar.cameraOffset.x, oldChar.cameraOffset.y);
	char.skew.set(oldChar.skew.x, oldChar.skew.y);
	char.angle = oldChar.angle;
}

function playVCStageEditorPreviewAnim(char:Character) {
	try {
		var order = char.getAnimOrder();
		if (order != null && order.length > 0) {
			var animToPlay = order[0];
			char.playAnim(animToPlay, true);
			char.stopAnimation();
		} else {
			char.dance();
			char.stopAnimation();
		}
	} catch(e:Dynamic) {}
}

function getVCCharacterPacks():Array<Dynamic> {
	if (vcCharacterPacks != null)
		return vcCharacterPacks;

	var packs:Array<Dynamic> = [];
	var foundPackPaths:Map<String, Bool> = [];

	for (assetsRoot in getVCAssetsRoots()) {
		addVCCharacterPack(packs, foundPackPaths, "Main", assetsRoot + "/data/characters");
		collectVCContentCharacterPacks(assetsRoot + "/content", packs, foundPackPaths, "");
	}

	if (packs.length <= 0)
		packs.push({name: "Empty", chars: []});

	vcCharacterPacks = packs;
	return vcCharacterPacks;
}

function getVCAssetsRoots():Array<String> {
	var roots:Array<String> = [];
	var normalized = Paths.getAssetsRoot().split("\\").join("/");
	var contentIndex = normalized.indexOf("/content/");
	if (contentIndex >= 0)
		addVCAssetsRoot(roots, normalized.substr(0, contentIndex));
	else
		addVCAssetsRoot(roots, normalized);

	return roots;
}

function addVCAssetsRoot(roots:Array<String>, root:String) {
	if (root == null || root.length <= 0)
		return;

	var normalized = root.split("\\").join("/");
	while (StringTools.endsWith(normalized, "/"))
		normalized = normalized.substr(0, normalized.length - 1);

	if (roots.indexOf(normalized) < 0)
		roots.push(normalized);
}

function collectVCContentCharacterPacks(contentPath:String, packs:Array<Dynamic>, foundPackPaths:Map<String, Bool>, parentName:String) {
	if (contentPath == null || !FileSystem.exists(contentPath) || !FileSystem.isDirectory(contentPath))
		return;

	try {
		for (folder in FileSystem.readDirectory(contentPath)) {
			var packPath = contentPath + "/" + folder;
			if (FileSystem.isDirectory(packPath)) {
				var packName = parentName.length > 0 ? parentName + "/" + folder : folder;
				addVCCharacterPack(packs, foundPackPaths, packName, packPath + "/data/characters");
				collectVCContentCharacterPacks(packPath + "/content", packs, foundPackPaths, packName);
			}
		}
	} catch(e:Dynamic) {}
}

function addVCCharacterPack(packs:Array<Dynamic>, foundPackPaths:Map<String, Bool>, packName:String, charsPath:String) {
	if (charsPath == null || !FileSystem.exists(charsPath) || !FileSystem.isDirectory(charsPath))
		return;

	var normalized = charsPath.split("\\").join("/");
	if (foundPackPaths.exists(normalized))
		return;

	var found:Map<String, Bool> = [];
	var chars:Array<String> = [];
	collectVCCharacters(charsPath, found, chars);
	if (chars.length <= 0)
		return;

	chars.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
	foundPackPaths.set(normalized, true);
	packs.push({name: packName, chars: chars});
}

function collectVCCharacters(path:String, found:Map<String, Bool>, list:Array<String>) {
	if (path == null || !FileSystem.exists(path))
		return;

	if (FileSystem.isDirectory(path)) {
		try {
			for (file in FileSystem.readDirectory(path)) {
				var fullPath = path + "/" + file;
				if (FileSystem.isDirectory(fullPath)) {
					collectVCCharacters(fullPath, found, list);
				} else if (Path.extension(file).toLowerCase() == "xml") {
					var name = Path.withoutExtension(Path.withoutDirectory(file));
					if (!found.exists(name)) {
						found.set(name, true);
						list.push(name);
					}
				}
			}
		} catch(e:Dynamic) {}
	}
}

function refreshVCStageEditorCharacter(char) {
	try {
		if (char.animation != null && char.animation.curAnim != null) {
			var animName = char.animation.curAnim.name;
			char.playAnim(animName, true);
			char.stopAnimation();
		} else {
			char.dance();
			char.stopAnimation();
		}
	} catch(e:Dynamic) {}

	try {
		StageEditor.calcSpriteBounds(char);
	} catch(e:Dynamic) {}
}
