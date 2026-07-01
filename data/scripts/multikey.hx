import funkin.backend.scripting.events.StrumCreationEvent;
import funkin.backend.scripting.events.DirectionAnimEvent;
import funkin.system.FunkinSprite;
import funkin.backend.scripting.events.PlayAnimEvent;
import funkin.backend.scripting.events.AmountEvent;
import funkin.backend.scripting.EventManager;
import flixel.input.keyboard.FlxKey;
import funkin.backend.chart.Chart;
import haxe.Json;
import haxe.xml.Access;
import haxe.xml.Parser;
#if ENCRYPTED_FILES
import voiid.FileEncrypt;
#end
import haxe.xml.Printer;
#if !mobile
import flixel.ui.FlxButton;
#end
import Xml;
import Int; 
import String;
import Array;

public var maniaChanges:Array<Array<Dynamic>> = [];

public var strumLineKeyCounts:Int = [4,4,4];
public var strumLineSwagWidths:Float = [112,112,112];
public var strumLineNoteScales:Float = [0.7,0.7,0.7];

var changingMania = false;
var playFadeIn = true;
var strumLineHasSustains:Array<Bool> = [];

var maxKeyCount = 0;


public var multikeyScales:Array<Float> = [];
public var multikeyWidths:Array<Float> = [];
public var multikeyOffsets:Array<Float> = [];


public var multikeySingDirs:Array<Array<Int>> = [];
public var multikeySplashIDs:Array<Array<Int>> = [];
public var multikeyStrumAnims:Array<Array<String>> = [];
public var multikeyNoteAnims:Array<Array<String>> = [];

var multikeyMobileHitboxes = [];

public var multikeyXML = null;

function loadMultikeyData()
{
	var xmlPath = Paths.xml('multikeyData');
	if (!Assets.exists(xmlPath))
	{
		trace('multikey data is missing!');
		return;
	}
		
	var plainXML = Assets.getText(xmlPath);
	var mainXML = Xml.parse(plainXML);
	multikeyXML = mainXML;
	
	var kc = 0;
	for (keyData in mainXML.elementsNamed("keyData"))
	{
		for (keyGroup in keyData.elementsNamed("keyGroup"))
		{
			multikeyScales.push(Std.parseFloat(keyGroup.get("scale")));
			multikeyWidths.push(Std.parseFloat(keyGroup.get("gapWidth")));
			multikeyOffsets.push(Std.parseFloat(keyGroup.get("xOffset")));

			multikeySingDirs.push([]);
			multikeySplashIDs.push([]);
			multikeyStrumAnims.push([]);
			multikeyNoteAnims.push([]);
			for (key in keyGroup.elementsNamed("key")) 
			{
				multikeySingDirs[kc].push(Std.parseInt(key.get("singDir")));
				multikeySplashIDs[kc].push(Std.parseInt(key.get("splashID")));
				multikeyStrumAnims[kc].push([key.get("strumStatic"),key.get("strumConfirm"),key.get("strumPress")]);
				multikeyNoteAnims[kc].push([key.get("note"),key.get("noteHold"),key.get("noteHoldEnd")]);
			}
			kc++;
		}
	}
	maxKeyCount = kc;
}
public function getKeyCountIndex(strumlineID:Int)
{
	return getCappedKeyCount(strumlineID)-1;
}
public function getCappedKeyCount(strumlineID:Int)
{
	var kc = strumLineKeyCounts[strumlineID];
	if (kc > multikeyScales.length) 
		kc = multikeyScales.length;
	return kc;
}

var controlsList:Array<Array<Int>> = [];
var controlsListP2:Array<Array<Int>> = [];

var controlsGamepadList:Array<Array<Int>> = [];
var controlsGamepadListP2:Array<Array<Int>> = [];

function onPreGenerateStrums(event)
{
    
	event.cancel();
	for(p in 0...strumLines.members.length)
		strumLines.members[p].generateStrums(strumLineKeyCounts[p]);


	scripts.event("onPostGenerateStrums", event);
}

function onStrumCreation(event) 
{

    event.cancel();

	var kc = getKeyCountIndex(event.player);

    var strum = event.strum;
    strum.frames = Paths.getFrames(event.sprite);
    strum.antialiasing = true;
    strum.setGraphicSize(Std.int((strum.width * strumLineNoteScales[event.player] * strumLines.members[event.player].strumScale)));

    strum.animation.addByPrefix('static', multikeyStrumAnims[kc][strum.ID][0]);
    strum.animation.addByPrefix('pressed', multikeyStrumAnims[kc][strum.ID][2], 24, false);
    strum.animation.addByPrefix('confirm', multikeyStrumAnims[kc][strum.ID][1], 24, false);

		
	var sl = PlayState.SONG.strumLines[event.player];
	var strOffset:Float = sl.strumLinePos == null ? (sl.type == 1 ? 0.75 : 0.25) : sl.strumLinePos;

	var startingPos = sl.strumPos == null ?
		FlxPoint.get((FlxG.width * strOffset) - ((Note.swagWidth * (sl.strumScale == null ? 1 : sl.strumScale)) * 2), this.strumLine.y) :
		FlxPoint.get(sl.strumPos[0] == 0 ? ((FlxG.width * strOffset) - ((Note.swagWidth * (sl.strumScale == null ? 1 : sl.strumScale)) * 2)) : sl.strumPos[0], sl.strumPos[1]);

	strum.x = startingPos.x + ((strumLineSwagWidths[event.player] * strumLines.members[event.player].strumScale) * strum.ID);
    strum.x += multikeyOffsets[kc];
    strum.updateHitbox();

	
	

    
	var curControls = controlsList[kc];
	var curControlsP2 = controlsListP2[kc];
	var curControlsGamepad = controlsGamepadList[kc];
	var curControlsGamepadP2 = controlsGamepadListP2[kc];
	if (PlayState.coopMode)
	{
		var controlGroup = curControls;
		if (event.player == 0)
			controlGroup = curControlsP2;
		strum.getPressed = function(strumline:StrumLine)
		{
			return FlxG.keys.anyPressed([controlGroup[strum.ID%controlGroup.length]]);
		}
		strum.getJustPressed = function(strumline:StrumLine)
		{
			return FlxG.keys.anyJustPressed([controlGroup[strum.ID%controlGroup.length]]);
		}
		strum.getJustReleased = function(strumline:StrumLine)
		{
			return FlxG.keys.anyJustReleased([controlGroup[strum.ID%controlGroup.length]]);
		}
	}  
	else 
	{
		
		strum.getPressed = function(strumline:StrumLine)
		{
			var gamepadPress = false;
			var gamepad = FlxG.gamepads.getFirstActiveGamepad();
			if (gamepad != null && gamepad.anyPressed([curControlsGamepad[strum.ID%curControlsGamepad.length], curControlsGamepadP2[strum.ID%curControlsGamepad.length]]))
				gamepadPress = true;
				
			return FlxG.keys.anyPressed([curControls[strum.ID%curControls.length], curControlsP2[strum.ID%curControlsP2.length]]) || gamepadPress #if mobile || multikeyMobileHitboxes[strum.ID % multikeyMobileHitboxes.length].pressed #end;
		}
		strum.getJustPressed = function(strumline:StrumLine)
		{
			var gamepadPress = false;
			var gamepad = FlxG.gamepads.getFirstActiveGamepad();
			if (gamepad != null && gamepad.anyJustPressed([curControlsGamepad[strum.ID%curControlsGamepad.length], curControlsGamepadP2[strum.ID%curControlsGamepad.length]]))
				gamepadPress = true;

			return FlxG.keys.anyJustPressed([curControls[strum.ID%curControls.length], curControlsP2[strum.ID%curControlsP2.length]]) || gamepadPress #if mobile || multikeyMobileHitboxes[strum.ID % multikeyMobileHitboxes.length].justPressed #end;
		}
		strum.getJustReleased = function(strumline:StrumLine)
		{
			var gamepadPress = false;
			var gamepad = FlxG.gamepads.getFirstActiveGamepad();
			if (gamepad != null && gamepad.anyJustReleased([curControlsGamepad[strum.ID%curControlsGamepad.length], curControlsGamepadP2[strum.ID%curControlsGamepad.length]]))
				gamepadPress = true;

			return FlxG.keys.anyJustReleased([curControls[strum.ID%curControls.length], curControlsP2[strum.ID%curControlsP2.length]]) || gamepadPress #if mobile || multikeyMobileHitboxes[strum.ID % multikeyMobileHitboxes.length].justReleased #end;
		}
	}

    if (changingMania)
    {
        event.__doAnimation = playFadeIn;
    }
}

function onNoteCreation(event) {

	event.cancel();

	if (maniaChanges[event.strumLineID].length > 0)
	{
		for (mc in maniaChanges[event.strumLineID])
		{
			if (event.note.strumTime > mc[0])
			{
				strumLineKeyCounts[event.strumLineID] = mc[1]; 
			}
		}
	}

	var kc = getKeyCountIndex(event.strumLineID);

	var note = event.note;
	note.splash = getSplashForTime(note.strumTime);
	note.frames = Paths.getFrames(event.noteSprite);
	if (note.isSustainNote && event.strumLineID >= 0 && event.strumLineID < strumLineHasSustains.length)
		strumLineHasSustains[event.strumLineID] = true;

	var strumScale = strumLines.members[event.strumLineID].strumScale;

	note.noteData = note.noteData % strumLineKeyCounts[event.strumLineID];

    note.animation.addByPrefix('scroll', multikeyNoteAnims[kc][note.noteData][0]);
    note.animation.addByPrefix('hold', multikeyNoteAnims[kc][note.noteData][1]);
    note.animation.addByPrefix('holdend', multikeyNoteAnims[kc][note.noteData][2]);
    if (note.isSustainNote)
		note.scale.set(multikeyScales[kc]*strumScale, event.noteScale);
    else 
        note.scale.set(multikeyScales[kc]*strumScale, multikeyScales[kc]*strumScale);

	note.updateHitbox();

    if (maniaChanges[event.strumLineID] != null && maniaChanges[event.strumLineID].length > 0)
        strumLineKeyCounts[event.strumLineID] = maniaChanges[event.strumLineID][0][1]; 
}

function create()
{
	loadMultikeyData();
	cacheSplashSkinChanges();
    strumLineKeyCounts = [];
	maniaChanges = [];
	strumLineHasSustains = [];
	for (i in 0...strumLines.members.length)
	{
		strumLineKeyCounts.push(4);
		maniaChanges.push([]);
		strumLineHasSustains.push(false);
	}
    
	var chartPath = Paths.chart(PlayState.SONG.meta.name, PlayState.difficulty);
	var data:SwagSong = null;
	if (Assets.exists(chartPath))
	{
		#if ENCRYPTED_FILES
		var t = FileEncrypt.decryptString(chartPath);
		#else 
		var t = Assets.getText(chartPath);
		#end
		data = Json.parse(t);
	}

	var doParse = true;
	if (data.codenameChart != null && data.codenameChart)
	{
		doParse = false; 
	}

	if (PlayState.SONG.meta.customValues != null)
	{
		
		if (Reflect.getProperty(PlayState.SONG.meta.customValues, PlayState.difficulty + "_keyCount") != null)
		{
			var kc = Std.parseInt(Reflect.getProperty(PlayState.SONG.meta.customValues, PlayState.difficulty + "_keyCount")); 

			for (i in 0...strumLines.members.length)
			{
				maniaChanges[i].push([-10000, kc]); 
			}
		}
	}

	
	for (event in events)
	{
		if (event.name == "Set Key Count" || event.name == "Change Key Count") 
		{
			if (event.name == "Change Key Count" || event.params[2])
			{
				for (i in 0...strumLines.members.length)
				{
					maniaChanges[i].push([event.time, event.params[0]]); 
				}
			}
			else
			{
				maniaChanges[event.params[3]].push([event.time, event.params[0]]);
			}
		}
	}

	if (maniaChanges.length > 0)
	{
		for (i in 0...maniaChanges.length)
		{
			if (maniaChanges[i].length > 0)
			{
				
				maniaChanges[i].sort(function(a, b) {
					if(a[0] < b[0]) return -1;
					else if(a[0] > b[0]) return 1;
					else return 0;
				});
				strumLineKeyCounts[i] = maniaChanges[i][0][1]; 
				maniaChanges[i][0][0] = -10000;
			}
		}
	}


	if (doParse) 
	{
		
		for (str in PlayState.SONG.strumLines) 
		{
			while(str.notes.length > 0)
				str.notes.remove(str.notes[0]);
		}
			
		
		if (data.song.notes != null)
		{
			for (section in data.song.notes)
			{
				if (section != null)
				{
					for(note in section.sectionNotes)
					{
						

						var daStrumTime:Float = note[0];

						var keyCount = 4;
						var playerKeyCount = 4;
						if (maniaChanges[0].length > 0) 
						{
							for (mc in maniaChanges[0])
							{
								if (daStrumTime > mc[0])
								{
									keyCount = mc[1];
								}
							}
						}
						if (maniaChanges[1].length > 0) 
						{
							for (mc in maniaChanges[1])
							{
								if (daStrumTime > mc[0])
								{
									playerKeyCount = mc[1];
								}
							}
						}

						var daNoteData:Int = Std.int(note[1] % (keyCount+playerKeyCount));

						if (section.mustHitSection && daNoteData >= playerKeyCount)
						{
							daNoteData -= playerKeyCount;
							daNoteData %= keyCount;
						}
						else if (!section.mustHitSection && daNoteData >= keyCount)
						{
							daNoteData -= keyCount;
							daNoteData %= playerKeyCount;
						}

						var daNoteType:Int = 0;
						var gottaHitNote:Bool = section.mustHitSection;
						if(note[1] >= (!gottaHitNote ? keyCount : playerKeyCount))
							gottaHitNote = !section.mustHitSection;

						var noteTypeSuffix:String = "";
		
						if (note.length > 2) {
							if (Std.isOfType(note[3], Int)) {
								noteTypeSuffix = "char["+Std.string(note[3])+"]";
								daNoteType = Chart.addNoteType(PlayState.SONG, noteTypeSuffix);
							} else if (Std.isOfType(note[3], String)) {
								daNoteType = Chart.addNoteType(PlayState.SONG, note[3]);
							} else if (Std.isOfType(note[3], Array)) {
								noteTypeSuffix = "char"+Std.string(note[3]);
								daNoteType = Chart.addNoteType(PlayState.SONG, noteTypeSuffix);
							}
						} else {
							if(data.noteTypes != null)
								daNoteType = Chart.addNoteType(PlayState.SONG, data.noteTypes[daNoteType-1]);
						}
						if (note[4] != null && note[4] != "default") {
							daNoteType = Chart.addNoteType(PlayState.SONG, note[4]+noteTypeSuffix);
						}
		
						PlayState.SONG.strumLines[gottaHitNote ? 1 : 0].notes.push({
							time: daStrumTime,
							id: daNoteData,
							type: daNoteType,
							sLen: note[2]
						});
					}
				}
			}
		}     
	}

	for (i in 0...maniaChanges.length)
	{
		if (maniaChanges[i].length > 0)
		{
			strumLineKeyCounts[i] = maniaChanges[i][0][1]; 
		}
	}
		
	controlsList = []; 
	controlsListP2 = [];
	controlsGamepadList = []; 
	controlsGamepadListP2 = [];
	
	importScript("data/scripts/controlsCheck.hx");
	for (kc in 0...maxKeyCount)
	{
		controlsList.push([]);
		controlsListP2.push([]);
		controlsGamepadList.push([]);
		controlsGamepadListP2.push([]);
        
        for (i in 0...(kc+1))
        {
			if (kc == 3) 
			{
				switch(i)
				{
					case 0:
						controlsList[kc].push(Options.P1_NOTE_LEFT[0]);
						controlsListP2[kc].push(Options.P2_NOTE_LEFT[0]);
					case 1:
						controlsList[kc].push(Options.P1_NOTE_DOWN[0]);
						controlsListP2[kc].push(Options.P2_NOTE_DOWN[0]);
					case 2:
						controlsList[kc].push(Options.P1_NOTE_UP[0]);
						controlsListP2[kc].push(Options.P2_NOTE_UP[0]);
					case 3:
						controlsList[kc].push(Options.P1_NOTE_RIGHT[0]);
						controlsListP2[kc].push(Options.P2_NOTE_RIGHT[0]);
				}
			}
			else
			{
				var k = Reflect.getProperty(FlxG.save.data, (kc+1) + "k" + i);
				controlsList[kc].push(k);
				var kp2 = Reflect.getProperty(FlxG.save.data, (kc+1) + "k" + i + "p2");
				controlsListP2[kc].push(kp2);
			}


			var kg = Reflect.getProperty(FlxG.save.data, (kc+1) + "k" + i + "gamepad");
			if (kg == -1)
				kg = -100;
            controlsGamepadList[kc].push(kg);
            var kgp2 = Reflect.getProperty(FlxG.save.data, (kc+1) + "k" + i + "gamepadP2");
			if (kgp2 == -1)
				kgp2 = -100;
            controlsGamepadListP2[kc].push(kgp2);
        }
	}
	
	
    strumLineSwagWidths = [];
	strumLineNoteScales = [];
	for (i in 0...strumLineKeyCounts.length)
	{
		strumLineSwagWidths.push(multikeyWidths[getKeyCountIndex(i)] * 0.7);
		strumLineNoteScales.push(multikeyScales[getKeyCountIndex(i)]);
	}
}
function postCreate()
{
	#if mobile
	for (i in 0...strumLineKeyCounts.length)
		if (!strumLines.members[i].cpu)
			loadMobileHitboxes(strumLineKeyCounts[i]);
	#end
}

var splashScaleMult = 1.428; 
var splashScales:Map<String, Float> = [];
var splashSkinChanges:Array<Dynamic> = [];
var defaultSplashSkinPrefix:String = "voiid/";

function normalizeSplashPrefix(prefix:String):String {
	if (prefix == null || prefix == "" || prefix == "codename/")
		return "";
	return prefix;
}

function splashNameForPrefix(prefix:String):String {
	prefix = normalizeSplashPrefix(prefix);
	if (prefix == "")
		return Assets.exists(Paths.xml("splashes/codename")) ? "codename" : "default";
	if (prefix == "voiid/")
		return Assets.exists(Paths.xml("splashes/voiid")) ? "voiid" : "default";

	var name = StringTools.endsWith(prefix, "/") ? prefix.substr(0, prefix.length - 1) : prefix;
	if (Assets.exists(Paths.xml("splashes/" + name)))
		return name;

	return "default";
}

function cacheSplashSkinChanges() {
	splashSkinChanges = [];
	for (event in events) {
		if (event.name == "Change UI Skin") {
			splashSkinChanges.push({
				time: event.time,
				splash: splashNameForPrefix(event.params[1])
			});
		}
	}

	if (splashSkinChanges.length > 0) {
		splashSkinChanges.sort(function(a, b) {
			if(a.time < b.time) return -1;
			else if(a.time > b.time) return 1;
			else return 0;
		});
	}
}

function getSplashForTime(time:Float):String {
	var splash = splashNameForPrefix(defaultSplashSkinPrefix);
	for (change in splashSkinChanges) {
		if (time >= change.time)
			splash = change.splash;
		else
			break;
	}
	return splash;
}

function getShaderFloat(shader:Dynamic, name:String, fallback:Float = 0):Float {
	if (shader == null) return fallback;

	try {
		var value = Reflect.getProperty(shader, name);
		if (value == null) value = Reflect.field(shader, name);
		if (value == null) return fallback;

		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	} catch(e:Dynamic) {
		return fallback;
	}
}

function getVisualStrumCenterX(strum:Dynamic):Float {
	if (strum == null) return FlxG.width * 0.5;

	var center = strum.x + (strum.width * 0.5);
	var shader = Reflect.field(strum, "shader");
	if (shader != null) {
		var shaderCenter = getShaderFloat(shader, "screenX", Math.NaN);
		if (!Math.isNaN(shaderCenter))
			center = shaderCenter;

		try {
			var offset = scripts.call("getNoteModifierVisualOffsetX", [strum.strumLine.ID, strum.ID, center]);
			if (offset != null)
				center += offset;
		} catch(e:Dynamic) {}
	}

	return center;
}

function getVisualStrumCenterY(strum:Dynamic):Float {
	if (strum == null) return FlxG.height * 0.5;

	var center = strum.y + (strum.height * 0.5);
	var shader = Reflect.field(strum, "shader");
	if (shader != null) {
		var shaderCenter = getShaderFloat(shader, "screenY", Math.NaN);
		if (!Math.isNaN(shaderCenter))
			center = shaderCenter;
	}

	return center;
}

function getNoteTypeForSplash(note:Dynamic):Dynamic {
	if (note == null) return "";
	try {
		var noteType = Reflect.field(note, "noteType");
		if (noteType != null) return noteType;
	} catch(e:Dynamic) {}
	return "";
}

function getSplashShader(splashName:String, strumID:Int, strumLineID:Int, noteType:Dynamic, fallback:Dynamic):Dynamic {
	if (splashName == "paper") {
		try {
			var shader = scripts.call("getPaperSplashShader", [strumID, strumLineID, noteType]);
			if (shader != null)
				return shader;
		} catch(e:Dynamic) {}
	}
	return fallback;
}

function onNoteHit(event)
{
    var index = event.note.strumID;
    event.direction = multikeySingDirs[getKeyCountIndex(event.note.strumLine.ID)][index]; 

    if (event.direction == 4) 
    {
        var char = event.characters[0];
		event.direction = 2;
        if (char.animation.getByName("singUP-SPACE") != null)
        {
            event.animSuffix = "-SPACE";
        }        
    }

    
    if (event.showSplash)
    {
        event.showSplash = false;
		var splashName = event.note.splash == null ? getSplashForTime(event.note.strumTime) : event.note.splash;

		
        event.note.__strum.ID = multikeySplashIDs[getKeyCountIndex(event.note.strumLine.ID)][index]; 
        

		
		splashHandler.__grp = splashHandler.getSplashGroup(splashName);
		var splash = splashHandler.__grp.showOnStrum(event.note.__strum);
		if (splash == null) {
			event.note.__strum.ID = event.note.strumID;
			return;
		}
		splashHandler.add(splash);
		
		while(splashHandler.members.length > 8)
			splashHandler.remove(splashHandler.members[0], true);

		event.note.__strum.ID = event.note.strumID; 

		
		if (!splashScales.exists(splashName))
		{
			splashScales.set(splashName, splash.scale.x); 
		}
		var scale:Float = splashScales.get(splashName);
		
		splash.shader = getSplashShader(splashName, index, event.note.strumLine.ID, getNoteTypeForSplash(event.note), event.note.__strum.shader);

		
		splash.scale.set(
			strumLineNoteScales[event.note.strumLine.ID]*splashScaleMult*scale, 
			strumLineNoteScales[event.note.strumLine.ID]*splashScaleMult*scale);
		splash.updateHitbox();
		splash.setPosition(
			getVisualStrumCenterX(event.note.__strum) - (splash.width / 2), 
			getVisualStrumCenterY(event.note.__strum) - (splash.height / 2));
    }
}
function onPlayerMiss(event)
{
	if (event.animCancelled)
		return;
	
    event.animCancelled = true;
	var directionID = multikeySingDirs[getKeyCountIndex(event.playerID)][event.direction];
    for(char in event.characters) {
        if (char == null) continue;

        if(event.stunned) char.stunned = true;
        char.playSingAnim(directionID, event.animSuffix, 1, event.forceAnim);
    }
}

function changeKeyCount(kc, doAnim, strumlineID)
{
	if (strumLineKeyCounts[strumlineID] == kc)
		return;

    strumLineKeyCounts[strumlineID] = kc;
	for (strum in strumLines.members[strumlineID])
	{
		strum.kill();
		strumLines.members[strumlineID].remove(strum, true);
		strum.destroy();
	}
    strumLines.members[strumlineID].clear();

	strumLineSwagWidths[strumlineID] = multikeyWidths[getKeyCountIndex(strumlineID)] * 0.7;
	strumLineNoteScales[strumlineID] = multikeyScales[getKeyCountIndex(strumlineID)];

	if (!strumLines.members[strumlineID].cpu) 
	{
		#if mobile
		loadMobileHitboxes(strumLineKeyCounts[1]);
		#end
	}
    
    changingMania = true;
    playFadeIn = doAnim;
	strumLines.members[strumlineID].generateStrums(strumLineKeyCounts[strumlineID]);
	scripts.call("onPostManiaChange", [strumlineID]);
}

function onEvent(event)
{
    if (event.event.name == "Set Key Count" || event.event.name == "Change Key Count")
    {
		if (event.event.name == "Change Key Count" || event.event.params[2]) 
		{
			for (i in 0...strumLines.members.length)
			{
				changeKeyCount(event.event.params[0], event.event.params[1], i);
			}
		}
		else
		{
			changeKeyCount(event.event.params[0], event.event.params[1], event.event.params[3]);
		}
    }
}

function postUpdate(elapsed)
{
    for(lineID in 0...strumLines.members.length)
	{
		var p = strumLines.members[lineID];
		if (p == null || lineID >= strumLineHasSustains.length || !strumLineHasSustains[lineID])
			continue;
        p.notes.forEach(function(n) {
            if (n.isSustainNote)
            {
                n.y -= Strum.N_WIDTHDIV2;
                n.y += strumLineSwagWidths[n.strumLine.ID]*0.5*strumLines.members[n.strumLine.ID].strumScale;
            }
        });
	}
}

function loadMobileHitboxes(targetKc)
{
	#if mobile
	for (i in mobileControls.hitbox)
		mobileControls.hitbox.remove(i);
	#end
	multikeyMobileHitboxes = [];
	var kc = 1;
	for (keyData in multikeyXML.elementsNamed("mobileHitboxes"))
	{
		for (keyGroup in keyData.elementsNamed("keyGroup"))
		{
			if (kc == targetKc)
			{
				for (key in keyGroup.elementsNamed("key")) 
				{
					var x = FlxG.width * Std.parseFloat(key.get("xPercent"));
					var y = FlxG.height * Std.parseFloat(key.get("yPercent"));
					var w = FlxG.width * Std.parseFloat(key.get("widthPercent"));
					var h = FlxG.height * Std.parseFloat(key.get("heightPercent"));
					var color = FlxColor.fromString(key.get("color"));
					
					#if !mobile
					var spr = new FlxButton(x,y);
					spr.makeGraphic(1,1, color);
					spr.setGraphicSize(w, h);
					spr.updateHitbox();
					spr.cameras = [camHUD];
					spr.alpha = 0.5;
					add(spr);
					multikeyMobileHitboxes.push(spr);
					#end

					#if mobile
					var spr = mobileControls.hitbox.createHint(x, y, Std.int(w), Std.int(h), color);
					mobileControls.hitbox.add(spr);
					multikeyMobileHitboxes.push(spr);
					#end
				}
				break;
			}

			kc++;
		}
	}
}
