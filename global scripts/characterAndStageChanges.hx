import funkin.game.Stage;
import flixel.util.FlxTimer;

var charactersMap:Array<Dynamic> = [];
var stageMap = ["" => null];
var warmObjects:Array<Dynamic> = [];
var preloadedObjectStates:Array<Dynamic> = [];
var pendingPreloads:Array<Dynamic> = [];
var preloadLeadTime:Float = 12000;

function voiidDebugTrace(message:String) {
	if (Reflect.field(FlxG.save.data, "voiidDebugLogs") == true)
		trace(message);
}

function create() {
	for (i in 0...PlayState.SONG.strumLines.length) {
		var map:Map<String, Array<Character>> = ["" => []];
		map.clear();
		charactersMap.push(map);
	}
	stageMap.clear();
}

function warmPreloadedObject(obj:Dynamic, removeAfterWarm:Bool = false) {
	if (obj == null) return;

	for (warm in warmObjects) {
		if (warm.obj == obj) return;
	}

	var wasInState = members != null && members.indexOf(obj) >= 0;
	rememberPreloadedObjectState(obj, removeAfterWarm);
	var data = {
		obj: obj,
		alpha: obj.alpha,
		visible: obj.visible,
		active: obj.active,
		wasInState: wasInState,
		removeAfterWarm: removeAfterWarm
	};
	warmObjects.push(data);

	if (!wasInState)
		add(obj);

	obj.visible = true;
	obj.alpha = 0.001;
	obj.active = false;

	new FlxTimer().start(0.25, function(_) {
		finishWarmPreloadedObject(obj);
	});
}

function finishWarmPreloadedObject(obj:Dynamic) {
	for (i in 0...warmObjects.length) {
		var warm = warmObjects[i];
		if (warm.obj != obj) continue;

		obj.alpha = warm.alpha;
		obj.visible = warm.visible;
		obj.active = warm.active;

		if ((warm.removeAfterWarm || !warm.wasInState) && members != null && members.indexOf(obj) >= 0)
			remove(obj, true);

		warmObjects.splice(i, 1);
		return;
	}
}

function restoreWarmObject(obj:Dynamic) {
	if (obj == null) return;

	for (i in 0...warmObjects.length) {
		var warm = warmObjects[i];
		if (warm.obj != obj) continue;

		obj.alpha = warm.alpha;
		obj.visible = warm.visible;
		obj.active = warm.active;
		warmObjects.splice(i, 1);
		return;
	}

	var state = getPreloadedObjectState(obj);
	if (state != null) {
		obj.alpha = state.alpha;
		obj.visible = state.visible;
		obj.active = state.active;
		return;
	}

	obj.alpha = 1;
	obj.visible = true;
	obj.active = true;
}

function rememberPreloadedObjectState(obj:Dynamic, removeAfterWarm:Bool = false) {
	for (state in preloadedObjectStates) {
		if (state.obj == obj) return;
	}

	preloadedObjectStates.push({
		obj: obj,
		alpha: obj.alpha,
		visible: obj.visible,
		active: obj.active,
		removeAfterWarm: removeAfterWarm
	});
}

function getPreloadedObjectState(obj:Dynamic) {
	for (state in preloadedObjectStates) {
		if (state.obj == obj) return state;
	}
	return null;
}

function getCharactersMap(strumlineID:Int):Map<String, Array<Character>> {
	if (strumlineID < 0) return null;

	while (charactersMap.length <= strumlineID) {
		var map:Map<String, Array<Character>> = ["" => []];
		map.clear();
		charactersMap.push(map);
	}

	return charactersMap[strumlineID];
}

function hasStrumline(strumlineID:Int):Bool {
	return strumlineID >= 0 && strumLines != null && strumLines.members != null && strumlineID < strumLines.members.length && strumLines.members[strumlineID] != null;
}

function postCreate() {
	for (i in 0...strumLines.length) {
		var characterNames:Array<String> = [];
		var characters = [];
		for (char in strumLines.members[i].characters) {
			characterNames.push(char.curCharacter);
			characters.push(char);
		}

		var map = getCharactersMap(i);
		if (!map.exists(Std.string(characterNames))) {
			map.set(Std.string(characterNames), characters);
		}
	}
	if (!stageMap.exists(curStage)) stageMap.set(curStage, stage);
	setStageScriptActive(stage, true);

	for (event in events) {
		switch(event.name) {
			case "Change Characters":
				queueTimedPreload(event.time, "characters", event.params[0], event.params[1]);
			case "Change Stage":
				queueTimedPreload(event.time, "stage", event.params[0], null);
		}
	}

	processPendingPreloads();
}

function queueTimedPreload(time:Float, type:String, a:Dynamic, b:Dynamic) {
	pendingPreloads.push({
		time: time,
		type: type,
		a: a,
		b: b,
		done: false
	});
}

function processPendingPreloads() {
	if (pendingPreloads.length <= 0) return;

	var now = Conductor.songPosition;
	for (preload in pendingPreloads) {
		if (preload.done) continue;
		if (preload.time - now > preloadLeadTime) continue;

		switch(preload.type) {
			case "characters":
				onCharactersPreload(preload.a, preload.b);
			case "stage":
				onStagePreload(preload.a);
		}
		preload.done = true;
	}
}

function update(elapsed:Float) {
	processPendingPreloads();
}


function onCharactersPreload(group:String, characterNames:String) {
	var strumlineID = groupNameToStrumlineID(group);
	if (strumlineID < 0) return;
	if (!hasStrumline(strumlineID)) {
		voiidDebugTrace("[ChangeCharacters] skipped preload for missing strumline " + strumlineID + " group: " + group);
		return;
	}

	var map = getCharactersMap(strumlineID);
	if (map == null) return;

	var n = Std.string(parseCharacterNames(characterNames));
	if (map.exists(n)) return;

	var arr:Array<Character> = [];
	for (c in parseCharacterNames(characterNames)) {
		var character = new Character(0, 0, c, strumlineID == 1);
		character.globalOffset.x -= (character.frameWidth*character.scale.x)/2;
		character.globalOffset.y -= (character.frameHeight*character.scale.y);
		character.dance();
		warmPreloadedObject(character);
		setCharacterScriptsActive(character, false);
		arr.push(character);
	}
	map.set(n, arr);
}

function changeCharacters(group:String, characterNames:String) {
	var strumlineID = groupNameToStrumlineID(group);
	if (strumlineID < 0) return;
	if (!hasStrumline(strumlineID)) {
		voiidDebugTrace("[ChangeCharacters] skipped missing strumline " + strumlineID + " for group: " + group);
		return;
	}

	var strumline = strumLines.members[strumlineID];

	for (char in strumline.characters) {
		setCharacterScriptsActive(char, false);
		remove(char);
	}
	strumline.characters = [];

	var map = getCharactersMap(strumlineID);
	if (map == null) return;

	var n = Std.string(parseCharacterNames(characterNames));
	if (map.exists(n)) {
		var newCharacters = map.get(n);

		for (char in newCharacters) {
			restoreWarmObject(char);
			setCharacterScriptsActive(char, true);
			strumline.characters.push(char);
		}
		updateCharacterPositions(newCharacters, strumlineID);
	}

	scripts.call("onCharactersChanged", [strumlineID, characterNames]);
}

function setCharacterScriptsActive(char:Character, active:Bool) {
	if (char == null || char.scripts == null) return;
	if (char.extra["voiidScriptsActive"] == active) return;

	if (active) {
		for (script in char.scripts.scripts)
			script.active = true;
		char.scripts.call("create");
		char.scripts.call("postCreate");
	} else {
		char.scripts.call("destroy");
		for (script in char.scripts.scripts)
			script.active = false;
	}

	char.extra["voiidScriptsActive"] = active;
}

function parseCharacterNames(names) {
	return names.split(',');
}

function updateCharacterPositions(characters:Array<Character>, strumlineID:Int) {
	for (i in 0...characters.length) {
		var char = characters[i];
		char.cameraOffset.set(0,0);
		if (char.xml.exists("camx")) char.cameraOffset.x = Std.parseFloat(char.xml.get("camx")); 
		if (char.xml.exists("camy")) char.cameraOffset.y = Std.parseFloat(char.xml.get("camy"));
		applyCharacterLayer(char, strumlineID, i);
	}
}

function applyCharacterLayer(char:Character, strumlineID:Int, charID:Int) {
	var groupName = strumlineIDToGroupName(strumlineID);
	var pose = stage.characterPoses[char.curCharacter] != null ? stage.characterPoses[char.curCharacter] : stage.characterPoses[groupName];
	var layerPose = pose;
	var layerIndex = layerPose != null ? members.indexOf(layerPose) : -1;

	if (layerIndex < 0) {
		layerPose = stage.characterPoses[groupName];
		layerIndex = layerPose != null ? members.indexOf(layerPose) : -1;
	}

	if (pose != null)
		pose.prepareCharacter(char, charID);

	remove(char, true);
	if (layerIndex >= 0)
		insert(layerIndex + 1, char);
	else
		add(char);
}

function groupNameToStrumlineID(n:String) {
	switch(n.toLowerCase()) {
		case "dad":
			return 0;
		case "bf" | "boyfriend":
			return 1;
		case "gf" | "girlfriend":
			return 2;
	}
	return Std.parseInt(n);
}
function strumlineIDToGroupName(i:Int) {
	switch(i) {
		case 0:
			return "dad";
		case 1:
			return "boyfriend";
		case 2:
			return "girlfriend";
	}
	return "idk";
}





function onStagePreload(name:String) {
	if (stageMap.exists(name)) {
		voiidDebugTrace("[ChangeStage] stage already preloaded: " + name);
		return;
	}

	voiidDebugTrace("[ChangeStage] preloading stage: " + name);
	var newStage = new Stage(name);
	setStageScriptActive(newStage, false);
	stageMap.set(name, newStage);

	for (spr in newStage.stageSprites) warmPreloadedObject(spr, true);
	for (n => pos in newStage.characterPoses) remove(pos);
}
function changeStage(name:String) {
	voiidDebugTrace("[ChangeStage] requested stage change to: " + name);
	if (!stageMap.exists(name)) {
		voiidDebugTrace("[ChangeStage] stage was not preloaded, loading now: " + name);
		onStagePreload(name);
	}
	if (!stageMap.exists(name)) {
		voiidDebugTrace("[ChangeStage] stage change failed, missing stage: " + name);
		return;
	}
	
	var oldStage = stage;
	var newStage = stageMap.get(name);
	callStageScript(oldStage, "onStageDeactivated", [name]);
	setStageScriptActive(oldStage, false);

	for (spr in oldStage.stageSprites) remove(spr);
	for (n => pos in oldStage.characterPoses) remove(pos);
	for (s in strumLines.members) {
		for (char in s.characters) remove(char);
	}
	remove(comboGroup, true);

	stage = newStage;
	refreshStageScriptVariables(stage);
	setStageScriptActive(stage, true);
	callStageScript(stage, "onStageActivated", [name]);


	var parsed = null;
	if (stage.stageXML.exists("startCamPosX") && (parsed = Std.parseFloat(stage.stageXML.get("startCamPosX")))) PlayState.instance.camFollow.x = parsed;
	if (stage.stageXML.exists("startCamPosY") && (parsed = Std.parseFloat(stage.stageXML.get("startCamPosY")))) PlayState.instance.camFollow.y = parsed;
	if (stage.stageXML.exists("zoom") && (parsed = Std.parseFloat(stage.stageXML.get("zoom")))) PlayState.instance.defaultCamZoom = parsed;
	PlayState.instance.curStage = stage.stageXML.exists("name") ? stage.stageXML.get("name") : name;
	voiidDebugTrace("[ChangeStage] current stage is now: " + PlayState.instance.curStage);

	for (n in stage.stageXML.elements()) {
		switch(n.nodeName) {
			case "sprite" | "spr" | "sparrow":
				var spr = stage.stageSprites.get(n.get("name"));
				restoreWarmObject(spr);
				add(spr);
			case "boyfriend" | "bf" | "player":
				add(stage.characterPoses["boyfriend"]);
			case "girlfriend" | "gf":
				add(stage.characterPoses["girlfriend"]);
			case "dad" | "opponent":
				add(stage.characterPoses["dad"]);
			case "ratings" | "combo":
				add(comboGroup);
		}
	}

	for (s in strumLines.members) {
		updateCharacterPositions(s.characters, s.ID);
	}

	insert(members.length-1, comboGroup);

	try {
		scripts.call("onStageChanged", [PlayState.instance.curStage]);
	} catch(e:Dynamic) {
		voiidDebugTrace("[ChangeStage] onStageChanged callback failed: " + e);
	}
}

function setStageScriptActive(daStage:Stage, active:Bool) {
	if (daStage == null || daStage.stageScript == null) return;
	daStage.stageScript.active = active;
	voiidDebugTrace("[ChangeStage] stage script " + daStage.stagePath + " active=" + active);
}

function callStageScript(daStage:Stage, func:String, args:Array<Dynamic>) {
	if (daStage == null || daStage.stageScript == null) return;
	try {
		daStage.stageScript.call(func, args);
	} catch(e:Dynamic) {}
}

function refreshStageScriptVariables(daStage:Stage) {
	if (daStage == null || daStage.stageScript == null) return;
	for (k => e in daStage.stageSprites) {
		daStage.stageScript.set(k, e);
	}
}



function onEvent(e) {
	var event = e.event;

	switch(event.name) {
		case "Change Characters":
			changeCharacters(event.params[0], event.params[1]);
		case "Change Stage":
			changeStage(event.params[0]);
	}
}
