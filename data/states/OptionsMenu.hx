import funkin.options.type.TextOption;
import funkin.options.TreeMenuScreen;
import funkin.options.keybinds.ChangeKeybindSubState;
import flixel.input.gamepad.FlxGamepadInputID;
import funkin.backend.MusicBeatSubstate;
import flixel.input.keyboard.FlxKey;
import haxe.io.Path;
import funkin.backend.scripting.Script;
import haxe.xml.Access;
import haxe.xml.Parser;
import haxe.xml.Printer;
import Xml;

public static var multikeyControlsCallback = null;
public static var multikeyControlsCancelCallback = null;
public static var multikeyRebindController = false;

function create()
{
	importScript("data/scripts/controlsCheck.hx");
}
var firstFrame = true;
function update(elapsed) {
	if (firstFrame) {
		generateMenu();
		firstFrame = false;
	}
}
var keyCountMenuNames = [];
var keyOptionsData = [];
function generateMenu()
{

    //
    //custom menu shits

	var xmlPath = Paths.xml('multikeyData');
	if (!Assets.exists(xmlPath))
	{
		trace('multikey data is missing!');
		return;
	}
	var plainXML = Assets.getText(xmlPath);
	var mainXML = Xml.parse(plainXML);



	var kc = 0;
	//get menu data
	for (keyData in mainXML.elementsNamed("defaultBinds"))
	{
		for (keyGroup in keyData.elementsNamed("keyGroup"))
		{
			var knum = 0;
			keyCountMenuNames.push(keyGroup.get("name"));
			keyOptionsData.push([]);
			for (key in keyGroup.elementsNamed("key")) //get key data
			{
				keyOptionsData[kc].push([key.get("name"), (kc+1)+"k"+knum]);
				knum++;
			}
			kc++;
		}
	}
	kc = 0; 
	//now need to get the note anim
	for (keyData in mainXML.elementsNamed("keyData"))
	{
		for (keyGroup in keyData.elementsNamed("keyGroup"))
		{
			var knum = 0;
			for (key in keyGroup.elementsNamed("key")) //get key data
			{
				keyOptionsData[kc][knum].push(key.get("note"));
				knum++;
			}
			kc++;
		}
	}

	var main = tree[0];

	if (Reflect.field(FlxG.save.data, "voiidModcharts") == null) {
		Reflect.setField(FlxG.save.data, "voiidModcharts", true);
		FlxG.save.flush();
	}
	if (Reflect.field(FlxG.save.data, "voiidAltNoteTypeTextures") == null) {
		Reflect.setField(FlxG.save.data, "voiidAltNoteTypeTextures", false);
		FlxG.save.flush();
	}
	if (Reflect.field(FlxG.save.data, "voiidPunchCenterScreen") == null) {
		Reflect.setField(FlxG.save.data, "voiidPunchCenterScreen", false);
		FlxG.save.flush();
	}
	if (Reflect.field(FlxG.save.data, "voiidBotplay") == null) {
		Reflect.setField(FlxG.save.data, "voiidBotplay", true);
		FlxG.save.flush();
	}
	if (Reflect.field(FlxG.save.data, "voiidNoMechanics") == null) {
		Reflect.setField(FlxG.save.data, "voiidNoMechanics", false);
		FlxG.save.flush();
	}
	if (Reflect.field(FlxG.save.data, "voiidNoDeath") == null) {
		Reflect.setField(FlxG.save.data, "voiidNoDeath", false);
		FlxG.save.flush();
	}

	main.add(new TextOption("Voiid Gameplay", "", " >", function() {
		var menu = new TreeMenuScreen("Voiid Gameplay", "");
		menu.add(createToggleOption("Botplay", "voiidBotplay", updateBotplayOptionText));
		menu.add(createToggleOption("No mechanics", "voiidNoMechanics", updateNoMechanicsOptionText));
		menu.add(createToggleOption("Modcharts", "voiidModcharts", updateModchartsOptionText));
		menu.add(createToggleOption("No death", "voiidNoDeath", updateNoDeathOptionText));
		menu.add(createToggleOption("Punch position", "voiidPunchCenterScreen", updatePunchPositionOptionText));
		menu.add(createToggleOption("Alt note type textures", "voiidAltNoteTypeTextures", updateAltNoteTypeTexturesOptionText));
		addMenu(menu);
	}));

	main.add(new TextOption("Multikey Controls", "", " >", function() {
		var mkMenu = new TreeMenuScreen("Multikey Controls", "");

		var keyboardOption = new TextOption("Keyboard", "", " >", function() {
			
			var keyCountMenus = [];
			var i = 0;
			for (menuData in keyOptionsData)
			{
				var menuName = keyCountMenuNames[i];
				if (i != 3) //ignore 4k
				{
					//submenu for each key count
					var option = new TextOption(menuName, "", " >", function()
					{
						//create options
						var subOptions = [];
						for (optionData in menuData)
							subOptions.push(setupOption(optionData[0], optionData[1], optionData[2]));
						for (optionData in menuData)
							subOptions.push(setupOption(optionData[0] + " P2", optionData[1]+"p2", optionData[2]));
		
						var subMenu = new TreeMenuScreen(menuName, "");
						for (o in subOptions) subMenu.add(o);
						addMenu(subMenu);
					});
					keyCountMenus.push(option);
				}
				i++;
			}

			var menu = new TreeMenuScreen("Keyboard", "");
			for (o in keyCountMenus) menu.add(o);
			addMenu(menu);
		});
		mkMenu.add(keyboardOption);

		///////////////////
		var gamepadOption = new TextOption("Gamepad", "", " >", function() {
			
			var keyCountMenus = [];
			var i = 0;
			for (menuData in keyOptionsData)
			{
				var menuName = keyCountMenuNames[i];
				if (i != 3) //ignore 4k
				{
					//submenu for each key count
					var option = new TextOption(menuName, "", " >", function()
					{
						//create options
						var subOptions = [];
						for (optionData in menuData)
							subOptions.push(setupOptionGamepad(optionData[0], optionData[1]+"gamepad", optionData[2]));
						for (optionData in menuData)
							subOptions.push(setupOptionGamepad(optionData[0] + " P2", optionData[1]+"gamepadP2", optionData[2]));
		
						var subMenu = new TreeMenuScreen(menuName, "");
						for (o in subOptions) subMenu.add(o);
						addMenu(subMenu);
					});
					keyCountMenus.push(option);
				}
				i++;
			}

			var menu = new TreeMenuScreen("Gamepad", "");
			for (o in keyCountMenus) menu.add(o);
			addMenu(menu);
		});
		mkMenu.add(gamepadOption);
	
        addMenu(mkMenu);
	}));
}

function updateModchartsOptionText(option:TextOption) {
	var enabled = Reflect.field(FlxG.save.data, "voiidModcharts") != false;
	option.text = "Modcharts: " + (enabled ? "ON" : "OFF");
}

function updateAltNoteTypeTexturesOptionText(option:TextOption) {
	var enabled = Reflect.field(FlxG.save.data, "voiidAltNoteTypeTextures") == true;
	option.text = "Alt note type textures: " + (enabled ? "ON" : "OFF");
}

function updatePunchPositionOptionText(option:TextOption) {
	var centerScreen = Reflect.field(FlxG.save.data, "voiidPunchCenterScreen") == true;
	option.text = "Punch position: " + (centerScreen ? "SCREEN" : "STRUMLINE");
}

function updateBotplayOptionText(option:TextOption) {
	var enabled = Reflect.field(FlxG.save.data, "voiidBotplay") == true;
	option.text = "Botplay: " + (enabled ? "ON" : "OFF");
}

function updateNoMechanicsOptionText(option:TextOption) {
	var enabled = Reflect.field(FlxG.save.data, "voiidNoMechanics") == true;
	option.text = "No mechanics: " + (enabled ? "ON" : "OFF");
}

function updateNoDeathOptionText(option:TextOption) {
	var enabled = Reflect.field(FlxG.save.data, "voiidNoDeath") == true;
	option.text = "No death: " + (enabled ? "ON" : "OFF");
}

function createToggleOption(name:String, savePath:String, updateText:Dynamic):TextOption {
	var option:TextOption;
	option = new TextOption("", "", "", function() {
		var enabled = Reflect.field(FlxG.save.data, savePath) == true;
		Reflect.setField(FlxG.save.data, savePath, !enabled);
		FlxG.save.flush();
		updateText(option);
	});
	option.__text.font = "normal";
	updateText(option);
	return option;
}

function setupOption(name:String, savePath:String, arrow:String)
{
    var option:TextOption;
    option = new TextOption("", "", "", function()
    {
        openKeybindMenu(option, name, savePath, false);
    });
    option.__text.font = "normal";
    option.text = name + ": " + CoolUtil.keyToString(Reflect.getProperty(FlxG.save.data, savePath));
    option.__text.y -= 30;
	option.__text.x += 75;

    //arrow icon
    var icon = new FlxSprite();
    icon.frames = Paths.getFrames("game/notes/default");
    icon.antialiasing = true;
    icon.animation.addByPrefix('icon', arrow + "0", 24, true);
    icon.animation.play('icon');
    icon.setGraphicSize(75, 75);
    icon.updateHitbox();
    var min = Math.min(icon.scale.x, icon.scale.y);
    icon.scale.set(min, min);
    option.add(icon);

    return option;
}

function setupOptionGamepad(name:String, savePath:String, arrow:String)
{
	var option:TextOption;
	option = new TextOption("", "", "", function()
	{
		openKeybindMenu(option, name, savePath, true);
	});
	option.__text.font = "normal";
	var bind = FlxGamepadInputID.toStringMap.get(Reflect.getProperty(FlxG.save.data, savePath));
	option.text = name + ": " + (bind == null ? "---" : getGamepadName(bind));
    option.__text.y -= 30;
	option.__text.x += 75;

	//arrow icon
	var icon = new FlxSprite();
	icon.frames = Paths.getFrames("game/notes/default");
	icon.antialiasing = true;
	icon.animation.addByPrefix('icon', arrow + "0", 24, true);
	icon.animation.play('icon');
	icon.setGraphicSize(75, 75);
	icon.updateHitbox();
	var min = Math.min(icon.scale.x, icon.scale.y);
	icon.scale.set(min, min);
	option.add(icon);

	return option;
}

function openKeybindMenu(option:TextOption, name:String, savePath:String, gamepad:Bool)
{
    persistentUpdate = false;
	multikeyRebindController = gamepad;

	var s = new MusicBeatSubstate(true, "MultikeyChangeBindSubstate");
	openSubState(s);
	

	multikeyControlsCallback = function(key:FlxKey)
	{
		Reflect.setProperty(FlxG.save.data, savePath, key);
        FlxG.save.flush();
		if (gamepad)
		{
			var bind = FlxGamepadInputID.toStringMap.get(Reflect.getProperty(FlxG.save.data, savePath));
			option.text = name + ": " + (bind == null ? "---" : getGamepadName(bind));
		}
		else
		{
			option.text = name + ": " + CoolUtil.keyToString(Reflect.getProperty(FlxG.save.data, savePath));
		}
		multikeyControlsCallback = null;
		multikeyControlsCancelCallback = null;
	};
	multikeyControlsCancelCallback = function()
	{
        Reflect.setProperty(FlxG.save.data, savePath, 0);
        FlxG.save.flush();
		if (gamepad)
		{
			var bind = FlxGamepadInputID.toStringMap.get(Reflect.getProperty(FlxG.save.data, savePath));
			option.text = name + ": " + (bind == null ? "---" : getGamepadName(bind));
		}
		else
		{
			option.text = name + ": " + CoolUtil.keyToString(Reflect.getProperty(FlxG.save.data, savePath));
		}
		multikeyControlsCallback = null;
		multikeyControlsCancelCallback = null;
	};
}

function getGamepadName(bind) {
    switch(bind) {
        case "LEFT_STICK_DIGITAL_UP": return "LS UP";
        case "LEFT_STICK_DIGITAL_DOWN": return "LS DOWN";
        case "LEFT_STICK_DIGITAL_LEFT": return "LS LEFT";
        case "LEFT_STICK_DIGITAL_RIGHT": return "LS RIGHT";
        case "RIGHT_STICK_DIGITAL_UP": return "RS UP";
        case "RIGHT_STICK_DIGITAL_DOWN": return "RS DOWN";
        case "RIGHT_STICK_DIGITAL_LEFT": return "RS LEFT";
        case "RIGHT_STICK_DIGITAL_RIGHT": return "RS RIGHT";

        case "LEFT_SHOULDER": return "LB";
        case "RIGHT_SHOULDER": return "RB";

        case "LEFT_STICK_CLICK": return "LS CLICK";
        case "RIGHT_STICK_CLICK": return "RS CLICK";

    }

    return bind;
}
