import funkin.game.Stage;
var charactersMap:Array<Dynamic> = [];
var stageMap = ["" => null];
function create() {
	for (i in 0...PlayState.SONG.strumLines.length) {
		var map:Map<String, Array<Character>> = ["" => []];
		map.clear();
		charactersMap.push(map);
	}
	stageMap.clear();
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
				onCharactersPreload(event.params[0], event.params[1]);
			case "Change Stage":
				onStagePreload(event.params[0]);
		}
	}
}

///characters/////////
function onCharactersPreload(group:String, characterNames:String) {
	var strumlineID = groupNameToStrumlineID(group);
	if (strumlineID < 0) return;
	if (!hasStrumline(strumlineID)) {
		trace("[ChangeCharacters] skipped preload for missing strumline " + strumlineID + " group: " + group);
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
		arr.push(character);
	}
	map.set(n, arr);
}

function changeCharacters(group:String, characterNames:String) {
	var strumlineID = groupNameToStrumlineID(group);
	if (strumlineID < 0) return;
	if (!hasStrumline(strumlineID)) {
		trace("[ChangeCharacters] skipped missing strumline " + strumlineID + " for group: " + group);
		return;
	}

	var strumline = strumLines.members[strumlineID];

	for (char in strumline.characters) {
		remove(char);
	}
	strumline.characters = [];

	var map = getCharactersMap(strumlineID);
	if (map == null) return;

	var n = Std.string(parseCharacterNames(characterNames));
	if (map.exists(n)) {
		var newCharacters = map.get(n);

		for (char in newCharacters) {
			strumline.characters.push(char);
		}
		updateCharacterPositions(newCharacters, strumlineID);
	}

	scripts.call("onCharactersChanged", [strumlineID, characterNames]);
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



///stages////////////

function onStagePreload(name:String) {
	if (stageMap.exists(name)) {
		trace("[ChangeStage] stage already preloaded: " + name);
		return;
	}

	trace("[ChangeStage] preloading stage: " + name);
	var newStage = new Stage(name);
	setStageScriptActive(newStage, false);
	stageMap.set(name, newStage);

	for (spr in newStage.stageSprites) remove(spr);
	for (n => pos in newStage.characterPoses) remove(pos);
}
function changeStage(name:String) {
	trace("[ChangeStage] requested stage change to: " + name);
	if (!stageMap.exists(name)) {
		trace("[ChangeStage] stage was not preloaded, loading now: " + name);
		onStagePreload(name);
	}
	if (!stageMap.exists(name)) {
		trace("[ChangeStage] stage change failed, missing stage: " + name);
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
	trace("[ChangeStage] current stage is now: " + PlayState.instance.curStage);

	for (n in stage.stageXML.elements()) {
		switch(n.nodeName) {
			case "sprite" | "spr" | "sparrow":
				add(stage.stageSprites.get(n.get("name")));
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
		trace("[ChangeStage] onStageChanged callback failed: " + e);
	}
}

function setStageScriptActive(daStage:Stage, active:Bool) {
	if (daStage == null || daStage.stageScript == null) return;
	daStage.stageScript.active = active;
	trace("[ChangeStage] stage script " + daStage.stagePath + " active=" + active);
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
