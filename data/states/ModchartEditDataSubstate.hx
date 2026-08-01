
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UISprite;
import haxe.io.Path;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIColorwheel;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIAutoCompleteTextBox;
import funkin.backend.utils.IniUtil;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import flixel.math.FlxMath;
import haxe.xml.Printer;
import Xml;

import funkin.backend.MusicBeatGroup;



class ModchartEditUIButtonList extends UIWindow {
	public var buttons:MusicBeatGroup = new MusicBeatGroup();
	public var draggingButton:ModchartEditButton = null;
	public var dragOffsetY:Float = 0;

	public var addButtons = [];
	public function setupAddButton(text, callback) {
		var addButton = new UIButton(25, 16, text, null, Std.int(this.buttonSize.x));
		addButton.autoAlpha = false;
		addButton.color = 0xFF00FF00;
		addButton.cameras = [buttonCameras];
		addButton.callback = callback;

		addButton.field.fieldWidth = 0;

		var addIcon = new FlxSprite(addButton.x + addButton.bHeight / 2, addButton.y + (32/2) - 8).loadGraphic(Paths.image('editors/charter/add-button'));
		addIcon.antialiasing = false;
		addButton.members.push(addIcon);
		members.push(addButton);

		addButtons.push({
			button: addButton,
			icon: addIcon
		});
	}

	public var buttonCameras:FlxCamera;
	public var cameraSpacing = 30;

	public var buttonSpacing:Float = 16;
	public var buttonSize:FlxPoint = FlxPoint.get();
	public var buttonOffset:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, width:Int, height:Int, windowName:String, buttonSize:FlxPoint, ?buttonOffset:FlxPoint, ?buttonSpacing:Float) {
		if (buttonSpacing != null) this.buttonSpacing = buttonSpacing;
		this.buttonSize = buttonSize;
		if (buttonOffset != null) this.buttonOffset = buttonOffset;
		super(x, y, width, height, windowName);

		buttonCameras = new FlxCamera(Std.int(x), Std.int(y+cameraSpacing), width, height-cameraSpacing-1);
		FlxG.cameras.add(buttonCameras, false);
		buttonCameras.bgColor = 0;

		members.push(buttons);
		nextscrollY = buttonCameras.scroll.y = -this.buttonSpacing;
	}

	public function add(button:T) {
		button.ID = buttons.members.length;
		buttons.add(button);
		nextscrollY += button.bHeight;
	}

	public function insert(button:T, position:Int) {
		button.ID = position;
		buttons.insert(position, button);
		nextscrollY += button.bHeight;
	}

	public function remove(button:T) {
		nextscrollY -= button.bHeight;
		buttons.members.remove(button);
		
	}

	public function beginDrag(button:ModchartEditButton) {
		if (draggingButton != null) return;

		var mousePos = FlxG.mouse.getWorldPosition(buttonCameras, FlxPoint.get());
		draggingButton = button;
		dragOffsetY = mousePos.y - button.y;
		button.dragging = true;
		button.alpha = 0.85;
		mousePos.put();
	}

	public function updateDrag() {
		if (draggingButton == null) return;

		if (!FlxG.mouse.pressed) {
			draggingButton.dragging = false;
			draggingButton.alpha = 1;
			draggingButton = null;
			return;
		}

		var mousePos = FlxG.mouse.getWorldPosition(buttonCameras, FlxPoint.get());
		var mouseViewY = mousePos.y - buttonCameras.scroll.y;
		var maxY:Float = 0;
		for (button in buttons.members) {
			if (button == null) continue;
			maxY += button.bHeight + buttonSpacing;
		}

		if (mouseViewY < 36) {
			buttonCameras.scroll.y = FlxMath.bound(buttonCameras.scroll.y - 12, -buttonSpacing, Math.max(maxY - buttonCameras.height, -buttonSpacing));
			mousePos.y = mouseViewY + buttonCameras.scroll.y;
		} else if (mouseViewY > buttonCameras.height - 36) {
			buttonCameras.scroll.y = FlxMath.bound(buttonCameras.scroll.y + 12, -buttonSpacing, Math.max(maxY - buttonCameras.height, -buttonSpacing));
			mousePos.y = mouseViewY + buttonCameras.scroll.y;
		}

		var targetIndex = 0;
		var layoutY:Float = buttonOffset.y;

		for (button in buttons.members) {
			if (button == null || button == draggingButton) continue;

			if (mousePos.y > layoutY + (button.bHeight / 2))
				targetIndex++;

			layoutY += button.bHeight + buttonSpacing;
		}

		var currentIndex = buttons.members.indexOf(draggingButton);
		if (targetIndex != currentIndex) {
			remove(draggingButton);
			insert(draggingButton, Std.int(FlxMath.bound(targetIndex, 0, buttons.members.length)));
		}

		draggingButton.y = mousePos.y - dragOffsetY;
		mousePos.put();
	}

	public function updateButtonsPos(elapsed:Float) {
		updateDrag();

		var yVal = 0;
		for (i => button in buttons.members) {
			if (button == null) continue;

			button.cameras = [buttonCameras];

			var targetX = (bWidth/2) - (buttonSize.x/2) + buttonOffset.x;
			if (button == draggingButton) {
				button.x = targetX;
			} else {
				button.setPosition(
					targetX,
					CoolUtil.fpsLerp(button.y, yVal + buttonOffset.y, 0.25));
			}

			yVal += (button.bHeight+buttonSpacing);
		}

		for (data in addButtons) {

			data.button.setPosition(
				(bWidth/2) - (buttonSize.x/2) + buttonOffset.x,
				CoolUtil.fpsLerp(data.button.y, yVal + buttonOffset.y, 0.25));

			data.button.field.offset.x = -(data.button.bWidth / 2 - data.button.field.width / 2);
			data.icon.x = (data.button.x + data.button.bWidth / 2 - data.icon.width / 2) - (data.button.field.width/2) - 12;
			data.icon.y = data.button.y + data.button.bHeight / 2 - data.icon.height / 2;

			data.button.selectable = (hovered);

			yVal += (data.button.bHeight+buttonSpacing);
		}


	}
	public var nextscrollY:Float = 0;
	public override function update(elapsed:Float) {
		updateButtonsPos(elapsed);

		super.update(elapsed);

		var maxY = 0;
		if (addButtons.length > 0) {
			maxY = (addButtons[addButtons.length-1].button.y + 32 + (buttonSpacing*1.5));
		} else {
			for (i => button in buttons.members) {
				if (button == null) continue;

				maxY += (button.bHeight+buttonSpacing);
			}
		}

		nextscrollY = FlxMath.bound(buttonCameras.scroll.y - (hovered ? FlxG.mouse.wheel : 0) * 32, -buttonSpacing, Math.max(maxY - buttonCameras.height, -buttonSpacing));

		buttonCameras.scroll.y = nextscrollY;
		

		if (__lastDrawCameras[0] != null) {
			buttonCameras.height = bHeight - cameraSpacing - 1; 
			buttonCameras.x = __lastDrawCameras[0].x + x - __lastDrawCameras[0].scroll.x;
			buttonCameras.y = __lastDrawCameras[0].y + y + cameraSpacing - __lastDrawCameras[0].scroll.y;
			buttonCameras.zoom = __lastDrawCameras[0].zoom;
		}
	}

	
	public function actuallydestroy() {

		if(buttonCameras != null) {
			if (FlxG.cameras.list.contains(buttonCameras))
				FlxG.cameras.remove(buttonCameras);
			buttonCameras = null;
		}
	}
}

// Legacy modcharts describe their editable items as Init/Event entries. This
// adapter exposes those entries through the same UI contract used by the
// modern Shader/Modifier item scripts without converting the XML format.
class LegacyModchartItemScript {
	public var eventType:String;

	public function new(eventType:String) {
		this.eventType = eventType;
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic {
		switch (func) {
			case "isEditable": return true;
			case "isLegacyEditable": return true;
			case "getLegacyEventType": return eventType;
			case "getXMLNodeName": return "Event";
			case "getEditButtonText": return getEditButtonText();
			case "setupItemData": setupItemData(args[0], args[1]); return null;
			case "setupDefaultItemData": setupDefaultItemData(args[0]); return null;
			case "getAvailableFiles": return getAvailableFiles();
			case "getEditDisplayName": return getEditDisplayName();
			case "getFolderDisplayName": return getFolderDisplayName();
			case "setupEditMenu": setupEditMenu(args[0], args[1]); return null;
			case "updateMenuPositions": updateMenuPositions(args[0]); return null;
			case "getMenuHeight": return getMenuHeight();
			case "getBaseWindowHeight": return getBaseWindowHeight();
			case "updateEditItem": updateEditItem(args[0], args[1]); return null;
			case "setDataValues": setDataValues(args[0], args[1]); return null;
			case "createNodeFromData": return createNodeFromData(args[0]);
		}
		return null;
	}

	function saveOriginalAttributes(data:Dynamic, node:Xml) {
		data.originalAttributes = [];
		for (attribute in node.attributes()) {
			data.originalAttributes.push({name: attribute, value: node.get(attribute)});
		}
	}

	function restoreOriginalAttributes(data:Dynamic, node:Xml) {
		if (data.originalAttributes == null) return;
		for (attribute in data.originalAttributes)
			node.set(attribute.name, attribute.value);
	}

	function setupItemData(data:Dynamic, node:Xml) {
		saveOriginalAttributes(data, node);
		data.eventType = eventType;
		switch (eventType) {
			case "initShader":
				data.file = node.get("shader");
			case "setCameraShader":
				data.file = node.get("camera");
			case "setShaderProperty":
				data.file = node.get("property");
				data.valueString = node.get("value");
				data.value = Std.parseFloat(data.valueString);
				data.valueIsNumeric = !Math.isNaN(data.value);
			case "initModifier":
				data.file = node.get("code");
				data.value = Std.parseFloat(node.get("value"));
				data.strumLineID = node.exists("strumLineID") ? Std.parseInt(node.get("strumLineID")) : -1;
				data.strumID = node.exists("strumID") ? node.get("strumID") : "-1";
		}
	}

	function setupDefaultItemData(data:Dynamic) {
		data.eventType = eventType;
		data.originalAttributes = [];
		data.file = "";
		data.value = 0;
		data.valueString = "0";
		data.valueIsNumeric = true;
		data.strumLineID = -1;
		data.strumID = "-1";
	}

	function getAvailableFiles():Array<String> {
		if (eventType == "setCameraShader") return ["game", "hud", "other"];
		if (eventType != "initShader") return [];

		var files:Array<String> = [];
		for (path in Paths.getFolderContent('shaders/legacy/', true, null)) {
			var extension = Path.extension(path).toLowerCase();
			if (extension == "frag" || extension == "vert") {
				var file = CoolUtil.getFilename(path);
				if (!files.contains(file)) files.push(file);
			}
		}
		return files;
	}

	function getEditButtonText():String {
		switch (eventType) {
			case "initShader": return "Add Legacy Shader";
			case "setCameraShader": return "Add Legacy Camera Binding";
			case "setShaderProperty": return "Add Legacy Shader Property";
			case "initModifier": return "Add Legacy Modifier";
		}
		return "Add Legacy Item";
	}

	function getEditDisplayName():String {
		switch (eventType) {
			case "initShader": return "Legacy Shader";
			case "setCameraShader": return "Legacy Camera Binding";
			case "setShaderProperty": return "Legacy Shader Property";
			case "initModifier": return "Legacy Modifier";
		}
		return "Legacy Item";
	}

	function getFolderDisplayName():String {
		switch (eventType) {
			case "initShader": return "(shaders/legacy/)";
			case "setCameraShader": return "(game / hud / other)";
			case "setShaderProperty": return "(property name)";
			case "initModifier": return "(inline code)";
		}
		return "";
	}

	function setupEditMenu(data:Dynamic, itemButton:Dynamic) {
		if (eventType == "setShaderProperty") {
			var valueInput:Dynamic = data.valueIsNumeric
				? new UINumericStepper(16, 100, data.value, 0, 6, null, null, 200)
				: new UITextBox(16, 100, data.valueString, 200);
			itemButton.addLabelOn(valueInput, "Default Value");
			itemButton.members.push(valueInput);
			itemButton.menuObjects.set("valueInput", valueInput);
		} else if (eventType == "initModifier") {
			var valueInput = new UINumericStepper(16, 100, data.value, 0, 6, null, null, 200);
			itemButton.addLabelOn(valueInput, "Default Value");
			itemButton.members.push(valueInput);
			itemButton.menuObjects.set("valueInput", valueInput);

			var strumLineIDInput = new UINumericStepper(16, 166, data.strumLineID, 0, 0, -1, null, 200);
			itemButton.addLabelOn(strumLineIDInput, "StrumLine ID (-1 = all)");
			itemButton.members.push(strumLineIDInput);
			itemButton.menuObjects.set("strumLineIDInput", strumLineIDInput);

			var strumIDInput = new UITextBox(16, 232, data.strumID, 200);
			itemButton.addLabelOn(strumIDInput, "Strum ID (-1 = all)");
			itemButton.members.push(strumIDInput);
			itemButton.menuObjects.set("strumIDInput", strumIDInput);
		}
	}

	function updateMenuPositions(itemButton:Dynamic) {
		if (eventType == "setShaderProperty") {
			itemButton.follow(itemButton, itemButton.menuObjects.get("valueInput"), 16, 100);
		} else if (eventType == "initModifier") {
			itemButton.follow(itemButton, itemButton.menuObjects.get("valueInput"), 16, 100);
			itemButton.follow(itemButton, itemButton.menuObjects.get("strumLineIDInput"), 16, 166);
			itemButton.follow(itemButton, itemButton.menuObjects.get("strumIDInput"), 16, 232);
		}
	}

	function getMenuHeight():Int {
		if (eventType == "initModifier") return 298;
		if (eventType == "setShaderProperty") return 166;
		return 100;
	}

	function getBaseWindowHeight():Int {
		if (eventType == "initModifier") return 340;
		if (eventType == "setShaderProperty") return 250;
		return 220;
	}

	function updateEditItem(data:Dynamic, itemButton:Dynamic) {
		switch (eventType) {
			case "initShader":
				var basePath = "shaders/legacy/" + data.file;
				var exists = Assets.exists(basePath + ".frag") || Assets.exists(basePath + ".vert") || Assets.exists(basePath + ".FRAG");
				itemButton.descText.text = exists || data.file == "" ? "Legacy shader file" : '"' + data.file + '" could not be found!';
			case "setCameraShader":
				itemButton.descText.text = "Attach the named legacy shader to this camera.";
			case "setShaderProperty":
				itemButton.descText.text = "Set a legacy shader property before timeline events run.";
			case "initModifier":
				itemButton.descText.text = "Inline legacy modifier code.";
		}
	}

	function commitStepper(stepper:Dynamic) {
		stepper.__onChange(stepper.label.text);
	}

	function setDataValues(data:Dynamic, itemButton:Dynamic) {
		if (eventType == "setShaderProperty") {
			var valueInput = itemButton.menuObjects.get("valueInput");
			if (data.valueIsNumeric) {
				commitStepper(valueInput);
				data.value = valueInput.value;
				data.valueString = Std.string(data.value);
			} else {
				data.valueString = valueInput.label.text;
			}
		} else if (eventType == "initModifier") {
			var valueInput = itemButton.menuObjects.get("valueInput");
			var strumLineIDInput = itemButton.menuObjects.get("strumLineIDInput");
			commitStepper(valueInput);
			commitStepper(strumLineIDInput);
			data.value = valueInput.value;
			data.strumLineID = Std.int(strumLineIDInput.value);
			data.strumID = itemButton.menuObjects.get("strumIDInput").label.text;
		}
	}

	function createNodeFromData(data:Dynamic):Xml {
		var node = Xml.createElement("Event");
		restoreOriginalAttributes(data, node);
		node.set("type", eventType);
		node.set("name", data.name);

		switch (eventType) {
			case "initShader":
				node.set("shader", data.file);
			case "setCameraShader":
				node.set("camera", data.file);
			case "setShaderProperty":
				node.set("property", data.file);
				node.set("value", data.valueIsNumeric ? data.value : data.valueString);
			case "initModifier":
				node.set("code", data.file);
				node.set("value", data.value);
				if (data.strumLineID >= 0) node.set("strumLineID", data.strumLineID);
				else node.remove("strumLineID");
				if (data.strumID != null && data.strumID != "" && data.strumID != "-1") node.set("strumID", data.strumID);
				else node.remove("strumID");
		}
		return node;
	}
}

class ModchartEditButton extends UIButton {
	public var topText:UIText;
	public var itemDisplayName:String = "";
	public var expandButton:UIButton;

	public var nameInput:UITextBox;
	public var fileInput:UIAutoCompleteTextBox;
	public var descText:UIText;

	public var menuObjects = ["" => null];
	
	public var colorInput:UIColorwheel;

	public var shiftUpButton:UIButton;
	public var shiftDownButton:UIButton;
	public var dragHandle:UIButton;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public var labels = [];

	public var xml = null;

	public var expanded = false;
	public var dragging = false;

	public var itemData = {
		name: "",
		type: "modifier",
		color: 0xFF545454,		
		file: ""
	}
	public var modList = [];

	public function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
		var uiText:UIText = new UIText(ui.x, ui.y - 24, 0, text, size);
		members.push(uiText); labels.push([ui, uiText]);
		return uiText;
	}

	public var script = null;
	public var itemList = null;

	public function new(id, modType, node, list, scr) {
		super(0, 0, '', function () {}, 928, 280);
		script = scr;
		itemList = list;

		if (node != null) {
			itemData.name = node.get("name");
			itemData.type = modType;

			script.call("setupItemData", [itemData, node]);

			if (node.exists("color"))
				itemData.color = FlxColor.fromString(node.get("color"));
		} else {
			itemData.type = modType;
			script.call("setupDefaultItemData", [itemData]);
		}
		
		field.text = "";
		resize(928, 280);

		autoAlpha = false; 
		frames = Paths.getFrames('editors/ui/inputbox');

		modList = script.call("getAvailableFiles", []);

		itemDisplayName = script.call("getEditDisplayName", []);
		var folderDisplayName = script.call("getFolderDisplayName", []);

		topText = new UIText(16, 12, 0, itemData.name + " (" + itemDisplayName + ")");
		members.push(topText);

		expandButton = new UIButton(16, 12, "↑", function () {
			expanded = !expanded;
			updateExpand();
		}, 32, 24);
		members.push(expandButton);

		shiftDownButton = new UIButton(16, 12, "↓", function () {
			var currentIndex = itemList.buttons.members.indexOf(this);
			if (currentIndex < itemList.buttons.members.length-1) {
				itemList.remove(this);
				itemList.insert(this, currentIndex + 1);
			}
		}, 32, 24);
		members.push(shiftDownButton);

		shiftUpButton = new UIButton(16, 12, "↑", function () {
			var currentIndex = itemList.buttons.members.indexOf(this);
			if (currentIndex > 0) {
				itemList.remove(this);
				itemList.insert(this, currentIndex - 1);
			}
		}, 32, 24);
		members.push(shiftUpButton);

		dragHandle = new UIButton(16, 12, "|||", function () {}, 44, 24);
		dragHandle.shouldPress = false;
		dragHandle.autoAlpha = false;
		dragHandle.color = 0xFF606060;
		dragHandle.hoverCallback = function() {
			if (FlxG.mouse.justPressed && !expanded)
				itemList.beginDrag(this);
		};
		members.push(dragHandle);


		nameInput = new UITextBox(16, 34, itemData.name, 200);
		addLabelOn(nameInput, itemDisplayName + " Name");
		members.push(nameInput);

		fileInput = new UIAutoCompleteTextBox(16 + 216, 34, itemData.file, 200, 32, modList);
		fileInput.suggestItems = modList;
		addLabelOn(fileInput, itemDisplayName + " File " + folderDisplayName);
		members.push(fileInput);

		fileInput.onChange = function(newfile) {
			if (itemData.file != newfile) {
				itemData.file = newfile;
				updateMod();
			}
		}

		descText = new UIText(16 + 216, 100, 300, "test");
		members.push(descText);

		menuObjects.clear();
		script.call("setupEditMenu", [itemData, this]);

		colorInput = new UIColorwheel(560, 34, itemData.color);
		addLabelOn(colorInput, "Editor Color");
		members.push(colorInput);

		deleteButton = new UIButton(16, 280-32-11, "", function () {
			itemList.remove(this);
			this.destroy();
		}, 64);
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + ((deleteButton.bWidth/2)-(15/2)), deleteButton.y + ((deleteButton.bHeight/2)-(16/2))).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);

		updateMod();
	}

	public function follow(parent, obj, X, Y) {
		obj.x = parent.x + X;
		obj.y = parent.y + Y;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		follow(this, topText, 16, 10);
		follow(this, expandButton, 880, 8);
		follow(this, dragHandle, 832, 8);

		if (expanded) {
			dragHandle.visible = false;
			dragHandle.selectable = false;

			follow(this, nameInput, 16, 34);
			follow(this, fileInput, 232, 34);
			follow(this, descText, 232, 100-24);

			var lastHeight = script.call("getMenuHeight", []);
			script.call("updateMenuPositions", [this]);

			for (obj in extraValues) {
				follow(this, obj, 16, lastHeight);
				lastHeight += 66;
			}

			follow(this, colorInput, 560, 34);
			fixColorWheelPos(colorInput);

			follow(this, deleteButton, 16, bHeight-32-11);
			follow(this, deleteIcon, 16 + ((deleteButton.bWidth/2)-(15/2)), (bHeight-32-11) + ((deleteButton.bHeight/2)-(16/2)));

			for (shit in labels) {
				follow(shit[0], shit[1], 0, -24);
				shit[1].visible = expanded;
			}
			for (i => label in extraLabels) {
				follow(extraValues[i], label, 0, -24);
				label.visible = expanded;
			}
		} else {
			dragHandle.visible = true;
			dragHandle.selectable = true;
			shiftDownButton.visible = shiftUpButton.visible = this.hoveredByChild || dragging;
			if (hoveredByChild || dragging) {
				follow(this, shiftDownButton, 880-80, 8);
				follow(this, shiftUpButton, 880-120, 8);
				follow(this, dragHandle, 832, 8);
				shiftDownButton.selectable = itemList.buttons.members.indexOf(this) < itemList.buttons.members.length-1;
				shiftUpButton.selectable = itemList.buttons.members.indexOf(this) > 0;
			}
		}
	}

	public var extraValuesList = []; 
	public var extraValues = [];
	public var extraLabels = [];

	public function updateMod() {
		script.call("updateEditItem", [itemData, this]);
		updateExpand();
	}

	public function getHeight() {
		var h = script.call("getBaseWindowHeight", []);
		h += extraValuesList.length * 66;
		return h;
	}

	public function updateExpand() {
		if (expanded) {
			resize(bWidth, getHeight());
		} else {
			resize(bWidth, 40);
		}

		var expandedItems = [nameInput, fileInput, descText, colorInput, deleteButton, deleteIcon];
		for (name => obj in menuObjects) {
			expandedItems.push(obj);
		}
		for (obj in extraValues) {
			expandedItems.push(obj);
		}
		for (obj in extraLabels) {
			expandedItems.push(obj);
		}

		for (item in expandedItems) {
			if (item is UISprite) {
				item.selectable = expanded;
			}
			if (item is UIColorwheel) {
				for (thing in item.rgbNumSteppers) thing.selectable = expanded;
				item.colorHexTextBox.selectable = expanded;
			}
			item.visible = expanded;
		}

		expandButton.field.text = expanded ? "↑" : "<";
		topText.visible = shiftDownButton.visible = shiftUpButton.visible = dragHandle.visible = shiftDownButton.selectable = shiftUpButton.selectable = !expanded;
		dragHandle.selectable = !expanded;
		topText.text = nameInput.label.text + " (" + itemDisplayName + ")";

		for (shit in labels) {
			shit[1].visible = expanded;
		}
	}

	public function fixColorWheelPos(wheel) {
		wheel.colorPicker.setPosition(wheel.x + 12.5, (wheel.y + 125/2) - (100/2));
		wheel.colorSlider.setPosition(wheel.colorPicker.x + 100 + 12.5, wheel.colorPicker.y);
		wheel.colorHexTextBox.setPosition(wheel.colorSlider.x + 16 + 12.5, wheel.colorSlider.y + 16);

		for (i in 0...3) { 
			wheel.members[i].setPosition(wheel.colorSlider.x + 18 + 12.5 + (i * 44), wheel.colorHexTextBox.y + 28 + 6 + 13 + 6 + 0.5);
		}
		wheel.updateColorPickerSelector();
		wheel.updateColorSliderPickerSelector();

		wheel.members[wheel.members.length-2].setPosition(wheel.colorHexTextBox.x - 2, wheel.colorHexTextBox.y - 18); 
		wheel.members[wheel.members.length-1].setPosition(wheel.rgbNumSteppers[0].x - 2, wheel.rgbNumSteppers[0].y - 18); 
	}

	public function saveToNode() {
		itemData.name = nameInput.label.text;
		itemData.file = fileInput.label.text;
		itemData.color = colorInput.curColor;
		itemData.colorString = colorInput.curColorString;
		script.call("setDataValues", [itemData, this]);

		return script.call("createNodeFromData", [itemData]);
	}
}

var itemList = null;
var stageHueHUDCheckbox:UICheckbox = null;
var legacyEditScripts = ["" => null];
var normalEditScripts = ["" => null];
var itemInitLayout = [];

function getStageHueHUDSetting():Bool {
	if (CURRENT_XML == null) return false;
	if (CURRENT_XML.exists("stageHueCamHUD"))
		return CURRENT_XML.get("stageHueCamHUD") == "true";

	// Compatibility with the short-lived item-based version of this option.
	for (list in CURRENT_XML.elementsNamed("Init")) {
		for (node in list.elementsNamed("StageHue")) {
			if (node.exists("camHUD") && node.get("camHUD") == "true") return true;
		}
	}
	return false;
}

function cloneItemXMLNode(node:Xml):Xml {
	if (node == null) return null;
	return Xml.parse(node.toString()).firstElement();
}

function create() {
	winTitle = "Edit Modchart Data";
	winWidth = 960;
}

function postCreate() {

	itemList = new ModchartEditUIButtonList(windowSpr.x + 16, windowSpr.y + 64, 928, 420, "", FlxPoint.get(928, 280), FlxPoint.get(0, 0), 0);
	itemList.frames = Paths.getFrames('editors/ui/inputbox');
	itemList.cameraSpacing = 0;

	if (ITEM_EDIT_IS_LEGACY) {
		legacyEditScripts.clear();
		for (eventType in ["initShader", "setCameraShader", "setShaderProperty", "initModifier"]) {
			var itemScript = new LegacyModchartItemScript(eventType);
			var itemName = "legacy_" + eventType;
			legacyEditScripts.set(eventType, itemScript);
			itemList.setupAddButton(itemScript.call("getEditButtonText", []), function() {
				itemList.add(new ModchartEditButton(itemList.buttons.length, itemName, null, itemList, itemScript));
			});
		}
	} else {
		normalEditScripts.clear();
		for (name => script in ITEM_EDIT_LOADED_SCRIPTS) {
			if (script.call("isEditable", []) == true) {
				var itemScript = script;
				var itemName = name;
				normalEditScripts.set(script.call("getXMLNodeName", []), {name: itemName, script: itemScript});
				itemList.setupAddButton(script.call("getEditButtonText", []), function() {
					itemList.add(new ModchartEditButton(itemList.buttons.length, itemName, null, itemList, itemScript));
				});
			}
		}
	}

	ITEM_EDIT_PRESERVED_INIT_NODES = [];
	itemInitLayout = [];
	if (ITEM_EDIT_IS_LEGACY) {
		for (list in CURRENT_XML.elementsNamed("Init")) {
			for (node in list.elements()) {
				var eventType = node.nodeName == "Event" ? node.get("type") : null;
				var script = eventType == null ? null : legacyEditScripts.get(eventType);
				if (script != null) {
					itemInitLayout.push({editable: true, node: null});
					itemList.add(new ModchartEditButton(itemList.buttons.length, "legacy_" + eventType, node, itemList, script));
				} else {
					// Never discard an Init entry just because this version of the
					// editor does not know how to expose it.
					var preservedNode = cloneItemXMLNode(node);
					ITEM_EDIT_PRESERVED_INIT_NODES.push(preservedNode);
					itemInitLayout.push({editable: false, node: preservedNode});
				}
			}
		}
	} else {
		for (list in CURRENT_XML.elementsNamed("Init")) {
			for (node in list.elements()) {
				var editData = normalEditScripts.get(node.nodeName);
				if (editData != null) {
					itemInitLayout.push({editable: true, node: null});
					itemList.add(new ModchartEditButton(itemList.buttons.length, editData.name, node, itemList, editData.script));
				} else {
					var preservedNode = cloneItemXMLNode(node);
					ITEM_EDIT_PRESERVED_INIT_NODES.push(preservedNode);
					itemInitLayout.push({editable: false, node: preservedNode});
				}
			}
		}
	}

	add(itemList);

	if (!ITEM_EDIT_IS_LEGACY) {
		stageHueHUDCheckbox = new UICheckbox(
			windowSpr.x + 20,
			windowSpr.y + windowSpr.bHeight - 16 - 32,
			"Apply Stage Hue to HUD Camera?",
			getStageHueHUDSetting()
		);
		add(stageHueHUDCheckbox);
	}

	var saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
		save();
		close();
		ITEM_EDIT_SAVE_CALLBACK();
	});
	saveButton.x -= saveButton.bWidth;
	add(saveButton);

	var closeButton = new UIButton(saveButton.x - 10, saveButton.y, "Close", function() {
		close();
	});
	closeButton.color = 0xFFFF0000;
	closeButton.x -= closeButton.bWidth;
	add(closeButton);
}

function save() {
	if (!ITEM_EDIT_IS_LEGACY && CURRENT_XML != null && stageHueHUDCheckbox != null)
		CURRENT_XML.set("stageHueCamHUD", stageHueHUDCheckbox.checked ? "true" : "false");

	var initEvents = Xml.createElement("Init");
	var savedNodes = [];
	for (button in itemList.buttons.members) {
		savedNodes.push(button.saveToNode());
	}

	var savedIndex = 0;
	for (slot in itemInitLayout) {
		if (slot.editable) {
			if (savedIndex < savedNodes.length)
				initEvents.addChild(savedNodes[savedIndex++]);
		} else if (slot.node != null) {
			initEvents.addChild(cloneItemXMLNode(slot.node));
		}
	}
	while (savedIndex < savedNodes.length)
		initEvents.addChild(savedNodes[savedIndex++]);
	ITEM_EDIT_SAVED_INIT_EVENTS = initEvents;
}

function destroy() {
	itemList.actuallydestroy();
}
