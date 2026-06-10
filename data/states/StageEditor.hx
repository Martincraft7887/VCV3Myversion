import funkin.editors.stage.StageEditor;
import funkin.editors.stage.elements.StageCharacterButton;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIDropDown;
import funkin.game.Character;
import funkin.backend.system.Flags;
import haxe.io.Path;
import sys.FileSystem;

var vcStageEditorOffsetID:String = "voiidLECharacterOffsetApplied";
var vcPreviewPanel:Array<Dynamic> = [];
var vcPreviewPanelVisible:Bool = true;
var vcCharacterList:Array<String> = null;

function postCreate() {
	createVCPreviewPanel();
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

	var chars = getVCCharacterList();
	var y = 34;
	var toggle = new UIButton(8, y, "Voiid preview", function() {
		toggleVCPreviewPanel();
	}, 126, 28);
	addVCPreviewControl(toggle);

	makeVCPreviewDropdown("dad", "NO_DELETE_dad", 8, y + 34, chars);
	makeVCPreviewDropdown("bf", "NO_DELETE_boyfriend", 8, y + 70, chars);
	makeVCPreviewDropdown("gf", "NO_DELETE_girlfriend", 8, y + 106, chars);
}

function addVCPreviewControl(control:Dynamic) {
	var editor = StageEditor.instance;
	if (editor != null && editor.uiCamera != null)
		control.cameras = [editor.uiCamera];
	vcPreviewPanel.push(control);
	add(control);
}

function makeVCPreviewDropdown(label:String, charKey:String, x:Float, y:Float, chars:Array<String>) {
	var options = [label + ": default"].concat(chars);
	var dropdown = new UIDropDown(x, y, 230, 28, options, 0);
	dropdown.onChange = function(i) {
		if (i <= 0)
			resetVCPreviewCharacter(charKey);
		else
			changeVCPreviewCharacter(charKey, dropdown.options[i]);
	};
	addVCPreviewControl(dropdown);
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
	if (oldChar == null)
		return;

	var button:StageCharacterButton = cast oldChar.extra.get(StageEditor.exID("button"));
	if (button == null)
		return;

	var slotName = getVCPreviewSlotName(charKey);
	var pose = getVCPreviewPose(editor, characterName, slotName);
	var memberIndex = editor.members.indexOf(oldChar);
	var charIndex = editor.chars.indexOf(oldChar);
	var wasSelected = editor.selection.contains(oldChar);
	var isPlayer = pose != null ? pose.flipX : charKey == "NO_DELETE_boyfriend";
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
	editor.xmlMap.remove(oldChar);
	editor.xmlMap.set(newChar, button.xml);

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

function applyVCPreviewStagePosition(char:Character, oldChar:Character, pose:Dynamic) {
	if (pose != null) {
		pose.prepareCharacter(char, 0);
		return;
	}

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

function getVCCharacterList():Array<String> {
	if (vcCharacterList != null)
		return vcCharacterList;

	var found:Map<String, Bool> = [];
	var list:Array<String> = [];
	var roots = [
		Paths.getAssetsRoot() + "/data/characters",
		Paths.getAssetsRoot() + "/images/characters",
		Paths.getAssetsRoot() + "/content"
	];

	for (root in roots)
		collectVCCharacters(root, found, list);

	list.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
	vcCharacterList = list;
	return vcCharacterList;
}

function collectVCCharacters(path:String, found:Map<String, Bool>, list:Array<String>) {
	if (path == null || !FileSystem.exists(path))
		return;

	if (FileSystem.isDirectory(path)) {
		for (file in FileSystem.readDirectory(path)) {
			var fullPath = path + "/" + file;
			if (FileSystem.isDirectory(fullPath)) {
				var normalized = fullPath.split("\\").join("/");
				if (normalized.indexOf("/data/characters") >= 0 || normalized.indexOf("/images/characters") >= 0 || normalized.indexOf("/content/") >= 0)
					collectVCCharacters(fullPath, found, list);
			} else if (Path.extension(file).toLowerCase() == "xml") {
				var normalizedFile = fullPath.split("\\").join("/");
				if (normalizedFile.indexOf("/data/characters/") >= 0) {
					var name = Path.withoutExtension(Path.withoutDirectory(file));
					if (!found.exists(name)) {
						found.set(name, true);
						list.push(name);
					}
				}
			}
		}
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
