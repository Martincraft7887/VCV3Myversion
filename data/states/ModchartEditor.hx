//
import funkin.editors.ui.UISliceSprite;
import funkin.game.HudCamera;
import funkin.menus.FreeplayState;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIFileExplorer;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UISprite;
import funkin.editors.ui.UISlider;
import funkin.editors.ui.UIUtil;
import funkin.editors.ui.UIContextMenu;
import funkin.editors.ui.UIState;
import haxe.io.Path;
import funkin.editors.ui.UITopMenu;
import funkin.editors.ui.UISubstateWindow;
import funkin.backend.utils.SortedArrayUtil;
import flixel.input.keyboard.FlxKey;
import funkin.backend.utils.ShaderResizeFix;
import flixel.addons.display.FlxBackdrop;
import funkin.editors.charter.CharterQuantButton;
import openfl.ui.MouseCursor;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import haxe.xml.Printer;
import funkin.game.Stage;
import funkin.backend.MusicBeatGroup;
import funkin.editors.EditorTreeMenu;
import funkin.game.Character;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import Xml;
import ModchartEventObjects;
import UIScrollBarHorizontal;

public static var CURRENT_EVENT = null; //event used by edit substate
public static var EVENT_EDIT_EVENT_SCRIPT = null;
public static var EVENT_EDIT_CALLBACK:Void->Void = null;
public static var EVENT_EDIT_CANCEL_CALLBACK:Void->Void = null;
public static var EVENT_DELETE_CALLBACK:Void->Void = null;

public static var ITEM_EDIT_LOADED_SCRIPTS = ["" => null];
public static var ITEM_EDIT_SAVE_CALLBACK:Void->Void = null;
public static var ITEM_EDIT_SAVED_INIT_EVENTS = null;

public static var CURRENT_XML:Xml;
var dragStartPos = null;
var isDragging = false;

var isDraggingStage:Bool = false;
var stagePanLastMouse:FlxPoint = null;
var editorCamZoom:Float = 1;
inline static var EDITOR_CAM_ZOOM_MIN:Float = 0.25;
inline static var EDITOR_CAM_ZOOM_MAX:Float = 3;
function destroy() {
	CURRENT_EVENT = null;
	EVENT_EDIT_EVENT_SCRIPT = null;
	EVENT_EDIT_CALLBACK = null;
	EVENT_EDIT_CANCEL_CALLBACK = null;
	EVENT_DELETE_CALLBACK = null;
	ITEM_EDIT_SAVE_CALLBACK = null;
	ITEM_EDIT_SAVED_INIT_EVENTS = null;
	ITEM_EDIT_LOADED_SCRIPTS = null;
	CURRENT_XML = null;
}

public var eventScripts = ["" => null];
public var itemScripts = ["" => null];

var legacyShaderRoot:String = "legacy/";
var legacyShaders = ["" => null];
var legacyNoteModchart:Bool = false;
var legacyEditorRuntime = null;

function ensureLegacyEditorRuntime() {
	if (legacyEditorRuntime == null)
		legacyEditorRuntime = importScript("data/scripts/modchartEditorLegacyRuntime.hx");
	return legacyEditorRuntime;
}

function applyLegacyModifierValue(name:String, value:Float) {
	var rt = ensureLegacyEditorRuntime();
	if (rt != null)
		rt.call("setModifierValue", [name, value]);
}

function updateLegacyModifierItem(item, i:Int) {
	var text = timelineUIList[i].valueText;
	if (text != null) {
		text.text = Std.string(FlxMath.roundDecimal(item.currentValue, 2));
	}
	applyLegacyModifierValue(item.object, item.currentValue);
}

public function callItemScriptFromItem(item, func, args) {
	if (item.type == "legacyModifier" && func == "updateItem") {
		updateLegacyModifierItem(args[0], args[1]);
		return;
	}
	var script = itemScripts.get(item.type);
	if (script != null) {
		script.call(func, args);
	}
}

public function callEventScriptFromItem(item, func, args) {
	//items could technically support multiple types of event based on the name
	var script = eventScripts.get(callItemScriptFromItem(item, "getEventNameFromItem", [item]));
	if (script != null) {
		script.call(func, args);
	}
}

public function callEventScriptFromEvent(e, func, args) {
	var script = eventScripts.get(e.type);
	if (script != null) {
		script.call(func, args);
	}
}

/*
{
	name: "",
	type: "",
	defaultValue: 0,
	currentValue: 0,
	lastValue: -9999
	property: "",
	object: null //shader/modifier/whatever idk
}
*/
public var timelineItems = [];
public var timelineIndexMap = ["" => -1];
public function createTimelineItem(name, type, object) {
	if (timelineIndexMap.exists(name)) {
		trace("duplicate timeline item?");
	}
	var timelineItem = {
		name: name,
		type: type,
		defaultValue: 0,
		currentValue: 0,
		lastValue: Math.NEGATIVE_INFINITY,
		property: "",
		object: object
	}
	timelineItems.push(timelineItem);
	timelineList.push(name);
	timelineIndexMap.set(name, timelineItems.length-1);
	return timelineItem;
}
var eventRenderer = null;
var eventIndexList = [0];
var events = [];

//array<String>
public var timelineList = [];

/*
{
	bg: null,
	nameText: null,
	valueText: null
}
*/
public var timelineUIList = [];

/*
{
	startIndex: -1,
	endIndex: 0,
	color: -1,
	bg: null
}
*/
public var timelineGroups = [];

public var timelineUIBG = new MusicBeatGroup();
public var timelineUINameText = new MusicBeatGroup();
public var timelineUIValueText = new MusicBeatGroup();

var conductorSprY:Float = 0.0;
var vocals:FlxSound;

var songPosInfo:UIText;

public var camGame:FlxCamera;
public var camHUD:HudCamera;
public var camOther:FlxCamera;

var camEditor:FlxCamera;
var camEditorTop:FlxCamera;
var camTimelineList:FlxCamera;
var camTimelineValueList:FlxCamera;
var camTimeline:FlxCamera;

var scrollBar:UIScrollBarHorizontal;

var timelineWindow:UIWindow;
var beatSeparator:FlxBackdrop;
var sectionSeparator:FlxBackdrop;

var hoverBox:FlxSprite;

var stage:Stage;
var defaultCamZoom:Float = 1;
var stagePreviewMode = false;
var experimentalGameplayPreview:Bool = false;
var experimentalPreviewChars:Array<Dynamic> = [];
var experimentalPreviewCharGroups:Array<Dynamic> = [];
var experimentalPreviewCharData:Array<Dynamic> = [];
var experimentalPreviewNotes:Array<Dynamic> = [];
var experimentalNoteTypeData:Map<String, Dynamic> = [];
var experimentalPreviewNextNoteIndex:Int = 0;
var experimentalPreviewFirstRenderIndex:Int = 0;
var experimentalPreviewLastSongPosition:Float = Math.NEGATIVE_INFINITY;
var experimentalRTXData:Dynamic = null;
var experimentalRTXTargets:Array<Dynamic> = [];
var experimentalRTXShaders:Array<Dynamic> = [];
var experimentalRTXHue:Float = 0;
inline static var EXPERIMENTAL_PREVIEW_PAST_WINDOW:Float = 350;
inline static var EXPERIMENTAL_PREVIEW_FUTURE_WINDOW:Float = 2500;

var xml:Xml;

var ROW_SIZE_X = 20.0;
var ROW_SIZE_Y = 20.0;
var targetRowSizeX = 20.0;
var targetRowSizeY = 20.0;

function updateSize() {
	hoverBox.setGraphicSize(ROW_SIZE_Y,ROW_SIZE_Y);
	hoverBox.updateHitbox();

	for (i => ui in timelineUIList) {
		ui.bg.y = ROW_SIZE_Y*i;
		ui.nameText.y = ROW_SIZE_Y*i;
		ui.valueText.y = ROW_SIZE_Y*i;
	}
}

var topMenu = [];
var topMenuSpr = null;
var selectionBox:UISliceSprite;
var selectedEvents = [];
var clipboard = [];

var snapIndex:Int = 6;
public var quantButtons:Array<CharterQuantButton> = [];
public var quant:Int = 16;
public var quants:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

public var strumLines = [];
public var downscroll = Options.downscroll;

function postCreate() {

	eventScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartEvents/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			eventScripts.set(file, importScript("data/scripts/modchartEvents/" + file + ".hx"));
		}
	}

	itemScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartTimelineItems/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			itemScripts.set(file, importScript("data/scripts/modchartTimelineItems/" + file + ".hx"));
		}
	}

	topMenu = [
		{
			label: "File",
			childs: [
				{
					label: "Save",
					keybind: [FlxKey.CONTROL, FlxKey.S],
					onSelect: _save
				},
				/*{
					label: "Save (Optimized)",
					onSelect: _save_opt
				},*/
				null,
				{
					label: "Export Packaged Modchart",
					onSelect: _export_package
				},
				null,
				{
					label: "Exit",
					onSelect: _exit
				}
			]
		},
		{
			label: "Edit",
			childs: [
				/*{
					label: "Undo",
					keybind: [FlxKey.CONTROL, FlxKey.Z],
					onSelect: _edit_undo
				},
				{
					label: "Redo",
					keybinds: [[FlxKey.CONTROL, FlxKey.Y], [FlxKey.CONTROL, FlxKey.SHIFT, FlxKey.Z]],
					onSelect: _edit_redo
				},
				null,*/
				{
					label: "Copy",
					keybind: [FlxKey.CONTROL, FlxKey.C],
					onSelect: _edit_copy
				},
				{
					label: "Paste",
					keybind: [FlxKey.CONTROL, FlxKey.V],
					onSelect: _edit_paste
				},
				null,
				{
					label: "Cut",
					keybind: [FlxKey.CONTROL, FlxKey.X],
					onSelect: _edit_cut
				},
				{
					label: "Delete",
					keybind: [FlxKey.DELETE],
					onSelect: _edit_delete
				},
				null,
				{
					label: "Shift Selection Left",
					keybind: [FlxKey.SHIFT, FlxKey.LEFT],
					onSelect: _edit_shiftleft
				},
				{
					label: "Shift Selection Right",
					keybind: [FlxKey.SHIFT, FlxKey.RIGHT],
					onSelect: _edit_shiftright
				}
			]
		},
		{
			label: "Modchart",
			childs: [
				{
					label: "Edit Timeline Items",
					onSelect: _modchart_edititems
				}
			]
		},
		{
			label: "View",
			childs: [
				{
					label: "Fullscreen",
					keybind: [FlxKey.F],
					onSelect: _view_fullscreen
				},
				{
					label: "Reset Camera",
					keybind: [FlxKey.R],
					onSelect: _view_reset_camera
				},
				{
					label: "Reload Editor",
					keybind: [FlxKey.F6],
					onSelect: _view_reload_editor
				},
				{
					label: "Swap Scroll",
					onSelect: _view_downscroll
				},
				null,
				{
					label: "Experimental Gameplay Preview",
					onSelect: _view_experimental_gameplay_preview
				}
			]
		},
		{
			label: "Song",
			childs: [
				{
					label: "Go back to the start",
					keybind: [FlxKey.HOME],
					onSelect: _song_start
				},
				{
					label: "Go to the end",
					keybind: [FlxKey.END],
					onSelect: _song_end
				},
				null,
				{
					label: "Mute instrumental",
					onSelect: _song_muteinst
				},
				{
					label: "Mute voices",
					onSelect: _song_mutevoices
				}
			]
		},
		{
			label: "Playback",
			childs: [
				{
					label: "Play/Pause",
					keybind: [FlxKey.SPACE],
					onSelect: _playback_play
				},
				null,
				{
					label: "â†‘ Speed 25%",
					onSelect: _playback_speed_raise
				},
				{
					label: "Reset Speed",
					onSelect: _playback_speed_reset
				},
				{
					label: "â†“ Speed 25%",
					onSelect: _playback_speed_lower
				},
				null,
				{
					label: "Go back a section",
					keybind: [FlxKey.A],
					onSelect: _playback_back
				},
				{
					label: "Go forward a section",
					keybind: [FlxKey.D],
					onSelect: _playback_forward
				}
			]
		},
		{
			label: "Snap >",
			childs: [
				{
					label: "wha",
					onSelect: function() {}
				}
			]
		}
	];

	camGame = FlxG.camera;

	camHUD = new HudCamera();
	camHUD.bgColor = 0;
	camHUD.downscroll = downscroll;
	FlxG.cameras.add(camHUD);

	camOther = new FlxCamera();
	camOther.bgColor = 0;
	FlxG.cameras.add(camOther);

	camEditor = new FlxCamera();
	camEditor.bgColor = 0;
	FlxG.cameras.add(camEditor);

	camEditorTop = new FlxCamera();
	camEditorTop.bgColor = 0;
	FlxG.cameras.add(camEditorTop);

	topMenuSpr = new UITopMenu(topMenu);
	topMenuSpr.scrollFactor.set(1,1);
	topMenuSpr.cameras = [camEditorTop];
	add(topMenuSpr);

	quants.reverse();
	for (quant in quants) {
		var button = new CharterQuantButton(0, 0, quant);
		button.cameras = [camEditorTop];
		button.onClick = () -> {setquant(button.quant);};
		quantButtons.push(add(button));
	}
	quants.reverse();
	
	buildSnapsUI();

	camTimelineList = new FlxCamera(0, 720/2, 200, 720/2);
	camTimelineList.bgColor = 0;
	FlxG.cameras.add(camTimelineList);

	camTimelineValueList = new FlxCamera(200, 720/2, 50, 720/2);
	camTimelineValueList.bgColor = 0;
	FlxG.cameras.add(camTimelineValueList);

	camTimeline = new FlxCamera(250, 720/2, 1280-250, 720/2);
	camTimeline.bgColor = 0;
	FlxG.cameras.add(camTimeline);

	//bg = new FlxSprite();
	//bg.loadGraphic(Paths.image('menus/menuBG'));
	//bg.color = 0xFF777777;
	//add(bg);
	//bg.cameras = [camGame];

	if (PlayState.SONG.stage == null) PlayState.SONG.stage = "stage";
	stage = new Stage(PlayState.SONG.stage);
	for (obj in stage.stageSprites) {
		obj.cameras = [camGame];
	}
	if (stage.stageXML != null && stage.stageXML.exists("zoom")) {
		defaultCamZoom = Std.parseFloat(stage.stageXML.get("zoom"));
	}
	editorCamZoom = defaultCamZoom;

	FlxG.mouse.visible = true;

	createStrumlines();

	songPosInfo = new UIText(FlxG.width - 30 - 400, 35, 400, "00:00\nBeat: 0\nStep: 0\nMeasure: 0\nBPM: 0\nTime Signature: 4/4");
	songPosInfo.alignment = "right";
	songPosInfo.cameras = [camEditor];
	songPosInfo.scrollFactor.set(0,0);
	if (!stagePreviewMode) add(songPosInfo);

	timelineWindow = new UIWindow(0,720-320, 1280,320, "Timeline");
	timelineWindow.cameras = [camEditor];
	add(timelineWindow);
	
	scrollBar = new UIScrollBarHorizontal();
	scrollBar.newnew(250, timelineWindow.y+5, 1000, 0, 10, 1280-270, 20);
	scrollBar.cameras = [camEditor];
	scrollBar.onChange = function(v) {
		if (!FlxG.sound.music.playing)
			Conductor.songPosition = Conductor.getTimeForStep(v) + Conductor.songOffset;
	}
	add(scrollBar);

	hoverBox = new FlxSprite(-100,0);
	hoverBox.makeGraphic(1,1);
	hoverBox.setGraphicSize(ROW_SIZE_X,ROW_SIZE_Y);
	hoverBox.updateHitbox();
	hoverBox.cameras = [camTimeline];
	
	loadSong();
	loadEvents(false);
	buildXMLFromEvents();

	var valueBG = new FlxSprite(0,0);
	valueBG.makeGraphic(1,1);
	valueBG.setGraphicSize(50,1280);
	valueBG.updateHitbox();
	valueBG.color = 0xff302e32;
	valueBG.cameras = [camTimelineValueList];
	valueBG.scrollFactor.set();
	add(valueBG);

	timelineUIBG.cameras = [camTimeline, camTimelineList, camTimelineValueList];
	timelineUIBG.scrollFactor.set(0, 1);
	add(timelineUIBG);
	timelineUINameText.cameras = [camTimelineList];
	add(timelineUINameText);
	timelineUIValueText.cameras = [camTimelineValueList];
	add(timelineUIValueText);
	createTimelineUI();

	var line = new FlxSprite(200-2,0);
	line.makeGraphic(1,1);
	line.setGraphicSize(2,1280);
	line.updateHitbox();
	line.cameras = [camTimelineList];
	line.scrollFactor.set();
	add(line);

	var line2 = new FlxSprite(50-2,0);
	line2.makeGraphic(1,1);
	line2.setGraphicSize(2,1280);
	line2.updateHitbox();
	line2.cameras = [camTimelineValueList];
	line2.scrollFactor.set();
	add(line2);

	sectionSeparator = new FlxBackdrop(null, FlxAxes.X, 0, 0);
	sectionSeparator.x = -2;

	beatSeparator = new FlxBackdrop(null, FlxAxes.X, 0, 0);
	beatSeparator.x = -1;

	for(sep in [sectionSeparator, beatSeparator]) {
		sep.makeSolid(1, 1, -1);
		sep.alpha = 0.5;
		sep.scrollFactor.set(1, 0);
		sep.scale.set(sep == sectionSeparator ? 4 : 2, 720/2);
		sep.cameras = [camTimeline];
		sep.updateHitbox();
	}
	add(beatSeparator);
	add(sectionSeparator);

	add(hoverBox);

	eventRenderer = new EventRenderer();
	add(eventRenderer);
	eventRenderer.cameras = [camTimeline];

	selectionBox = new UISliceSprite(0, 0, 2, 2, 'editors/ui/selection');
	selectionBox.visible = false;
	selectionBox.scrollFactor.set(1, 1);
	selectionBox.incorporeal = true;
	selectionBox.cameras = [camTimeline];
	add(selectionBox);

	endStagePan();
	initEditorCamera();
}

function createTimelineUI() {
	timelineUIBG.clear();
	timelineUINameText.clear();
	timelineUIValueText.clear();
	timelineUIList = [];

	for (i => name in timelineList) {
		var bg = new FlxSprite(0,(ROW_SIZE_Y*i));
		bg.makeGraphic(1,1);
		bg.setGraphicSize(1280,ROW_SIZE_Y);
		bg.updateHitbox();
		bg.cameras = [camTimeline, camTimelineList, camTimelineValueList];
		bg.scrollFactor.set(0, 1);
		bg.color = i % 2 == 1 ? 0xFF272727 : 0xFF545454;
		timelineUIBG.add(bg);

		var text = new UIText(10, (ROW_SIZE_Y*i),0, name, 15);
		text.cameras = [camTimelineList];
		timelineUINameText.add(text);

		var valueText = new UIText(10, (ROW_SIZE_Y*i),0, "-", 15);
		valueText.cameras = [camTimelineValueList];
		timelineUIValueText.add(valueText);

		timelineUIList.push({
			bg: bg,
			nameText: text,
			valueText: valueText
		});
	}

	for (grp in timelineGroups) {
		grp.bg = new FlxSprite(0, ROW_SIZE_Y * grp.startIndex);
		grp.bg.makeGraphic(1,1);
		grp.bg.setGraphicSize(1280, ROW_SIZE_Y * (grp.endIndex - grp.startIndex));
		grp.bg.updateHitbox();
		grp.bg.cameras = [camTimeline, camTimelineList, camTimelineValueList];
		grp.bg.scrollFactor.set(0, 1);
		grp.bg.color = grp.color;
		grp.bg.alpha = 0.15;
		timelineUIBG.add(grp.bg);
	}
}

public var multikeyScales:Array<Float> = [];
public var multikeyWidths:Array<Float> = [];
public var multikeyOffsets:Array<Float> = [];
public var multikeySingDirs = [];
public var multikeyStrumAnims = [];
public var multikeyNoteAnims = [];

function loadMultikeyData() {
	if (multikeyScales.length > 0) return;

	var xmlPath = Paths.xml("multikeyData");
	if (!Assets.exists(xmlPath)) {
		trace("multikeyData.xml missing!");
		return;
	}

	var mainXML = Xml.parse(Assets.getText(xmlPath));
	var kc = 0;

	for (keyData in mainXML.elementsNamed("keyData")) {
		for (keyGroup in keyData.elementsNamed("keyGroup")) {
			multikeyScales.push(Std.parseFloat(keyGroup.get("scale")));
			multikeyWidths.push(Std.parseFloat(keyGroup.get("gapWidth")));
			multikeyOffsets.push(Std.parseFloat(keyGroup.get("xOffset")));

			multikeySingDirs.push([]);
			multikeyStrumAnims.push([]);
			multikeyNoteAnims.push([]);

			for (key in keyGroup.elementsNamed("key")) {
				multikeySingDirs[kc].push(Std.parseInt(key.get("singDir")));
				multikeyStrumAnims[kc].push([
					key.get("strumStatic"),
					key.get("strumConfirm"),
					key.get("strumPress")
				]);
				multikeyNoteAnims[kc].push([
					key.get("note"),
					key.get("noteHold"),
					key.get("noteHoldEnd")
				]);
			}

			kc++;
		}
	}
}

function getExperimentalKeyCount(strumLineID:Int):Int {
	var keyCount:Int = 4;
	if (PlayState.SONG.strumLines != null && PlayState.SONG.strumLines[strumLineID] != null) {
		var sl = PlayState.SONG.strumLines[strumLineID];
		if (sl.keyCount != null)
			keyCount = sl.keyCount;
	}
	if (strumLines != null && strumLines[strumLineID] != null && strumLines[strumLineID].length > keyCount)
		keyCount = strumLines[strumLineID].length;
	if (keyCount < 1) keyCount = 1;
	return keyCount;
}

function getExperimentalKeyCountIndex(strumLineID:Int):Int {
	var kc:Int = getExperimentalKeyCount(strumLineID) - 1;
	if (kc < 0) kc = 0;
	if (multikeyScales.length > 0 && kc >= multikeyScales.length)
		kc = multikeyScales.length - 1;
	return kc;
}

function getExperimentalLane(strumLineID:Int, id:Int):Int {
	var keyCount:Int = getExperimentalKeyCount(strumLineID);
	var lane:Int = id % keyCount;
	if (lane < 0) lane += keyCount;
	return lane;
}

function getExperimentalSingDirection(strumLineID:Int, id:Int):Int {
	var kc:Int = getExperimentalKeyCountIndex(strumLineID);
	var lane:Int = getExperimentalLane(strumLineID, id);
	if (multikeySingDirs[kc] != null && multikeySingDirs[kc][lane] != null)
		return multikeySingDirs[kc][lane];
	return lane % 4;
}

function getExperimentalNoteAnim(strumLineID:Int, id:Int, part:Int):String {
	var fallback:Array<String> = ["purple0", "blue0", "green0", "red0"];
	var kc:Int = getExperimentalKeyCountIndex(strumLineID);
	var lane:Int = getExperimentalLane(strumLineID, id);
	if (multikeyNoteAnims[kc] != null && multikeyNoteAnims[kc][lane] != null && multikeyNoteAnims[kc][lane][part] != null)
		return multikeyNoteAnims[kc][lane][part];
	return fallback[lane % fallback.length];
}

function getExperimentalNoteScaleX(strumLineID:Int, strumScale:Float):Float {
	var kc:Int = getExperimentalKeyCountIndex(strumLineID);
	if (multikeyScales.length < 1) return strumScale;
	return multikeyScales[kc] * strumScale;
}

function getExperimentalSustainYOffset(strumLineID:Int):Float {
	var kc:Int = getExperimentalKeyCountIndex(strumLineID);
	var strumScale:Float = 1;
	if (PlayState.SONG.strumLines != null && PlayState.SONG.strumLines[strumLineID] != null && PlayState.SONG.strumLines[strumLineID].strumScale != null)
		strumScale = PlayState.SONG.strumLines[strumLineID].strumScale;
	if (multikeyWidths.length < 1) return Note.swagWidth / 2;
	return multikeyWidths[kc] * 0.7 * 0.5 * strumScale;
}

function loadExperimentalNoteTypeData() {
	if (experimentalNoteTypeData.exists("BoxingMatchPunch")) return;
	experimentalNoteTypeData.set("none", null);
	experimentalNoteTypeData.set("BoxingMatchPunch", {skin: "BoxingMatchPunch", animSuffix: "-dodge"});
	experimentalNoteTypeData.set("Wiik3Punch", {skin: "Wiik3Punch-Alt", animSuffix: "-dodge"});
	experimentalNoteTypeData.set("Wiik4Sword", {skin: "Wiik4Sword", animSuffix: "-dodge", offsetsY: [-10, -10, -10, -10], offsetsYDS: [-10, -10, -10, -10]});
	experimentalNoteTypeData.set("VoiidBullet", {skin: "VoiidBullet", animSuffix: "-dodge", offsetsX: [-25, -4, -7, 5], offsetsY: [0, 0, -32, 0], offsetsYDS: [-40, -30, 0, -40]});
	experimentalNoteTypeData.set("ParryNote", {skin: "ParryNote", animSuffix: "-dodge", offsetsY: [-165, -165, -165, -165], offsetsYDS: [-40, -40, -40, -40]});
	experimentalNoteTypeData.set("GreedPunch", {skin: "GreedPunch", animSuffix: "-dodge"});
	experimentalNoteTypeData.set("SwordGreen", {skin: "SwordGreen", animSuffix: "-dodge", offsetsY: [-10, -10, -10, -10], offsetsYDS: [-10, -10, -10, -10]});
	experimentalNoteTypeData.set("RejectedPunch", {skin: "RejectedPunch", animSuffix: "-dodge"});
	experimentalNoteTypeData.set("RejectedSword", {skin: "RejectedSword", animSuffix: "-dodge", offsetsY: [-10, -10, -10, -10], offsetsYDS: [-10, -10, -10, -10]});
	experimentalNoteTypeData.set("RejectedBullet", {skin: "RejectedBullet", animSuffix: "-dodge", offsetsX: [-25, -4, -7, 5], offsetsY: [0, 0, -32, 0], offsetsYDS: [-40, -30, 0, -40]});
	experimentalNoteTypeData.set("REJECTED_VIP_NOTES", {skin: "REJECTED_NOTES", offsetsY: [-145, -145, -145, -145], offsetsYDS: [-20, -20, -20, -20]});
	experimentalNoteTypeData.set("REJECTED_NOTES", {skin: "REJECTED_NOTES", offsetsY: [-145, -145, -145, -145], offsetsYDS: [-20, -20, -20, -20]});
	experimentalNoteTypeData.set("RevPunch", {skin: "RevPunchAlt", animSuffix: "-dodge"});
	experimentalNoteTypeData.set("RevSword", {skin: "RevSword", animSuffix: "-dodge", offsetsY: [-10, -10, -10, -10], offsetsYDS: [-10, -10, -10, -10]});
}

function getExperimentalNoteTypeName(noteData:Dynamic):String {
	var directType:Dynamic = Reflect.field(noteData, "noteType");
	if (directType != null) return StringTools.trim(Std.string(directType));

	var directTypeID:Dynamic = Reflect.field(noteData, "noteTypeID");
	if (directTypeID != null) {
		var parsedDirectID:Null<Int> = Std.parseInt(Std.string(directTypeID));
		if (parsedDirectID != null)
			return getExperimentalNoteTypeNameFromID(Std.int(parsedDirectID));
	}

	var type:Dynamic = Reflect.field(noteData, "type");
	if (type == null) return "none";
	var typeString = StringTools.trim(Std.string(type));
	var parsedStringID:Null<Int> = Std.parseInt(typeString);
	if (parsedStringID == null) return typeString;
	if (Std.string(parsedStringID) != typeString) return typeString;

	return getExperimentalNoteTypeNameFromID(Std.int(parsedStringID));
}

function getExperimentalNoteTypeNameFromID(typeID:Int):String {
	var chartNoteTypes:Dynamic = Reflect.field(PlayState.SONG, "noteTypes");
	if (chartNoteTypes != null && typeID > 0 && chartNoteTypes.length >= typeID)
		return Std.string(chartNoteTypes[typeID - 1]);
	return "none";
}

function getExperimentalNoteTypeBase(noteType:String):String {
	if (noteType == null) return "none";
	noteType = StringTools.trim(noteType);
	if (!StringTools.contains(noteType, "char[")) return noteType;
	var base = StringTools.trim(noteType.substring(0, noteType.indexOf("char[")));
	return base == "" ? "none" : base;
}

function getExperimentalNoteTypeData(noteType:String):Dynamic {
	loadExperimentalNoteTypeData();
	var base = getExperimentalNoteTypeBase(noteType);
	if (experimentalNoteTypeData.exists(base))
		return experimentalNoteTypeData.get(base);
	return null;
}

function createStrumlines() {
	loadMultikeyData();

	strumLines = [];

	for (i => strumLine in PlayState.SONG.strumLines) {
		if (strumLine == null) continue;

		var keyCount:Int = 4;

		if (strumLine.keyCount != null)
			keyCount = strumLine.keyCount;

		var kc:Int = keyCount - 1;

		if (kc < 0) kc = 0;
		if (kc >= multikeyScales.length)
			kc = multikeyScales.length - 1;

		var strumScale:Float = strumLine.strumScale == null ? 1 : strumLine.strumScale;

		var noteScale:Float = multikeyScales[kc];
		var spacing:Float = multikeyWidths[kc] * 0.7;
		var xOffset:Float = multikeyOffsets[kc];

		var strOffset:Float = strumLine.strumLinePos == null
			? (strumLine.type == 1 ? 0.75 : 0.25)
			: strumLine.strumLinePos;

		var startingPos:FlxPoint = strumLine.strumPos == null ?
			FlxPoint.get(
				(FlxG.width * strOffset) - ((Note.swagWidth * strumScale) * 2),
				50
			) :
			FlxPoint.get(
				strumLine.strumPos[0] == 0
					? ((FlxG.width * strOffset) - ((Note.swagWidth * strumScale) * 2))
					: strumLine.strumPos[0],
				strumLine.strumPos[1]
			);

		strumLines.push([]);

		if (strumLine.visible == false) continue;

		for (dir in 0...keyCount) {
			var babyArrow = new FlxSprite(
				startingPos.x + ((spacing * strumScale) * dir) + xOffset,
				startingPos.y
			);

			babyArrow.frames = Paths.getFrames("game/voiid/notes/default");
			babyArrow.antialiasing = true;

			var anims = multikeyStrumAnims[kc][dir];

			babyArrow.animation.addByPrefix("static", anims[0]);
			babyArrow.animation.addByPrefix("confirm", anims[1], 24, false);
			babyArrow.animation.addByPrefix("pressed", anims[2], 24, false);
			babyArrow.animation.play("static");

			babyArrow.setGraphicSize(
				Std.int(babyArrow.width * noteScale * strumScale)
			);

			babyArrow.updateHitbox();
			babyArrow.centerOffsets();
			babyArrow.centerOrigin();
			babyArrow.scrollFactor.set();
			babyArrow.cameras = [camHUD];
			babyArrow.ID = dir;

			if (!stagePreviewMode)
				add(babyArrow);

			strumLines[i].push(babyArrow);
		}
	}
}

function clearExperimentalGameplayPreview() {
	clearExperimentalRTXShaders();

	for (char in experimentalPreviewChars) {
		if (char != null) {
			remove(char, true);
			char.destroy();
		}
	}
	experimentalPreviewChars = [];
	experimentalPreviewCharGroups = [];
	experimentalPreviewCharData = [];

	for (data in experimentalPreviewNotes) {
		if (data != null && data.sprite != null) {
			remove(data.sprite, true);
			data.sprite.destroy();
		}
		if (data != null && data.sustain != null) {
			remove(data.sustain, true);
			data.sustain.destroy();
		}
		if (data != null && data.sustainEnd != null) {
			remove(data.sustainEnd, true);
			data.sustainEnd.destroy();
		}
		if (data != null && data.sustainBody != null) {
			remove(data.sustainBody, true);
			data.sustainBody.destroy();
		}
	}
	experimentalPreviewNotes = [];
	experimentalPreviewNextNoteIndex = 0;
	experimentalPreviewFirstRenderIndex = 0;
	experimentalPreviewLastSongPosition = Math.NEGATIVE_INFINITY;
}

function loadExperimentalRTX() {
	experimentalRTXData = readExperimentalRTXData(PlayState.SONG.stage);
	clearExperimentalRTXShaders();
	if (experimentalRTXData == null) return;

	var hueItem = getStageHueTimelineItem();
	if (hueItem != null) experimentalRTXHue = hueItem.currentValue;

	for (char in experimentalPreviewChars)
		applyExperimentalRTXToSprite(char);
}

function readExperimentalRTXData(stageName:String):Dynamic {
	if (stageName == null) return null;
	var path = Paths.file("data/stages/" + stageName + ".json");
	if (!Assets.exists(path)) return null;

	var text = Assets.getText(path);
	if (text != null && text.length > 0 && StringTools.fastCodeAt(text, 0) == 65279)
		text = text.substr(1);

	try {
		var parsed:Dynamic = Json.parse(text);
		return parsed == null ? null : Reflect.field(parsed, "rtxData");
	} catch(e:Dynamic) {
		return null;
	}
}

function clearExperimentalRTXShaders() {
	for (i in 0...experimentalRTXTargets.length) {
		var target = experimentalRTXTargets[i];
		var shader = experimentalRTXShaders[i];
		if (target != null && target.shader == shader)
			target.shader = null;
	}
	experimentalRTXTargets = [];
	experimentalRTXShaders = [];
}

function applyExperimentalRTXToSprite(sprite:Dynamic) {
	if (sprite == null || experimentalRTXData == null || experimentalRTXTargets.indexOf(sprite) >= 0) return;

	var shader = new CustomShader("RTXEffect");
	setupExperimentalRTXShader(shader, sprite);
	sprite.shader = shader;
	experimentalRTXTargets.push(sprite);
	experimentalRTXShaders.push(shader);
}

function setupExperimentalRTXShader(shader:Dynamic, sprite:Dynamic) {
	setExperimentalRTXUniform(shader, "overlayColor", colorToExperimentalRTXVec4(getExperimentalRTXString("overlay", "0x000000"), getExperimentalRTXFloat("overlayAlpha", 0)));
	setExperimentalRTXUniform(shader, "satinColor", colorToExperimentalRTXVec4(getExperimentalRTXString("satin", "0xFFFFFF"), getExperimentalRTXFloat("satinAlpha", 0)));
	setExperimentalRTXUniform(shader, "innerShadowColor", colorToExperimentalRTXVec4(getExperimentalRTXString("inner", "0x000000"), getExperimentalRTXFloat("innerAlpha", 0)));
	setExperimentalRTXUniform(shader, "innerShadowDistance", getExperimentalRTXFloat("innerDistance", 10));
	setExperimentalRTXUniform(shader, "innerShadowAngle", getExperimentalRTXAngle(sprite));
	setExperimentalRTXUniform(shader, "layernumbers", getExperimentalRTXFloat("layernumbers", getExperimentalRTXFloat("layers", 5)));
	setExperimentalRTXUniform(shader, "layerseparation", getExperimentalRTXFloat("layerseparation", getExperimentalRTXFloat("separation", 1)));
	setExperimentalRTXUniform(shader, "hue", experimentalRTXHue);
}

function setExperimentalRTXHue(value:Float) {
	experimentalRTXHue = value;
	for (shader in experimentalRTXShaders)
		setExperimentalRTXUniform(shader, "hue", value);
}

function updateExperimentalRTXAngles() {
	if (experimentalRTXData == null) return;
	for (i in 0...experimentalRTXTargets.length) {
		var sprite = experimentalRTXTargets[i];
		var shader = experimentalRTXShaders[i];
		if (sprite == null || shader == null || sprite.shader != shader) continue;
		setExperimentalRTXUniform(shader, "innerShadowAngle", getExperimentalRTXAngle(sprite));
	}
}

function setExperimentalRTXUniform(shader:Dynamic, property:String, value:Dynamic) {
	try {
		shader.hset(property, value);
	} catch(e:Dynamic) {
		try {
			Reflect.setProperty(shader, property, value);
		} catch(e2:Dynamic) {}
	}
}

function colorToExperimentalRTXVec4(value:String, alpha:Float):Array<Float> {
	var rgb = parseExperimentalRTXColor(value);
	return [rgb[0], rgb[1], rgb[2], alpha];
}

function parseExperimentalRTXColor(value:String):Array<Float> {
	var raw = Std.string(value);
	raw = StringTools.replace(raw, "#", "");
	raw = StringTools.replace(raw, "0x", "");
	raw = StringTools.replace(raw, "0X", "");
	if (raw.length == 8) raw = raw.substr(2, 6);
	if (raw.length != 6) return [1, 1, 1];

	var r = Std.parseInt("0x" + raw.substr(0, 2));
	var g = Std.parseInt("0x" + raw.substr(2, 2));
	var b = Std.parseInt("0x" + raw.substr(4, 2));
	if (r == null || g == null || b == null) return [1, 1, 1];

	return [r / 255, g / 255, b / 255];
}

function getExperimentalRTXAngle(sprite:Dynamic):Float {
	if (getExperimentalRTXBool("pointLight", false) && sprite != null) {
		var midpoint = sprite.getGraphicMidpoint();
		var dx = getExperimentalRTXFloat("lightX", 0) - midpoint.x;
		var dy = getExperimentalRTXFloat("lightY", 0) - midpoint.y;
		if (sprite.flipX) dx = -dx;
		if (sprite.flipY) dy = -dy;
		return Math.atan2(dy, dx);
	}

	var radians = getExperimentalRTXFloat("innerAngle", 270) * Math.PI / 180;
	if (sprite != null && sprite.flipX)
		radians = Math.atan2(Math.sin(radians), -Math.cos(radians));
	return radians;
}

function getExperimentalRTXString(field:String, fallback:String):String {
	var value = Reflect.field(experimentalRTXData, field);
	return value == null ? fallback : Std.string(value);
}

function getExperimentalRTXFloat(field:String, fallback:Float):Float {
	var value = Reflect.field(experimentalRTXData, field);
	if (value == null) return fallback;
	var parsed = Std.parseFloat(Std.string(value));
	return Math.isNaN(parsed) ? fallback : parsed;
}

function getExperimentalRTXBool(field:String, fallback:Bool):Bool {
	var value = Reflect.field(experimentalRTXData, field);
	if (value == null) return fallback;
	return Std.string(value).toLowerCase() == "true";
}

function createExperimentalCharacters() {
	if (stage == null) return;

	for (i => strumLine in PlayState.SONG.strumLines) {
		if (strumLine == null || strumLine.characters == null) continue;

		var charPosName:String = strumLine.position == null ? (switch(strumLine.type) {
			case 0: "dad";
			case 1: "boyfriend";
			case 2: "girlfriend";
			default: "dad";
		}) : strumLine.position;

		var chars = [];
		for (k => charName in strumLine.characters) {
			var flip = stage.isCharFlipped(stage.characterPoses[charName] != null ? charName : charPosName, strumLine.type == 1);
			var char = new Character(0, 0, charName, flip, true, true);
			stage.applyCharStuff(char, charPosName, k);
			char.globalOffset.x -= (char.frameWidth * char.scale.x) / 2;
			char.globalOffset.y -= (char.frameHeight * char.scale.y);
			char.danceOnBeat = false;
			playExperimentalCharDance(char);
			char.cameras = [camGame];
			add(char);
			experimentalPreviewChars.push(char);
			chars.push(char);
		}
		experimentalPreviewCharGroups[i] = chars;
		experimentalPreviewCharData[i] = {
			animSuffix: "",
			lastHit: {
				time: 0,
				endTime: 0,
				dir: -1,
				animSuffix: ""
			}
		};
	}

	loadExperimentalRTX();
}

function getExperimentalNoteSkinForTime(time:Float, noteType:String = "none"):String {
	var noteTypeData = getExperimentalNoteTypeData(noteType);
	if (noteTypeData != null && noteTypeData.skin != null)
		return "game/voiid/notes/" + noteTypeData.skin;

	var noteSkinPrefix = "voiid/";
	var chartEvents:Dynamic = Reflect.field(PlayState.SONG, "events");
	if (chartEvents != null) {
		for (event in chartEvents) {
			if (event == null || event.name != "Change UI Skin" || event.params == null) continue;
			if (event.time <= time && event.params.length > 1) {
				noteSkinPrefix = event.params[1];
			}
		}
	}
	return "game/" + noteSkinPrefix + "notes/default";
}

function makeExperimentalNoteSprite(strumLineID:Int, noteData:Dynamic) {
	var id:Int = Std.int(Reflect.field(noteData, "id"));
	var time:Float = Std.parseFloat(Std.string(Reflect.field(noteData, "time")));
	var sustainMs:Float = Std.parseFloat(Std.string(Reflect.field(noteData, "sLen")));
	if (Math.isNaN(sustainMs)) sustainMs = 0;
	var noteType:String = getExperimentalNoteTypeName(noteData);
	var noteSkin:String = getExperimentalNoteSkinForTime(time, noteType);
	var sprite = new FlxSprite();
	sprite.frames = Paths.getFrames(noteSkin);
	sprite.antialiasing = true;

	sprite.animation.addByPrefix("scroll", getExperimentalNoteAnim(strumLineID, id, 0));
	sprite.animation.play("scroll");

	var strumLine = PlayState.SONG.strumLines[strumLineID];
	var kc:Int = getExperimentalKeyCountIndex(strumLineID);
	var strumScale:Float = strumLine.strumScale == null ? 1 : strumLine.strumScale;
	sprite.setGraphicSize(Std.int(sprite.width * multikeyScales[kc] * strumScale));
	sprite.updateHitbox();
	sprite.cameras = [camHUD];
	sprite.visible = false;
	add(sprite);

	var sustain:FlxSprite = null;
	var sustainBody:FlxSprite = null;
	var sustainEnd:FlxSprite = null;
	var sustainBodyFrameHeight:Float = 1;
	var sustainBodyBaseScaleX:Float = 1;
	if (sustainMs > 0) {
		var sustainScaleX:Float = getExperimentalNoteScaleX(strumLineID, strumScale);

		sustainBody = new FlxSprite();
		sustainBody.frames = Paths.getFrames(noteSkin);
		sustainBody.antialiasing = true;
		sustainBody.animation.addByPrefix("hold", getExperimentalNoteAnim(strumLineID, id, 1));
		sustainBody.animation.play("hold");
		sustainBody.scale.set(sustainScaleX, 1);
		sustainBody.updateHitbox();
		sustainBodyFrameHeight = sustainBody.frameHeight > 0 ? sustainBody.frameHeight : sustainBody.height;
		sustainBodyBaseScaleX = sustainScaleX;
		sustainBody.cameras = [camHUD];
		sustainBody.visible = false;
		add(sustainBody);

		sustainEnd = new FlxSprite();
		sustainEnd.frames = Paths.getFrames(noteSkin);
		sustainEnd.antialiasing = true;
		sustainEnd.animation.addByPrefix("holdend", getExperimentalNoteAnim(strumLineID, id, 2));
		sustainEnd.animation.play("holdend");
		sustainEnd.scale.set(sustainScaleX, sustainScaleX);
		sustainEnd.updateHitbox();
		sustainEnd.cameras = [camHUD];
		sustainEnd.visible = false;
		add(sustainEnd);
	}

	if (sustainMs > 0) {
		remove(sprite, true);
		add(sprite);
	}

	return {
		sprite: sprite,
		sustain: sustain,
		sustainBody: sustainBody,
		sustainEnd: sustainEnd,
		sustainBodyFrameHeight: sustainBodyFrameHeight,
		sustainBodyBaseScaleX: sustainBodyBaseScaleX,
		strumLineID: strumLineID,
		time: time,
		id: id,
		lane: getExperimentalLane(strumLineID, id),
		noteType: noteType,
		type: Reflect.field(noteData, "type"),
		sLen: sustainMs,
		endTime: time + sustainMs,
		wasHit: false,
		visibleInPreview: false,
		baseScaleX: sprite.scale.x,
		baseScaleY: sprite.scale.y,
		sustainLastHeight: -1,
		nextSustainConfirmTime: time + (Conductor.stepCrochet > 0 ? Conductor.stepCrochet : 125)
	};
}

function createExperimentalNotes() {
	for (strumLineID => strumLine in PlayState.SONG.strumLines) {
		if (strumLine == null || strumLine.notes == null) continue;
		for (note in strumLine.notes) {
			experimentalPreviewNotes.push(makeExperimentalNoteSprite(strumLineID, note));
		}
	}
	experimentalPreviewNotes.sort(function(a, b) {
		if (a.time < b.time) return -1;
		if (a.time > b.time) return 1;
		return 0;
	});
}

function createExperimentalGameplayPreview() {
	clearExperimentalGameplayPreview();
	createExperimentalCharacters();
	createExperimentalNotes();
	if (legacyNoteModchart) {
		var rt = ensureLegacyEditorRuntime();
		if (rt != null)
			rt.call("initEditor", []);
	}
	refreshExperimentalPreviewNoteIndex();
	updateExperimentalGameplayPreview();
}

function refreshExperimentalPreviewNoteIndex() {
	experimentalPreviewNextNoteIndex = 0;
	while (experimentalPreviewNextNoteIndex < experimentalPreviewNotes.length && experimentalPreviewNotes[experimentalPreviewNextNoteIndex].time < Conductor.songPosition) {
		experimentalPreviewNextNoteIndex++;
	}
	experimentalPreviewFirstRenderIndex = 0;
	while (experimentalPreviewFirstRenderIndex < experimentalPreviewNotes.length && experimentalPreviewNotes[experimentalPreviewFirstRenderIndex].endTime < Conductor.songPosition - EXPERIMENTAL_PREVIEW_PAST_WINDOW) {
		hideExperimentalPreviewNote(experimentalPreviewNotes[experimentalPreviewFirstRenderIndex]);
		experimentalPreviewFirstRenderIndex++;
	}
	for (data in experimentalPreviewNotes) {
		if (data != null) {
			data.wasHit = data.time < Conductor.songPosition;
			hideExperimentalPreviewNote(data);
		}
	}
	experimentalPreviewLastSongPosition = Conductor.songPosition;
}

function getExperimentalCharactersForNote(noteData:Dynamic):Array<Dynamic> {
	var chars:Array<Dynamic> = [];
	var group = experimentalPreviewCharGroups[noteData.strumLineID];
	if (group == null || group.length < 1) return chars;

	var noteType = noteData.noteType == null ? "none" : noteData.noteType;
	if (!StringTools.contains(noteType, "char[")) {
		if (StringTools.contains(noteType, "char")) {
			var charPos:Int = noteType.lastIndexOf("char");
			var parsedChar:Null<Int> = Std.parseInt(noteType.substring(charPos + 4));
			if (parsedChar != null) {
				var charIndex:Int = Std.int(parsedChar) % group.length;
				if (charIndex < 0) charIndex += group.length;
				if (group[charIndex] != null)
					chars.push(group[charIndex]);
				return chars;
			}
		}
		chars.push(group[0]);
		return chars;
	}

	var start:Int = noteType.indexOf("char[") + 5;
	var end:Int = noteType.indexOf("]", start);
	if (end < 0) end = noteType.length;
	var characterIndexes = noteType.substring(start, end).split(",");
	for (id in characterIndexes) {
		var parsedIndex:Null<Int> = Std.parseInt(id);
		if (parsedIndex == null) continue;
		var index:Int = Std.int(parsedIndex) % group.length;
		if (index < 0) index += group.length;
		if (group[index] != null)
			chars.push(group[index]);
	}
	return chars;
}

function playExperimentalStrumAnim(strum:Dynamic, anim:String, force:Bool = true) {
	if (strum == null || strum.animation == null) return;
	strum.animation.play(anim, force);
	strum.centerOffsets();
	strum.centerOrigin();
}

function pulseExperimentalSustainConfirm(noteData:Dynamic) {
	if (noteData == null || noteData.sLen <= 0 || !noteData.wasHit || Conductor.songPosition < noteData.time || Conductor.songPosition > noteData.endTime) return;
	var interval:Float = Conductor.stepCrochet > 0 ? Conductor.stepCrochet : 125;
	if (noteData.nextSustainConfirmTime == null || noteData.nextSustainConfirmTime < noteData.time)
		noteData.nextSustainConfirmTime = noteData.time + interval;
	if (noteData.nextSustainConfirmTime > Conductor.songPosition) return;
	if (strumLines[noteData.strumLineID] != null && strumLines[noteData.strumLineID][noteData.lane] != null)
		playExperimentalStrumAnim(strumLines[noteData.strumLineID][noteData.lane], "confirm", true);
	noteData.nextSustainConfirmTime = Conductor.songPosition + interval;
}

function triggerExperimentalNoteHit(noteData:Dynamic) {
	if (noteData == null) return;
	if (experimentalPreviewCharGroups[noteData.strumLineID] == null) return;
	noteData.wasHit = true;
	noteData.nextSustainConfirmTime = noteData.time + (Conductor.stepCrochet > 0 ? Conductor.stepCrochet : 125);
	if (strumLines[noteData.strumLineID] != null && strumLines[noteData.strumLineID][noteData.lane] != null)
		playExperimentalStrumAnim(strumLines[noteData.strumLineID][noteData.lane], "confirm", true);

	var eventTime:Float = noteData.time;
	var sustainSteps:Float = 0;
	var sustainMs = Std.parseFloat(Std.string(noteData.sLen));
	if (!Math.isNaN(sustainMs) && Conductor.stepCrochet > 0) {
		sustainSteps = sustainMs / Conductor.stepCrochet;
	}

	var groupData = experimentalPreviewCharData[noteData.strumLineID];
	if (groupData == null) return;

	var singDir:Int = getExperimentalSingDirection(noteData.strumLineID, noteData.id);
	var animSuffix:String = groupData.animSuffix;
	var noteTypeData = getExperimentalNoteTypeData(noteData.noteType);
	if (noteTypeData != null && noteTypeData.animSuffix != null)
		animSuffix = noteTypeData.animSuffix;
	if (singDir == 4) {
		singDir = 2;
		var charGroup = experimentalPreviewCharGroups[noteData.strumLineID];
		if (charGroup != null && charGroup.length > 0 && charGroup[0].animation.getByName("singUP-SPACE") != null)
			animSuffix = "-SPACE";
	}

	if (!(eventTime >= groupData.lastHit.time && groupData.lastHit.endTime > eventTime)) {
		var holdMs:Float = Conductor.stepCrochet > 0 ? Conductor.stepCrochet * Math.max(sustainSteps, 4) : Math.max(sustainMs, 500);
		groupData.lastHit.time = eventTime;
		groupData.lastHit.endTime = eventTime + holdMs;
		groupData.lastHit.dir = singDir;
		groupData.lastHit.animSuffix = animSuffix;
	}

	for (char in getExperimentalCharactersForNote(noteData)) {
		char.playSingAnim(singDir, animSuffix, "SING", true);
		char.lastHit = eventTime;
	}
}

function updateExperimentalCharacterHits() {
	if (experimentalPreviewLastSongPosition == Math.NEGATIVE_INFINITY) {
		refreshExperimentalPreviewNoteIndex();
		return;
	}

	if (Conductor.songPosition < experimentalPreviewLastSongPosition) {
		refreshExperimentalPreviewNoteIndex();
		for (group in experimentalPreviewCharGroups) {
			if (group == null) continue;
			for (char in group)
				playExperimentalCharDance(char);
		}
		return;
	}

	while (experimentalPreviewNextNoteIndex < experimentalPreviewNotes.length && experimentalPreviewNotes[experimentalPreviewNextNoteIndex].time <= Conductor.songPosition) {
		triggerExperimentalNoteHit(experimentalPreviewNotes[experimentalPreviewNextNoteIndex]);
		experimentalPreviewNextNoteIndex++;
	}

	for (id => groupData in experimentalPreviewCharData) {
		if (groupData == null || experimentalPreviewCharGroups[id] == null) continue;
		if (Conductor.songPosition < groupData.lastHit.time || Conductor.songPosition > groupData.lastHit.endTime) {
			for (char in experimentalPreviewCharGroups[id]) {
				if (char != null && char.lastAnimContext == "SING")
					playExperimentalCharDance(char);
			}
		}
	}

	experimentalPreviewLastSongPosition = Conductor.songPosition;
}

function hideExperimentalPreviewNote(data:Dynamic) {
	if (data == null) return;
	if (data.sprite != null) data.sprite.visible = false;
	if (data.sustain != null) data.sustain.visible = false;
	if (data.sustainBody != null) {
		data.sustainBody.visible = false;
		data.sustainBody.clipRect = null;
	}
	if (data.sustainEnd != null) data.sustainEnd.visible = false;
	data.visibleInPreview = false;
}

function forceExperimentalModifierValues(shader:Dynamic, table:Dynamic, strumLineID:Int, lane:Int) {
	if (shader == null || table == null || table.modTable == null || table.modTable[strumLineID] == null || table.modTable[strumLineID][lane] == null) return;
	for (mod in table.modTable[strumLineID][lane]) {
		if (mod == null) continue;
		try {
			shader.hset(mod.shaderName, mod.value);
		} catch(e:Dynamic) {}
		if (mod.subMods != null) {
			for (sub in mod.subMods) {
				if (sub == null) continue;
				try {
					shader.hset(sub.shaderName, sub.value);
				} catch(e:Dynamic) {}
			}
		}
	}
}

function getExperimentalSubModValue(mod:Dynamic, name:String, fallback:Float = 0):Float {
	if (mod == null || mod.subMods == null) return fallback;
	for (sub in mod.subMods) {
		if (sub != null && sub.name == name)
			return sub.value == null ? fallback : sub.value;
	}
	return fallback;
}

function getExperimentalModifierTransform(strumLineID:Int, lane:Int, curPos:Float) {
	var result = {
		x: 0.0,
		y: 0.0,
		angle: 0.0,
		scaleX: 1.0,
		scaleY: 1.0,
		alpha: 1.0
	};

	var table = getExperimentalModTable();
	if (table == null || table.modTable == null || table.modTable[strumLineID] == null || table.modTable[strumLineID][lane] == null) return result;

	for (mod in table.modTable[strumLineID][lane]) {
		if (mod == null || mod.value == null) continue;
		var value:Float = mod.value;
		var shaderFile = mod.shaderFile == null ? mod.name : mod.shaderFile;
		switch(shaderFile) {
			case "x":
				result.x += value;
			case "y":
				result.y += value;
			case "xSplit":
				result.x += lane < 2 ? -value : value;
			case "ySplit":
				result.y += lane < 2 ? -value : value;
			case "angleZ":
				result.angle += value;
			case "angleZSplit":
				result.angle += lane < 2 ? -value : value;
			case "noteScale":
				result.scaleX *= 1 + value;
				result.scaleY *= 1 + value;
			case "scaleX":
				result.scaleX *= value;
			case "scaleY":
				result.scaleY *= value;
			case "alpha":
				result.alpha *= 1 + value;
			case "drunk":
				var drunkSpeed:Float = getExperimentalSubModValue(mod, "speed", 1);
				result.x += Math.cos(((Conductor.songPosition * 0.001) + (lane * 0.2) + (curPos * 0.45) * 0.013) * (drunkSpeed * 0.2)) * 112.0 * 0.5 * value;
			case "drunknotime":
				result.x += Math.sin(curPos * 0.05) * 120.0 * value;
			case "tipsy":
				var tipsySpeed:Float = getExperimentalSubModValue(mod, "speed", 1);
				result.y += Math.cos(Conductor.songPosition * 0.001 * 1.2 + lane * 2.0 + 2.0 * (0.2 * tipsySpeed)) * 112.0 * 0.4 * value;
			case "invert":
				if (lane % 2 == 0)
					result.x += 112.0 * value;
				else
					result.x -= 112.0 * value;
			case "flip":
				var newPos:Float = 4.0 + (lane - 0.0) * ((-4.0 - 4.0) / (4.0 - 0.0));
				result.x += (112.0 * newPos * value) - (112.0 * value);
			default:
		}
	}

	return result;
}

function getExperimentalModTable() {
	try {
		if (modTable != null) return modTable;
	} catch(e:Dynamic) {}
	try {
		var pack = Reflect.field(FlxG.state, "stateScripts");
		if (pack != null) {
			var table = Reflect.callMethod(pack, Reflect.field(pack, "get"), ["modTable"]);
			if (table != null) return table;
		}
	} catch(e2:Dynamic) {}
	return Reflect.field(this, "modTable");
}

function getExperimentalModchartCamera() {
	try {
		if (modchartCamera != null) return modchartCamera;
	} catch(e:Dynamic) {}
	try {
		var pack = Reflect.field(FlxG.state, "stateScripts");
		if (pack != null) {
			var camera = Reflect.callMethod(pack, Reflect.field(pack, "get"), ["modchartCamera"]);
			if (camera != null) return camera;
		}
	} catch(e2:Dynamic) {}
	return Reflect.field(this, "modchartCamera");
}

function getExperimentalPerspectiveShader(data:Dynamic, fieldName:String, strumLineID:Int, lane:Int) {
	var table = getExperimentalModTable();
	if (table == null) return null;

	var shader = Reflect.field(data, fieldName);
	if (Reflect.field(data, fieldName + "Table") != table)
		shader = null;
	if (shader != null) return shader;

	try {
		if (Reflect.field(table, "createShader") != null)
			shader = Reflect.callMethod(table, Reflect.field(table, "createShader"), [strumLineID, lane]);
		else if (Reflect.field(table, "getShader") != null)
			shader = Reflect.callMethod(table, Reflect.field(table, "getShader"), [strumLineID, lane]);
		Reflect.setField(data, fieldName, shader);
		Reflect.setField(data, fieldName + "Table", table);
	} catch(e:Dynamic) {
		shader = null;
	}
	return shader;
}

function applyExperimentalPerspectiveToSprite(target:Dynamic, shader:Dynamic, strum:Dynamic, strumLineID:Int, lane:Int, curPos:Float, nextCurPos:Float, isSustain:Bool) {
	try {
		var table = getExperimentalModTable();
		var camera = getExperimentalModchartCamera();
		if (target == null || shader == null || table == null || camera == null) return;

		target.shader = shader;
		shader.viewMatrix = camera.viewMatrix;
		shader.perspectiveMatrix = camera.perspectiveMatrix;
		shader.songPosition = Conductor.songPosition;
		shader.curBeat = Conductor.curBeatFloat;
		shader.downscroll = downscroll;
		shader.isSustainNote = isSustain;

		if (target.frame != null)
			shader.frameUV = [target.frame.uv.x, target.frame.uv.y, target.frame.uv.width, target.frame.uv.height];

		var point = FlxPoint.weak();
		target.getScreenPosition(point, camHUD);
		shader.screenX = target.origin.x + point.x - target.offset.x;
		shader.screenY = target.origin.y + point.y - target.offset.y;
		point.put();

		shader.strumID = lane;
		shader.strumLineID = strumLineID;
		shader.data.noteCurPos.value = [curPos, curPos, nextCurPos, nextCurPos];
		shader.scrollSpeed = PlayState.SONG.scrollSpeed == null ? 1 : PlayState.SONG.scrollSpeed;
		forceExperimentalModifierValues(shader, table, strumLineID, lane);
	} catch(e:Dynamic) {
	}
}

function applyExperimentalPerspectiveStrum(strum:Dynamic, strumLineID:Int, lane:Int) {
	try {
		var table = getExperimentalModTable();
		var camera = getExperimentalModchartCamera();
		if (strum == null || table == null || camera == null) return;

		if (strum.shader == null || Reflect.field(strum, "experimentalShaderTable") != table) {
			if (Reflect.field(table, "createShader") != null)
				strum.shader = Reflect.callMethod(table, Reflect.field(table, "createShader"), [strumLineID, lane]);
			else if (Reflect.field(table, "getShader") != null)
				strum.shader = Reflect.callMethod(table, Reflect.field(table, "getShader"), [strumLineID, lane]);
			Reflect.setField(strum, "experimentalShaderTable", table);
		}
		if (strum.shader == null) return;

		strum.shader.viewMatrix = camera.viewMatrix;
		strum.shader.perspectiveMatrix = camera.perspectiveMatrix;
		strum.shader.songPosition = Conductor.songPosition;
		strum.shader.curBeat = Conductor.curBeatFloat;
		strum.shader.downscroll = downscroll;
		strum.shader.isSustainNote = false;

		if (strum.frame != null)
			strum.shader.frameUV = [strum.frame.uv.x, strum.frame.uv.y, strum.frame.uv.width, strum.frame.uv.height];

		var point = FlxPoint.weak();
		strum.getScreenPosition(point, camHUD);
		strum.shader.screenX = strum.origin.x + point.x - strum.offset.x;
		strum.shader.screenY = strum.origin.y + point.y - strum.offset.y;
		point.put();

		strum.shader.strumID = lane;
		strum.shader.strumLineID = strumLineID;
		strum.shader.data.noteCurPos.value = [0.0, 0.0, 0.0, 0.0];
		strum.shader.scrollSpeed = 0.0;
		forceExperimentalModifierValues(strum.shader, table, strumLineID, lane);
	} catch(e:Dynamic) {
	}
}

function updateExperimentalGameplayPreview() {
	if (!experimentalGameplayPreview) return;
	updateExperimentalCharacterHits();
	updateExperimentalRTXAngles();

	if (!legacyNoteModchart) {
		var camera = Reflect.field(this, "modchartCamera");
		if (camera != null && Reflect.field(camera, "updateViewMatrix") != null) {
			try {
				Reflect.callMethod(camera, Reflect.field(camera, "updateViewMatrix"), []);
			} catch(e:Dynamic) {}
		}
	}

	var speed:Float = PlayState.SONG.scrollSpeed == null ? 1 : PlayState.SONG.scrollSpeed;
	for (strumLineID => line in strumLines) {
		if (line == null) continue;
		for (lane => strum in line) {
			if (strum != null && strum.animation.curAnim != null && strum.animation.curAnim.name == "confirm" && strum.animation.curAnim.finished)
				playExperimentalStrumAnim(strum, "static");
			if (!legacyNoteModchart)
				applyExperimentalPerspectiveStrum(strum, strumLineID, lane);
		}
	}

	while (experimentalPreviewFirstRenderIndex < experimentalPreviewNotes.length && experimentalPreviewNotes[experimentalPreviewFirstRenderIndex].endTime < Conductor.songPosition - EXPERIMENTAL_PREVIEW_PAST_WINDOW) {
		hideExperimentalPreviewNote(experimentalPreviewNotes[experimentalPreviewFirstRenderIndex]);
		experimentalPreviewFirstRenderIndex++;
	}

	for (i in experimentalPreviewFirstRenderIndex...experimentalPreviewNotes.length) {
		var data = experimentalPreviewNotes[i];
		if (data == null || data.sprite == null) continue;
		if (data.time - Conductor.songPosition > EXPERIMENTAL_PREVIEW_FUTURE_WINDOW) {
			hideExperimentalPreviewNote(data);
			break;
		}

		if (strumLines[data.strumLineID] == null) {
			hideExperimentalPreviewNote(data);
			continue;
		}

		if (strumLines[data.strumLineID].length < 1) {
			hideExperimentalPreviewNote(data);
			continue;
		}

		var lane:Int = data.lane == null ? Std.int(data.id % strumLines[data.strumLineID].length) : Std.int(data.lane);
		var strum = strumLines[data.strumLineID][lane];
		if (strum == null) {
			hideExperimentalPreviewNote(data);
			continue;
		}

		var pxPerMs:Float = 0.45 * speed;
		var scrollDir:Int = downscroll ? -1 : 1;
		var diff:Float = data.time - Conductor.songPosition;
		var endDiff:Float = diff + data.sLen;
		if (endDiff < -EXPERIMENTAL_PREVIEW_PAST_WINDOW || diff > EXPERIMENTAL_PREVIEW_FUTURE_WINDOW) {
			hideExperimentalPreviewNote(data);
			continue;
		}

		var noteTypeData = getExperimentalNoteTypeData(data.noteType);
		var singDir:Int = getExperimentalSingDirection(data.strumLineID, data.id);
		if (singDir == 4) singDir = 2;
		var offsetX:Float = 0;
		var offsetY:Float = 0;
		if (noteTypeData != null) {
			if (noteTypeData.offsetsX != null && noteTypeData.offsetsX[singDir] != null)
				offsetX += noteTypeData.offsetsX[singDir] * 1.4285 * data.sprite.scale.x;
			if (downscroll && noteTypeData.offsetsYDS != null && noteTypeData.offsetsYDS[singDir] != null)
				offsetY += noteTypeData.offsetsYDS[singDir] * 1.4285 * data.sprite.scale.y;
			else if (!downscroll && noteTypeData.offsetsY != null && noteTypeData.offsetsY[singDir] != null)
				offsetY += noteTypeData.offsetsY[singDir] * 1.4285 * data.sprite.scale.y;
		}

		var noteCurPosForMods:Float = Conductor.songPosition - data.time;
		var noteTransform = getExperimentalModifierTransform(data.strumLineID, lane, noteCurPosForMods);
		data.sprite.x = strum.x + ((strum.width - data.sprite.width) / 2);
		data.sprite.y = strum.y + (diff * pxPerMs * scrollDir);
		data.sprite.x += offsetX + noteTransform.x;
		data.sprite.y += offsetY - noteTransform.y;
		data.sprite.angle = noteTransform.angle;
		data.sprite.alpha = noteTransform.alpha;
		data.sprite.scale.x = data.baseScaleX * Math.abs(noteTransform.scaleX);
		data.sprite.scale.y = data.baseScaleY * Math.abs(noteTransform.scaleY);
		data.sprite.visible = !data.wasHit && diff > 0 && diff < EXPERIMENTAL_PREVIEW_FUTURE_WINDOW;
		if (data.sprite.visible) {
			var noteShader = getExperimentalPerspectiveShader(data, "shader", data.strumLineID, lane);
			applyExperimentalPerspectiveToSprite(data.sprite, noteShader, strum, data.strumLineID, lane, noteCurPosForMods, noteCurPosForMods, false);
		}

		if (data.sLen > 0) {
			pulseExperimentalSustainConfirm(data);
			var sustainVisible:Bool = data.sLen > 0 && endDiff > -EXPERIMENTAL_PREVIEW_PAST_WINDOW && diff < EXPERIMENTAL_PREVIEW_FUTURE_WINDOW;

			if (data.wasHit && Conductor.songPosition <= data.endTime) {
				var sustainAnimSuffix = "";
				var sustainGroupData = experimentalPreviewCharData[data.strumLineID];
				if (sustainGroupData != null && sustainGroupData.animSuffix != null)
					sustainAnimSuffix = sustainGroupData.animSuffix;
				if (noteTypeData != null && noteTypeData.animSuffix != null)
					sustainAnimSuffix = noteTypeData.animSuffix;
				for (char in getExperimentalCharactersForNote(data)) {
					if (char != null) {
						if (char.lastAnimContext != "SING")
							char.playSingAnim(singDir, sustainAnimSuffix, "SING", true);
						char.lastHit = Conductor.songPosition;
					}
				}
			}

			if (data.sustainBody != null) {
				var sustainYOffset:Float = getExperimentalSustainYOffset(data.strumLineID);
				var tapHalfH:Float = data.sprite.height * 0.5;
				var headY:Float = strum.y + (diff * pxPerMs * scrollDir);
				var tailY:Float = strum.y + (endDiff * pxPerMs * scrollDir);
				var strumBodyY:Float = strum.y + tapHalfH + sustainYOffset;
				var bodyAnchorTop:Float = Math.min(headY, tailY) + tapHalfH + sustainYOffset;
				var bodyAnchorBottom:Float = Math.max(headY, tailY) + tapHalfH + sustainYOffset;
				var bodyHeightPx:Float = 0.0;
				var bodyY:Float = 0.0;
				var bodyCurPosForMods:Float = data.wasHit ? 0 : (diff > 0 ? diff * pxPerMs : 0);
				var bodyTransform = getExperimentalModifierTransform(data.strumLineID, lane, bodyCurPosForMods);
				var frameH:Float = data.sustainBodyFrameHeight;

				data.sustainBody.clipRect = null;
				data.sustainBody.x = strum.x + ((strum.width - data.sustainBody.width) / 2) + offsetX + bodyTransform.x;
				data.sustainBody.angle = 0;
				data.sustainBody.alpha = bodyTransform.alpha;
				data.sustainBody.scale.x = data.sustainBodyBaseScaleX;

				if (data.wasHit && Conductor.songPosition >= data.time) {
					bodyHeightPx = Math.max(0, endDiff * pxPerMs);
					bodyY = strumBodyY;
				} else {
					bodyHeightPx = Math.max(0, bodyAnchorBottom - bodyAnchorTop);
					bodyY = bodyAnchorTop;
				}

				data.sustainBody.y = bodyY + offsetY - bodyTransform.y;
				data.sustainBody.scale.y = Math.max(0.01, bodyHeightPx / frameH);
				data.sustainBody.updateHitbox();
				data.sustainBody.visible = sustainVisible && bodyHeightPx > 2;

				if (data.sustainBody.visible) {
					var sustainBodyShader = getExperimentalPerspectiveShader(data, "sustainBodyShader", data.strumLineID, lane);
					var bodyCurPos:Float = Conductor.songPosition - data.time;
					var bodyNextCurPos:Float = Conductor.songPosition - data.endTime;
					if (bodyCurPos > 0) bodyCurPos = 0;
					if (downscroll)
						applyExperimentalPerspectiveToSprite(data.sustainBody, sustainBodyShader, strum, data.strumLineID, lane, bodyNextCurPos, bodyCurPos, true);
					else
						applyExperimentalPerspectiveToSprite(data.sustainBody, sustainBodyShader, strum, data.strumLineID, lane, bodyCurPos, bodyNextCurPos, true);
				}
			}

			if (data.sustainEnd != null) {
				var sustainYOffset:Float = getExperimentalSustainYOffset(data.strumLineID);
				var tapHalfH:Float = data.sprite.height * 0.5;
				var tailVisible:Bool = sustainVisible && endDiff > 0 && endDiff <= EXPERIMENTAL_PREVIEW_FUTURE_WINDOW;
				var tailTransform = getExperimentalModifierTransform(data.strumLineID, lane, Conductor.songPosition - data.endTime);
				data.sustainEnd.x = strum.x + ((strum.width - data.sustainEnd.width) / 2) + offsetX + tailTransform.x;
				data.sustainEnd.y = strum.y + (endDiff * pxPerMs * scrollDir) + tapHalfH + sustainYOffset + offsetY - tailTransform.y;
				data.sustainEnd.angle = 0;
				data.sustainEnd.alpha = tailTransform.alpha;
				data.sustainEnd.scale.set(data.sustainBodyBaseScaleX, data.sustainBodyBaseScaleX);
				data.sustainEnd.flipY = downscroll;
				data.sustainEnd.visible = tailVisible;
			}
			if (data.sustainEnd != null && data.sustainEnd.visible) {
				var sustainEndShader = getExperimentalPerspectiveShader(data, "sustainEndShader", data.strumLineID, lane);
				applyExperimentalPerspectiveToSprite(data.sustainEnd, sustainEndShader, strum, data.strumLineID, lane, Conductor.songPosition - data.endTime, Conductor.songPosition - (data.endTime + (Conductor.stepCrochet * 0.5)), true);
			}
		}
		data.visibleInPreview = data.sprite.visible || (data.sustainBody != null && data.sustainBody.visible) || (data.sustainEnd != null && data.sustainEnd.visible);
	}
}

var _fullscreen = false;
var _timelineScrollY = 0;
var __crochet:Float = 0;
var __firstFrame:Bool = true;
function update(elapsed) {
	if (FlxG.keys.justPressed.F6) {
		_view_reload_editor(null);
		return;
	}

	ROW_SIZE_X = CoolUtil.fpsLerp(ROW_SIZE_X, targetRowSizeX, 0.2);
	ROW_SIZE_Y = CoolUtil.fpsLerp(ROW_SIZE_Y, targetRowSizeY, 0.2);

	if (FlxG.sound.music.playing || __firstFrame) {
		conductorSprY = curStepFloat * ROW_SIZE_X;
	} else {
		conductorSprY = CoolUtil.fpsLerp(conductorSprY, curStepFloat * ROW_SIZE_X, __firstFrame ? 1 : 1/3);
	}
	eventRenderer.conductorPos = conductorSprY/ROW_SIZE_X;

	updateUI();
	updateInputs();

	updateEvents();

	if (legacyNoteModchart) {
		var rt = ensureLegacyEditorRuntime();
		if (rt != null)
			rt.call("editorPostUpdate", [elapsed]);
	}

	updateExperimentalGameplayPreview();

	__crochet = ((60 / Conductor.bpm) * 1000);
	if (timelineWindow.hovered) {
		if (FlxG.keys.pressed.CONTROL) {
			if (FlxG.mouse.wheel != 0.0) {
				targetRowSizeX += FlxG.mouse.wheel * 2;
				if (targetRowSizeX < 4) targetRowSizeX = 4;
				if (targetRowSizeX > 100) targetRowSizeX = 100;
			}
		} else {
			_timelineScrollY += (FlxG.keys.pressed.SHIFT ? 8.0 : 1.0) * -FlxG.mouse.wheel * ROW_SIZE_Y;
			_timelineScrollY = FlxMath.bound(_timelineScrollY, 0, Math.max(0, 30 + (ROW_SIZE_Y*timelineList.length) - 720/2.25));
			camTimelineValueList.scroll.y = camTimeline.scroll.y = camTimelineList.scroll.y = CoolUtil.fpsLerp(camTimelineList.scroll.y, _timelineScrollY, 0.15);
		}
	} else if (!timelineWindow.hovered) {
		if (FlxG.keys.pressed.CONTROL && FlxG.mouse.wheel != 0) {
			editorCamZoom += FlxG.mouse.wheel * 0.1 * editorCamZoom;
			editorCamZoom = FlxMath.bound(editorCamZoom, EDITOR_CAM_ZOOM_MIN, EDITOR_CAM_ZOOM_MAX);
		} else if (!FlxG.sound.music.playing) {
			Conductor.songPosition -= (__crochet*0.25 * (FlxG.keys.pressed.SHIFT ? 8.0 : 1.0) * FlxG.mouse.wheel) - Conductor.songOffset;
		}
	}

	//trace(_timelineScrollY);

	var songLength = FlxG.sound.music.length;
	Conductor.songPosition = FlxMath.bound(Conductor.songPosition + Conductor.songOffset, 0, songLength);
	if (Conductor.songPosition >= songLength - Conductor.songOffset) {
		FlxG.sound.music.pause();
		vocals.pause();
		//for (strumLine in strumLines.members) strumLine.vocals.pause();
	}

	songPosInfo.text = CoolUtil.timeToStr(Conductor.songPosition) + '/' + CoolUtil.timeToStr(songLength)
		+ '\nStep: ' + curStep
		+ '\nBeat: ' + curBeat
		+ '\nMeasure: ' + curMeasure
		+ '\nBPM: ' + Conductor.bpm;


	camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, editorCamZoom, 0.15);
	camHUD.zoom = CoolUtil.fpsLerp(camHUD.zoom, 1, 0.05);

	eventRenderer.events = events;
}

function updateUI() {
	camTimeline.scroll.x = conductorSprY;
	sectionSeparator.spacing.x = ((ROW_SIZE_X/4) * Conductor.beatsPerMeasure * Conductor.stepsPerBeat) - 1;
	beatSeparator.spacing.x = ((ROW_SIZE_X/2) * Conductor.stepsPerBeat) - 1;
	
	var lastCamScale = camGame.flashSprite.scaleX;
	var camScale = _fullscreen ? 1.0 : 0.5;
	var newScale = CoolUtil.fpsLerp(camGame.flashSprite.scaleX, camScale, 0.15);
	if (Math.abs(camScale-newScale) < 0.01) newScale = camScale;
	camGame.flashSprite.scaleX = camGame.flashSprite.scaleY = camOther.flashSprite.scaleX = camOther.flashSprite.scaleY = camHUD.flashSprite.scaleX = camHUD.flashSprite.scaleY = newScale;
	

	if (camGame.flashSprite.scaleX != lastCamScale) {
		ShaderResizeFix.fixSpriteShaderSize(camGame.flashSprite);
		ShaderResizeFix.fixSpriteShaderSize(camHUD.flashSprite);
		ShaderResizeFix.fixSpriteShaderSize(camOther.flashSprite);
	}

	camGame.y = camHUD.y = camOther.y = ((-720/4)+32) * (-((camGame.flashSprite.scaleX-0.5)*2)+1);
	camEditor.scroll.y = CoolUtil.fpsLerp(camEditor.scroll.y, _fullscreen ? -720/2 : 0, 0.15);
	camEditorTop.scroll.y = CoolUtil.fpsLerp(camEditorTop.scroll.y, _fullscreen ? 100 : 0, 0.15);
	camTimelineValueList.y = camTimelineList.y = camTimeline.y = ((-camEditor.scroll.y) + 720/2) + 30 + 40;

	scrollBar.size = (1280-250)/ROW_SIZE_X;
	scrollBar.start = Conductor.curStepFloat - (scrollBar.size / 2);

	if (topMenuSpr.members[snapIndex] != null) {
		var snapButton = topMenuSpr.members[snapIndex];
		var lastButtonX = snapButton.x + snapButton.bWidth + 100;

		var buttonI:Int = 0;
		for (button in quantButtons) {
			button.visible = ((button.quant == quant) ||
				(button.quant == quants[FlxMath.wrap(quants.indexOf(quant)-1, 0, quants.length-1)]) ||
				(button.quant == quants[FlxMath.wrap(quants.indexOf(quant)+1, 0, quants.length-1)]));
			button.selectable = button.visible;
			if (!button.visible) continue;

			button.x = lastButtonX -= button.bWidth;
			button.framesOffset = button.quant == quant ? 9 : 0;
			button.alpha = button.quant == quant ? 1 : (button.hovered ? 0.4 : 0);
		}
		//snapButton.x = (lastButtonX -= snapButton.bWidth)-10;
	}
	
}
function wantsStagePan():Bool {
	return FlxG.mouse.pressedRight || (FlxG.mouse.pressed && FlxG.keys.pressed.ALT);
}

function stagePanJustStarted():Bool {
	return FlxG.mouse.justPressedRight || (FlxG.mouse.justPressed && FlxG.keys.pressed.ALT);
}

function endStagePan() {
	isDraggingStage = false;
	stagePanLastMouse = null;
}


function resetEditorCamera() {
	endStagePan();
	initEditorCamera();
}

function getExperimentalPreviewCameraFocus():FlxPoint {
	if (!experimentalGameplayPreview || experimentalPreviewChars.length < 1) return null;

	for (i => strumLine in PlayState.SONG.strumLines) {
		if (strumLine == null || strumLine.type == 1) continue;
		var group = experimentalPreviewCharGroups[i];
		if (group == null || group.length < 1) continue;

		for (char in group) {
			if (char == null || !char.exists) continue;
			try {
				return char.getCameraPosition();
			} catch(e:Dynamic) {}
		}
	}

	for (i => strumLine in PlayState.SONG.strumLines) {
		if (strumLine == null) continue;
		var group = experimentalPreviewCharGroups[i];
		if (group == null || group.length < 1) continue;

		for (char in group) {
			if (char == null || !char.exists) continue;
			try {
				return char.getCameraPosition();
			} catch(e:Dynamic) {}
		}
	}

	return null;
}

function playExperimentalCharDance(char:Character) {
	if (char == null || !char.exists || char.animation == null) return;
	try {
		char.dance();
	} catch(e:Dynamic) {}
}

function beatHit(curBeat:Int) {
	if (!experimentalGameplayPreview) return;

	for (char in experimentalPreviewChars) {
		if (char == null || !char.exists || char.animation == null) continue;
		if (char.beatInterval < 1) continue;
		if ((curBeat + char.beatOffset) % char.beatInterval != 0) continue;
		if (char.lastAnimContext == "SING") continue;
		playExperimentalCharDance(char);
	}
}

function initEditorCamera() {
	if (stage == null) return;

	var focusX:Null<Float> = null;
	var focusY:Null<Float> = null;

	if (experimentalGameplayPreview) {
		var previewCamPos = getExperimentalPreviewCameraFocus();
		if (previewCamPos != null) {
			focusX = previewCamPos.x;
			focusY = previewCamPos.y;
			previewCamPos.put();
		}
	}

	if (focusX == null && focusY == null && stage.stageXML != null) {
		if (stage.stageXML.exists("startCamPosX"))
			focusX = Std.parseFloat(stage.stageXML.get("startCamPosX"));
		if (stage.stageXML.exists("startCamPosY"))
			focusY = Std.parseFloat(stage.stageXML.get("startCamPosY"));
	}

	if (focusX == null || focusY == null) {
		var bf = stage.characterPoses.get("boyfriend");
		if (bf != null) {
			if (focusX == null) focusX = bf.x + bf.camxoffset;
			if (focusY == null) focusY = bf.y + bf.camyoffset;
		}
	}

	if (focusX != null && focusY != null)
		camGame.focusOn(FlxPoint.get(focusX, focusY));

	editorCamZoom = defaultCamZoom;
	camGame.zoom = editorCamZoom;
}

function updateInputs() {

	if(FlxG.keys.justPressed.ANY && currentFocus == null)
		UIUtil.processShortcuts(topMenu);

	eventRenderer.visible = !_fullscreen;
	if (_fullscreen) return;

	// Stage pan
	if (!timelineWindow.hovered && wantsStagePan()) {

		var mouse = FlxG.mouse.getScreenPosition();

		if (!isDraggingStage) {
			isDraggingStage = true;

			if (stagePanLastMouse == null)
				stagePanLastMouse = FlxPoint.get();

			stagePanLastMouse.set(mouse.x, mouse.y);
		}
		else {
			var zoom = camGame.zoom;
			if (zoom <= 0) zoom = 0.001;

			var dx = mouse.x - stagePanLastMouse.x;
			var dy = mouse.y - stagePanLastMouse.y;

			camGame.scroll.x -= dx / zoom;
			camGame.scroll.y -= dy / zoom;

			stagePanLastMouse.set(mouse.x, mouse.y);
		}
	}
	else {
		isDraggingStage = false;
	}

	scrollBar.active = !isDragging && !isDraggingStage;
	

	//if (timelineWindow.hovered) {
		var mousePos = FlxG.mouse.getWorldPosition(camTimeline);
		if (FlxG.mouse.justPressed && timelineWindow.hovered) {
			dragStartPos = FlxG.mouse.getWorldPosition(camTimeline);
			isDragging = false;
		} else if (FlxG.mouse.justReleased) {
			if (isDragging) {
				resetSelection();
				for (e in events) {
					if (!selectedEvents.contains(e)) {
						var x = e.step * ROW_SIZE_X;
						var y = e.timelineIndex * ROW_SIZE_Y;
						if ((selectionBox.x + selectionBox.bWidth > x) && (selectionBox.x < x + 20) && 
							(selectionBox.y + selectionBox.bHeight > y) && (selectionBox.y < y + 20)) {
							selectEvent(e, false);
						}
					}
				}
			}
			dragStartPos = null;
		}

		hoverBox.x = quantStep(mousePos.x / ROW_SIZE_X) * ROW_SIZE_X;
		hoverBox.y = Math.floor(mousePos.y / ROW_SIZE_Y) * ROW_SIZE_Y;

		selectionBox.visible = false;

		if (dragStartPos != null) {
			if (FlxG.mouse.pressed && (Math.abs(mousePos.x - dragStartPos.x) > 20 || Math.abs(mousePos.y - dragStartPos.y) > 20)) {
				isDragging = true;
			}
		}
		if (FlxG.mouse.pressed && dragStartPos != null && isDragging) {
			selectionBox.visible = true;
			selectionBox.x = Math.min(mousePos.x, dragStartPos.x);
			selectionBox.y = Math.min(mousePos.y, dragStartPos.y);
			selectionBox.bWidth = Std.int(Math.abs(mousePos.x - dragStartPos.x));
			selectionBox.bHeight = Std.int(Math.abs(mousePos.y - dragStartPos.y));
		}

		eventRenderer.sizeX = ROW_SIZE_X;
		eventRenderer.sizeY = ROW_SIZE_Y;
		eventRenderer._timelineScrollY = camTimeline.scroll.y;
		/*
		for(i in eventGroup.getVisibleStartIndex()...eventGroup.getVisibleEndIndex()) {
			var obj = eventGroup.members[i];
			obj.x = obj.event.step * ROW_SIZE_X;
			obj.y = obj.timelineIndex * ROW_SIZE_Y;
			obj.updateLength(ROW_SIZE_X);
		}
		*/


		if (FlxG.mouse.justReleased && !isDragging && timelineWindow.hovered) {
			var clickedEvent = null;
			for(i in eventRenderer.getVisibleStartIndex()...eventRenderer.getVisibleEndIndex()) {
				var e = events[i];
				var x = e.step * ROW_SIZE_X;
				var y = e.timelineIndex * ROW_SIZE_Y;
				if ((mousePos.x >= x) && (mousePos.x < x + 20) && (mousePos.y >= y) && (mousePos.y < y + 20)) {
					if (clickedEvent == null) {
						clickedEvent = e;
					}
					break;
				}
			}

			if (FlxG.keys.pressed.CONTROL) {
				if (clickedEvent != null) {
					selectEvent(clickedEvent, false);
				}
			} else {
				if (clickedEvent == null) {
					var step = quantStep((mousePos.x)/ROW_SIZE_X);
					var timelineIndex = Math.floor(mousePos.y / ROW_SIZE_Y);
					if (timelineIndex > -1 && timelineIndex < timelineList.length) {
						addEvent(step, timelineItems[timelineIndex]);
					}
				} else {
					editEvent(clickedEvent, false);
				}
			}
		}

		if (FlxG.mouse.justReleased) {
			isDragging = false;
		}
	//}

	
}

function quantStep(step:Float):Float {
	var stepMulti:Float = 1/(quant/16);
	return Math.floor(step/stepMulti) * stepMulti;
}

function quantStepRounded(step:Float, ?roundRatio:Float = 0.5):Float {
	var stepMulti:Float = 1/(quant/16);
	return ratioRound(step/stepMulti, roundRatio) * stepMulti;
}

function addEvent(step, item) {
	updateEvents(step);
	var e = callEventScriptFromItem(item, "createEventEditor", [item.name, step, item]);
	if (e != null) {
		SortedArrayUtil.addSorted(events, e, function(n){return n.step;});
		refreshEventTimings();

		editEvent(e, true);
	}
	resetSelection();
}

function editEvent(e, justPlaced:Bool) {
	CURRENT_EVENT = e;
	EVENT_EDIT_EVENT_SCRIPT = eventScripts.get(e.type);
	EVENT_EDIT_CALLBACK = function() {
		refreshEventTimings();
	}
	EVENT_EDIT_CANCEL_CALLBACK = function() {
		if (justPlaced) {
			events.remove(e);
			e = null;
		}
		
		refreshEventTimings();
	}
	EVENT_DELETE_CALLBACK = function() {
		if (selectedEvents.contains(e)) selectedEvents.remove(e);
		events.remove(e);
		e = null;
		
		refreshEventTimings();
	}
	var win = new UISubstateWindow(true, 'ModchartEventEditSubstate');
	FlxG.sound.music.pause();
	vocals.pause();
	openSubState(win);
}

function loadSong() {
	Conductor.setupSong(PlayState.SONG);

	CoolUtil.setMusic(FlxG.sound, FlxG.sound.load(Paths.inst(PlayState.SONG.meta.name, PlayState.difficulty)));
	if (PlayState.SONG.meta.needsVoices != false) // null or true
		vocals = FlxG.sound.load(Paths.voices(PlayState.SONG.meta.name, PlayState.difficulty));
	else
		vocals = new FlxSound();
	vocals.group = FlxG.sound.defaultMusicGroup;

	scrollBar.length = Conductor.getStepForTime(FlxG.sound.music.length);
}

function isLegacyModchartXML(xml:Xml):Bool {
	if (xml == null) return false;
	if (xml.get("noteModchart") == "true") return true;
	if (xml.elementsNamed("Shader").hasNext()) return false;
	if (xml.elementsNamed("Modifier").hasNext()) return false;
	if (xml.elementsNamed("FunkinModifier").hasNext()) return false;

	for (list in xml.elementsNamed("Init")) {
		if (list.elementsNamed("Shader").hasNext()) return false;
		if (list.elementsNamed("Modifier").hasNext()) return false;
		if (list.elementsNamed("FunkinModifier").hasNext()) return false;

		for (event in list.elementsNamed("Event")) {
			switch (event.get("type")) {
				case "initShader" | "setCameraShader" | "setShaderProperty" | "initModifier":
					return true;
			}
		}
	}

	for (list in xml.elementsNamed("Events")) {
		for (event in list.elementsNamed("Event")) {
			switch (event.get("type")) {
				case "setShaderProperty" | "setModifierValue" | "tweenShaderProperty" | "tweenModifierValue" | "addCameraZoom" | "addHUDZoom":
					return true;
			}
		}
	}

	return false;
}

function getLegacyCamera(camName:String):FlxCamera {
	if (camName == "hud" || camName == "camHUD") return camHUD;
	if (camName == "other") return camOther;
	return camGame;
}

function legacyShaderColor(shaderName:String):FlxColor {
	var h = 0;
	for (i in 0...shaderName.length) h = (h * 31 + shaderName.charCodeAt(i)) & 0xFFFFFF;
	return FlxColor.fromRGB((h >> 16) & 255, (h >> 8) & 255, h & 255);
}

function ensureLegacyShader(shaderName:String, path:String):CustomShader {
	if (legacyShaders.exists(shaderName)) return legacyShaders.get(shaderName);

	var s = new CustomShader(legacyShaderRoot + path);
	legacyShaders.set(shaderName, s);
	return s;
}

function addLegacyShaderPropertyItem(shaderName:String, shader:CustomShader, propName:String, value:Float) {
	var itemName = shaderName + "." + propName;
	if (timelineIndexMap.exists(itemName)) {
		var existing = timelineItems[timelineIndexMap.get(itemName)];
		existing.defaultValue = value;
		shader.hset(propName, value);
		return;
	}

	var item = createTimelineItem(itemName, "shader", shader);
	item.property = propName;
	item.defaultValue = value;
	shader.hset(propName, value);
}

function initLegacyDefaultShaders() {
	var s = new CustomShader(legacyShaderRoot + "colorswap");
	s.hue = 0;
	legacyShaders.set("colorswap", s);
	addLegacyShaderPropertyItem("colorswap", s, "hue", 0);
}

function processLegacyInitEvent(event:Xml) {
	switch (event.get("type")) {
		case "initShader":
			var shaderName = event.get("name");
			var path = event.get("shader");
			var groupStart = timelineList.length;
			var shader = ensureLegacyShader(shaderName, path);

			var txtPath = "shaders/legacy/" + path + ".txt";
			if (!Assets.exists(txtPath)) txtPath = "shaders/" + path + ".txt";
			if (Assets.exists(txtPath)) {
				for (vari in Assets.getText(txtPath).split("\n")) {
					if (vari == "" || vari.charAt(0) == "#") continue;
					var d = vari.split(" ");
					if (d.length < 2) continue;
					addLegacyShaderPropertyItem(shaderName, shader, d[0], Std.parseFloat(d[1]));
				}
			}

			if (timelineList.length > groupStart) {
				timelineGroups.push({
					startIndex: groupStart,
					endIndex: timelineList.length,
					color: legacyShaderColor(shaderName),
					bg: null
				});
			}

		case "setCameraShader":
			var camShader = legacyShaders.get(event.get("name"));
			if (camShader != null) getLegacyCamera(event.get("camera")).addShader(camShader);

		case "setShaderProperty":
			var shaderName = event.get("name");
			var propName = event.get("property");
			var value = Std.parseFloat(event.get("value"));
			var propShader = legacyShaders.get(shaderName);
			if (propShader == null) {
				propShader = ensureLegacyShader(shaderName, shaderName);
			}
			addLegacyShaderPropertyItem(shaderName, propShader, propName, value);

		case "initModifier":
			legacyNoteModchart = true;
			ensureLegacyEditorRuntime();

			var modName = event.get("name");
			var v = Std.parseFloat(event.get("value"));
			legacyEditorRuntime.call("createModifierFromEvent", [event]);

			if (!timelineIndexMap.exists(modName)) {
				var modItem = createTimelineItem(modName, "legacyModifier", modName);
				modItem.defaultValue = v;
			}
	}
}

function pushLegacyTimelineEvent(event:Xml) {
	var eventType = event.get("type");
	if (!eventScripts.exists(eventType)) {
		trace('legacy modchart: no event script for "${eventType}"');
		return;
	}

	var e = eventScripts.get(eventType).call("eventFromXMLEditor", [event]);
	var n = callEventScriptFromEvent(e, "getItemName", [e]);
	if (timelineIndexMap.exists(n)) {
		events.push(e);
	} else {
		trace('legacy modchart: skipping event for "${n}" (${eventType})');
	}
}

function loadLegacyModchartEditor(xml:Xml, reload:Bool) {
	legacyShaders = ["" => null];
	legacyNoteModchart = xml.get("noteModchart") == "true";
	initLegacyDefaultShaders();

	if (reload) events = [];

	var hasLegacyModifiers = legacyNoteModchart;
	if (!hasLegacyModifiers) {
		for (list in xml.elementsNamed("Init")) {
			for (event in list.elementsNamed("Event")) {
				if (event.get("type") == "initModifier") {
					hasLegacyModifiers = true;
					break;
				}
			}
		}
	}
	if (hasLegacyModifiers) {
		var rt = ensureLegacyEditorRuntime();
		if (rt != null)
			rt.call("prepareLoad", [true]);
	}

	for (list in xml.elementsNamed("Init")) {
		for (event in list.elementsNamed("Event")) {
			processLegacyInitEvent(event);
		}
	}

	for (list in xml.elementsNamed("Events")) {
		for (event in list.elementsNamed("Event")) {
			pushLegacyTimelineEvent(event);
		}
	}

	if (legacyNoteModchart || hasLegacyModifiers) {
		var rt = ensureLegacyEditorRuntime();
		if (rt != null)
			rt.call("initEditor", []);
	}

	trace("legacy modchart editor: timeline=" + timelineList.length + " events=" + events.length + " noteModchart=" + legacyNoteModchart);
}

function loadDefaults() {
	for (name => script in itemScripts) {
		script.call("setupDefaultsEditor", []);
	}
}

function loadEvents(reload) {

	if (!reload) {
		var xmlPath = getModchartSavePath();
		if (!FileSystem.exists(xmlPath)) return;

		xml = Xml.parse(File.getContent(xmlPath)).firstElement();
		loadDefaults();
	} else {
		//clear stuff for reload
		timelineGroups = [];
		timelineItems = [];
		timelineList = [];
		timelineIndexMap.clear();
		if (legacyEditorRuntime != null) {
			legacyEditorRuntime.call("clearNotePaths", []);
			legacyEditorRuntime.call("prepareLoad", [false]);
		}
		for (name => script in itemScripts) {
			script.call("reloadItems", []);
		}
		loadDefaults();
	}

	if (isLegacyModchartXML(xml)) {
		loadLegacyModchartEditor(xml, reload);
	} else {
		for (list in xml.elementsNamed("Init")) {
			for (name => script in itemScripts) {
				script.call("setupItemsFromXMLEditor", [list]);
			}
		}
		if (!reload) {
			for (list in xml.elementsNamed("Events")) {
				for (event in list.elementsNamed("Event")) {
					var eventType = event.get("type");
					if (eventScripts.exists(eventType)) {
						var e = eventScripts.get(eventType).call("eventFromXMLEditor", [event]);
						var n = callEventScriptFromEvent(e, "getItemName", [e]);
						if (timelineIndexMap.exists(n)) {
							events.push(e);
						} else {
							trace("skipping event for \"" + n + "\"");
						}
					}
				}
			}
		}
	}
	for (item in timelineItems) {
		item.currentValue = item.defaultValue;
	}
	for (name => script in itemScripts) {
		script.call("postXMLLoad", [xml]);
	}

	resetValuesToDefault();
	refreshEventTimings();

	if (reload) {
		createTimelineUI();
	}
}

function resetValuesToDefault() {
	for (item in timelineItems) {
		item.currentValue = item.defaultValue;
	}
}

function refreshEventTimings() {
	eventIndexList = [];

	for (item in timelineItems) {
		item.currentValue = item.defaultValue;
		item.lastValue = Math.NEGATIVE_INFINITY;
		eventIndexList.push(-1);
	}
	lastStep = Math.NEGATIVE_INFINITY;

	for (i in 0...events.length) {
		var e = events[i];
		e.lastIndex = -1;
		e.nextIndex = -1;
		
		var n = callEventScriptFromEvent(e, "getItemName", [e]);
		var itemIndex = timelineIndexMap.get(n);
		e.lastValue = timelineItems[itemIndex].currentValue;
		e.timelineIndex = itemIndex;
		if (e.time != null) e.easeIndex = shaderEaseList.indexOf(e.ease);
		if (e.selected == null) e.selected = false;

		if (eventIndexList[itemIndex] == -1) {
			eventIndexList[itemIndex] = i;
		} else {
			var lastIndex = eventIndexList[itemIndex];

			events[lastIndex].nextIndex = i;
			e.lastIndex = lastIndex;
			e.lastValue = events[lastIndex].value;
			if (events[lastIndex].DI_value != null && events[lastIndex].DI_value)
				e.lastValue = -e.lastValue;

			eventIndexList[itemIndex] = i;
		}
	}

	//force update current event indexes
	var currentStep = curStepFloat;
	if (!FlxG.sound.music.playing) {
		currentStep = conductorSprY / ROW_SIZE_X;
	}
	for (itemIndex => index in eventIndexList) {
		var i = index;
		if (events[i] == null) continue;

		if (events[i].nextIndex != -1) {
			while(true) {
				var nextIndex = events[i].nextIndex;
				if (currentStep >= events[nextIndex].step) {
					i = nextIndex;
					if (events[i].nextIndex == -1) {
						break;
					}
				} else {
					break;
				}
			}
		}
		if (events[i].lastIndex != -1) {
			while(true) {
				var lastIndex = events[i].lastIndex;
				if (currentStep < events[lastIndex].step + (events[lastIndex].time != null ? events[lastIndex].time : 0.0)) {
					i = lastIndex;
					if (events[i].lastIndex == -1) {
						break;
					}
				} else {
					break;
				}
			}
		}
		if (i != index) {
			eventIndexList[itemIndex] = i;
		}
	}
}
/*
function createEventObjects() {
	for (i in 0...events.length) {
		var e = events[i];
		var n = callEventScriptFromEvent(e, "getItemName", [e]);

		var obj = new EventObject(e);
		obj.timelineIndex = timelineList.indexOf(n);
		obj.x = e.step * ROW_SIZE_X;
		obj.y = obj.timelineIndex * ROW_SIZE_Y;
		obj.cameras = [camTimeline];
		eventGroup.addSorted(obj);
		obj.updateEvent();
	}
}
*/


function setShaderValue(obj, property:String, value:Float) {
	if (obj == null || property == null || property == "") return;

	try {
		if (Reflect.hasField(obj, "hset")) {
			Reflect.callMethod(obj, Reflect.field(obj, "hset"), [property, value]);
		} else {
			Reflect.setProperty(obj, property, value);
		}
	} catch(e:Dynamic) {
	}
}

function getShaderFloat(obj, property:String, fallback:Float = 0):Float {
	if (obj == null || property == null || property == "") return fallback;

	try {
		var value = Reflect.getProperty(obj, property);
		if (value == null) value = Reflect.field(obj, property);
		if (value == null) return fallback;

		var parsed = Std.parseFloat(Std.string(value));
		if (Math.isNaN(parsed)) return fallback;

		return parsed;
	} catch(e:Dynamic) {
		return fallback;
	}
}
function isITimeItem(item):Bool {
	if (item == null) return false;

	if (item.property == "iTime")
		return true;

	if (item.name != null) {
		var parts = Std.string(item.name).split(".");
		if (parts.length > 0 && parts[parts.length - 1] == "iTime")
			return true;
	}

	return false;
}

function updateShaderITime() {
	for (i => item in timelineItems) {
		if (!isITimeItem(item)) continue;
		if (item.object == null) continue;

		var value:Float = Conductor.songPosition * 0.001;

		try {
			item.object.hset("iTime", value);
		} catch(e:Dynamic) {
			try {
				Reflect.callMethod(item.object, Reflect.field(item.object, "hset"), ["iTime", value]);
			} catch(e2:Dynamic) {
			}
		}

		item.currentValue = value;
		item.lastValue = value;

		if (timelineUIList[i] != null && timelineUIList[i].valueText != null) {
			timelineUIList[i].valueText.text = Std.string(FlxMath.roundDecimal(value, 2));
		}
	}
}

function getStageHueTimelineItem() {
	if (timelineIndexMap.exists("stageHue.hue"))
		return timelineItems[timelineIndexMap.get("stageHue.hue")];
	return null;
}

function applyStageHuePreview(item) {
	if (item == null || item.name != "stageHue.hue" || item.object == null) return;

	setShaderValue(item.object, "hue", item.currentValue);
	setExperimentalRTXHue(item.currentValue);

	if (stage == null || stage.stageSprites == null) return;
	for (name => obj in stage.stageSprites) {
		if (obj != null) {
			obj.shader = item.object;
		}
	}
}

var lastStep = Math.NEGATIVE_INFINITY;
function updateEvents(?forceStep:Float = null) {

	var currentStep = curStepFloat;
	if (!FlxG.sound.music.playing) {
		currentStep = conductorSprY / ROW_SIZE_X;
	}
	if (forceStep != null) currentStep = forceStep;

	for (itemIndex => index in eventIndexList) {
		var i = index;
		if (events[i] == null) continue;

		if (lastStep != currentStep) {

			if (currentStep > lastStep) {
				//check for next event
				if (events[i].nextIndex != -1) {
					while(true) {
						var nextIndex = events[i].nextIndex;
						if (currentStep >= events[nextIndex].step) {
							i = nextIndex;
							if (events[i].nextIndex == -1) {
								break;
							}
						} else {
							break;
						}
					}
				}
			} else {
				//check for last (for rewinding)
				if (events[i].lastIndex != -1) {
					while(true) {
						var lastIndex = events[i].lastIndex;
						if (currentStep < events[lastIndex].step + (events[lastIndex].time != null ? events[lastIndex].time : 0.0)) {
							i = lastIndex;
							if (events[i].lastIndex == -1) {
								break;
							}
						} else {
							break;
						}
					}
				}
			}
		}

		if (i != index) {
			eventIndexList[itemIndex] = i;
		}

		var e = events[i];
		if (currentStep >= e.step) {
			var item = timelineItems[itemIndex];
			callEventScriptFromItem(item, "updateEventEditor", [currentStep, e, item]);
		} else {
			timelineItems[itemIndex].currentValue = e.lastValue;
		}
	}

	for (i => item in timelineItems) {
		if (item.currentValue != item.lastValue) {
			item.lastValue = item.currentValue;
			callItemScriptFromItem(item, "updateItem", [item, i]);
		}
		applyStageHuePreview(item);
	}
	updateShaderITime();
	lastStep = currentStep;


}


function buildXMLFromEvents(?newInitEvents = null, ?packaged = false) {
	if (packaged == null) packaged = false;
	var newXml = Xml.createElement("Modchart");
	var initEvents = newInitEvents == null ? Xml.createElement("Init") : newInitEvents;
	var xmlEvents = Xml.createElement("Events");
	
	//copy init events
	if (xml != null && newInitEvents == null) {
		for (list in xml.elementsNamed("Init")) {
			for (name => script in itemScripts) {
				script.call("copyXMLItems", [list, initEvents, packaged]);
			}
		}
	}

	for (i in 0...events.length) {
		var e = events[i];
		var node = Xml.createElement("Event");
		node.set("type", e.type);
		node.set("step", e.step);

		callEventScriptFromEvent(e, "eventToXMLEditor", [node, e]);

		xmlEvents.addChild(node);
	}

	newXml.addChild(initEvents);
    newXml.addChild(xmlEvents);
	refreshEventTimings();
	return newXml;
}



function normalizeModchartPath(path:String):String {
	return path == null ? "" : path.split("\\").join("/");
}

function sameModchartPath(a:String, b:String):Bool {
	return normalizeModchartPath(a).toLowerCase() == normalizeModchartPath(b).toLowerCase();
}

var cachedModchartSavePath:String = null;
var cachedModchartSong:String = null;
var cachedModchartDifficulty:String = null;

function getDirectSongFolder(parent:String, songName:String, ?fileName:String, ?skipFolder:String):String {
	if (parent == null || !FileSystem.exists(parent) || !FileSystem.isDirectory(parent)) return null;

	for (entry in FileSystem.readDirectory(parent)) {
		var songFolder = normalizeModchartPath(parent) + "/" + entry + "/songs/" + songName;
		if (skipFolder != null && sameModchartPath(songFolder, skipFolder)) continue;
		if (!FileSystem.exists(songFolder) || !FileSystem.isDirectory(songFolder)) continue;
		if (fileName == null || FileSystem.exists(songFolder + "/" + fileName)) return songFolder;
	}

	return null;
}

function findSongFolderInDir(dir:String, songName:String, ?skipFolder:String):String {
	if (dir == null || !FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return null;

	var normalizedDir = normalizeModchartPath(dir);
	if (StringTools.endsWith(normalizedDir, "/songs/" + songName) && (skipFolder == null || !sameModchartPath(normalizedDir, skipFolder)))
		return normalizedDir;

	for (entry in FileSystem.readDirectory(dir)) {
		var path = normalizedDir + "/" + entry;
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			var result = findSongFolderInDir(path, songName, skipFolder);
			if (result != null) return result;
		}
	}

	return null;
}

function findSongFolderWithFile(dir:String, songName:String, fileName:String, ?skipFolder:String):String {
	if (dir == null || !FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return null;

	var normalizedDir = normalizeModchartPath(dir);
	if (StringTools.endsWith(normalizedDir, "/songs/" + songName) && FileSystem.exists(normalizedDir + "/" + fileName) && (skipFolder == null || !sameModchartPath(normalizedDir, skipFolder)))
		return normalizedDir;

	for (entry in FileSystem.readDirectory(dir)) {
		var path = normalizedDir + "/" + entry;
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			var result = findSongFolderWithFile(path, songName, fileName, skipFolder);
			if (result != null) return result;
		}
	}

	return null;
}

function getModchartSavePath():String {
	var root = normalizeModchartPath(Paths.getAssetsRoot());
	var songName = PlayState.SONG.meta.name;
	if (cachedModchartSavePath != null && cachedModchartSong == songName && cachedModchartDifficulty == PlayState.difficulty)
		return cachedModchartSavePath;

	var defaultFolder = root + "/songs/" + songName;
	var contentRoot = root + "/content";
	var difficultyFile = "modchart-" + PlayState.difficulty + ".xml";
	var fileName = "modchart.xml";

	var songFolder = getDirectSongFolder(contentRoot, songName, difficultyFile);
	if (songFolder == null) songFolder = getDirectSongFolder(root, songName, difficultyFile, defaultFolder);
	if (songFolder == null && FileSystem.exists(defaultFolder + "/" + difficultyFile))
		songFolder = defaultFolder;

	if (songFolder != null) fileName = difficultyFile;
	else {
		songFolder = getDirectSongFolder(contentRoot, songName, fileName);
		if (songFolder == null) songFolder = getDirectSongFolder(root, songName, fileName, defaultFolder);
		if (songFolder == null && FileSystem.exists(defaultFolder + "/" + fileName))
			songFolder = defaultFolder;
		if (songFolder == null) songFolder = getDirectSongFolder(contentRoot, songName);
		if (songFolder == null) songFolder = getDirectSongFolder(root, songName, null, defaultFolder);
		if (songFolder == null) {
			songFolder = findSongFolderWithFile(contentRoot, songName, difficultyFile);
			if (songFolder == null) songFolder = findSongFolderWithFile(root, songName, difficultyFile, defaultFolder);
			if (songFolder != null) fileName = difficultyFile;
		}
		if (songFolder == null) songFolder = findSongFolderWithFile(contentRoot, songName, fileName);
		if (songFolder == null) songFolder = findSongFolderWithFile(root, songName, fileName, defaultFolder);
		if (songFolder == null) songFolder = findSongFolderInDir(contentRoot, songName);
		if (songFolder == null) songFolder = findSongFolderInDir(root, songName, defaultFolder);
		if (songFolder == null && FileSystem.exists(defaultFolder))
			songFolder = defaultFolder;
	}

	if (songFolder == null) songFolder = defaultFolder;
	cachedModchartSavePath = songFolder + "/" + fileName;
	cachedModchartSong = songName;
	cachedModchartDifficulty = PlayState.difficulty;
	return cachedModchartSavePath;
}

function _save() {
	xml = buildXMLFromEvents();
	CoolUtil.safeSaveFile(getModchartSavePath(), Printer.print(xml, true));
}
function _save_opt() {
	xml = buildXMLFromEvents();
	CoolUtil.safeSaveFile(getModchartSavePath(), Printer.print(xml, false));
}
function _export_package() {
	var packagedXML = buildXMLFromEvents(null, true);
	CoolUtil.safeSaveFile("testpackage.xml", Printer.print(packagedXML, true));
}
function _exit() {
	var state = new EditorTreeMenu();
	state.scriptName = "ModchartEditorSongSelectState";
	FlxG.switchState(state);
}
function _modchart_edititems() {
	CURRENT_XML = xml;
	ITEM_EDIT_LOADED_SCRIPTS = itemScripts;
	ITEM_EDIT_SAVE_CALLBACK = function() {
		xml = buildXMLFromEvents(ITEM_EDIT_SAVED_INIT_EVENTS);
		xml = buildXMLFromEvents(); //do twice just in case

		loadEvents(true);
	}
	var win = new UISubstateWindow(true, 'ModchartEditDataSubstate');
	FlxG.sound.music.pause();
	vocals.pause();
	openSubState(win);
}

function _view_fullscreen() {
	_fullscreen = !_fullscreen;
	for (name => script in itemScripts) {
		script.call("onFullscreen", [_fullscreen]);
	}
}

function _view_reset_camera(_) {
	resetEditorCamera();
}

function _view_reload_editor(_) {
	var state = new UIState();
	state.scriptName = "ModchartEditor";
	FlxG.switchState(state);
}

function _view_downscroll() {
	downscroll = !downscroll;
	camHUD.downscroll = downscroll;
	refreshEventTimings();

	for (name => script in itemScripts) {
		script.call("onFlipScroll", [downscroll]);
	}
}

function _view_experimental_gameplay_preview(_) {
	experimentalGameplayPreview = !experimentalGameplayPreview;
	if (experimentalGameplayPreview) {
		createExperimentalGameplayPreview();
		resetEditorCamera();
	} else {
		clearExperimentalGameplayPreview();
		resetEditorCamera();
	}
}

function _song_start(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition = 0;
}
function _song_end(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition = FlxG.sound.music.length;
}

function _song_muteinst(t) {
	FlxG.sound.music.volume = FlxG.sound.music.volume > 0 ? 0 : 1;
	t.icon = 1 - Std.int(Math.ceil(FlxG.sound.music.volume));
}
function _song_mutevoices(t) {
	vocals.volume = vocals.volume > 0 ? 0 : 1;
	//for (strumLine in strumLines.members) strumLine.vocals.volume = strumLine.vocals.volume > 0 ? 0 : 1;
	t.icon = 1 - Std.int(Math.ceil(vocals.volume));
}

function _playback_speed_change(change) {
	var v = FlxG.sound.music.pitch + change;
	if (v < 0.25) v = 0.25;
	if (v > 2.0) v = 2.0;
	FlxG.sound.music.pitch = vocals.pitch = v;
}

function _playback_speed_raise(_) _playback_speed_change(0.25);
function _playback_speed_reset(_) FlxG.sound.music.pitch = vocals.pitch = 1;
function _playback_speed_lower(_) _playback_speed_change(-0.25);

function _playback_play() {
	if (Conductor.songPosition >= FlxG.sound.music.length - Conductor.songOffset) return;

	if (FlxG.sound.music.playing) {
		FlxG.sound.music.pause();
		vocals.pause();
		//for (strumLine in strumLines.members) strumLine.vocals.pause();
	} else {
		FlxG.sound.music.play(true, Conductor.songPosition + Conductor.songOffset);
		vocals.play(true, FlxG.sound.music.getActualTime());
		//vocals.time = FlxG.sound.music.time = Conductor.songPosition + Conductor.songOffset * 2;
		//for (strumLine in strumLines.members) {
		//	strumLine.vocals.play();
		//	strumLine.vocals.time = vocals.time;
		//}
	}
}
function _playback_back(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition -= (Conductor.beatsPerMeasure * __crochet);
}
function _playback_forward(_) {
	if (FlxG.sound.music.playing) return;
	Conductor.songPosition += (Conductor.beatsPerMeasure * __crochet);
}

function selectEvent(e, reset:Bool) {
	if (reset) {
		resetSelection();
	}
	SortedArrayUtil.addSorted(selectedEvents, e, function(n){return n.step;});
	e.selected = true;
}
function resetSelection() {
	for (event in selectedEvents) {
		event.selected = false;
	}
	selectedEvents = [];
}


function _edit_undo() {

}
function _edit_redo() {

}
function _edit_copy() {
	clipboard = [];
	for (event in selectedEvents) {
		clipboard.push(callEventScriptFromEvent(event, "copyEventEditor", [event]));
	}
	clipboard.sort(function(a, b) {
		if(a.step < b.step) return -1;
		else if(a.step > b.step) return 1;
		else return 0;
	});
}
function _edit_paste() {
	resetSelection();
	if (clipboard.length > 0) {
		var diff = curStep - clipboard[0].step; //TODO: maybe switch to use mouse pos instead?

		//trace(clipboard[0].step);
		//trace(diff);

		for (event in clipboard) {
			var e = callEventScriptFromEvent(event, "copyEventEditor", [event]);
			e.step += diff;
			SortedArrayUtil.addSorted(events, e, function(n){return n.step;});
			selectEvent(e, false);
		}

		refreshEventTimings();
	}
}
function _edit_cut() {
	_edit_copy();
	_edit_delete();
}
function _edit_delete() {
	for (e in selectedEvents) {
		events.remove(e);
	}
	selectedEvents = [];
	refreshEventTimings();
}
function _edit_shiftleft() {
	for (event in selectedEvents) {
		event.step -= 1;
		if (event.step < 0) event.step = 0;
	}
	sortAllEvents();
	refreshEventTimings();
}
function _edit_shiftright() {
	for (event in selectedEvents) {
		event.step += 1;
	}
	sortAllEvents();
	refreshEventTimings();
}

function sortAllEvents() {
	events.sort(function(a, b) {
		if(a.step < b.step) return -1;
		else if(a.step > b.step) return 1;
		else return 0;
	});
}


inline function _snap_increasesnap(_) changequant(1);
inline function _snap_decreasesnap(_) changequant(-1);
inline function _snap_resetsnap(_) setquant(16);

inline function changequant(change:Int) {quant = quants[FlxMath.wrap(quants.indexOf(quant) + change, 0, quants.length-1)]; buildSnapsUI();};
inline function setquant(newquant:Int) {quant = newquant; buildSnapsUI();}

function buildSnapsUI() {
	var snapsTopButton = topMenuSpr.members[snapIndex];
	var newChilds:Array<UIContextMenuOption> = [
		{
			label: "â†‘ Grid Snap",
			keybind: [FlxKey.X],
			onSelect: _snap_increasesnap
		},
		{
			label: "Reset Grid Snap",
			onSelect: _snap_resetsnap
		},
		{
			label: "â†“ Grid Snap",
			keybind: [FlxKey.Z],
			onSelect: _snap_decreasesnap
		},
		null
	];

	for (_quant in quants)
		newChilds.push({
			label: _quant + 'x Grid Snap',
			onSelect: (_) -> {setquant(_quant); buildSnapsUI();},
			icon: _quant == quant ? 1 : 0
		});

	topMenu[snapIndex].childs = newChilds;

	if (snapsTopButton != null) snapsTopButton.contextMenu = newChilds;
	return newChilds;
}

