public var songHasPunches = false;

var punches = [];
var punchEarlyHitTiming = 160; 
var punchLateHitTiming = 160;
var dodging = false;
var dodgeCooldown = 0;
var canBeDodged = false;
var punchAlphas = [0,0,0];
var punchAlphaLerpSpeed = 0.1;

var fadeOutDelay = 0.0;

var punchSprites = [];
var msText:FunkinText;
var punchesLeftText:FunkinText;

function saveBool(name:String, fallback:Bool):Bool {
	var value = Reflect.field(FlxG.save.data, name);
	if (value == null) {
		Reflect.setField(FlxG.save.data, name, fallback);
		FlxG.save.flush();
		return fallback;
	}
	return value == true;
}

function noMechanicsEnabled():Bool {
	return saveBool("voiidNoMechanics", false);
}

function punchCenterScreen():Bool {
	return saveBool("voiidPunchCenterScreen", false);
}

function setupPunches() {
	for (i in 0...3) {
		var spr = new FlxSprite();
		spr.frames = Paths.getSparrowAtlas("punch"+(i+1));
		spr.cameras = [camHUD];
		spr.animation.addByPrefix("punch", "punch"+(i+1), 24, false);
		spr.animation.play("punch");
		spr.screenCenter();
		spr.alpha = 0;
		add(spr);
		punchSprites.push(spr);
	}

	msText = new FunkinText();
	msText.size = 32;
	msText.text = "";
	msText.cameras = [camHUD];
	msText.screenCenter();
	add(msText);

	msText.y = getY(450, 32);

	punchesLeftText = new FunkinText();
	punchesLeftText.size = 48;
	punchesLeftText.text = "";
	punchesLeftText.cameras = [camHUD];
	punchesLeftText.screenCenter();
	add(punchesLeftText);

	punchesLeftText.y = getY(300, 48);
}
function getY(y, objHeight) {
	if (!downscroll) return y;

	return -y + FlxG.height - objHeight;
}

function getShaderFloat(shader:Dynamic, name:String, fallback:Float = 0):Float {
	if (shader == null) return fallback;

	try {
		if (shader.data != null) {
			var parameter = Reflect.field(shader.data, name);
			if (parameter != null && parameter.value != null && parameter.value.length > 0) {
				var attributeValue = Std.parseFloat(Std.string(parameter.value[0]));
				if (!Math.isNaN(attributeValue)) return attributeValue;
			}
		}
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
		if (!Math.isNaN(shaderCenter)) center = shaderCenter;

		try {
			var offset = scripts.call("getNoteModifierVisualOffsetX", [1, strum.ID, center]);
			if (offset != null) center += offset;
		} catch(e:Dynamic) {}
	}

	return center;
}

function getPlayerStrumlineCenterX():Float {
	try {
		var line = strumLines.members[1];
		if (line == null || line.members == null || line.members.length < 1)
			return FlxG.width * 0.5;

		var minX = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		for (strum in line.members) {
			if (strum == null) continue;
			var center = getVisualStrumCenterX(strum);
			var halfWidth = strum.width * 0.5;
			minX = Math.min(minX, center - halfWidth);
			maxX = Math.max(maxX, center + halfWidth);
		}

		if (minX != Math.POSITIVE_INFINITY && maxX != Math.NEGATIVE_INFINITY)
			return (minX + maxX) * 0.5;
	} catch(e:Dynamic) {}

	return FlxG.width * 0.5;
}

function updatePosition() {
	var centerX = punchCenterScreen() ? FlxG.width * 0.5 : getPlayerStrumlineCenterX();

	for (i in 0...3) {
		punchSprites[i].x = centerX - (punchSprites[i].width*0.5);
	}
	msText.x = centerX - (msText.width*0.5);
	punchesLeftText.x = centerX - (punchesLeftText.width*0.5);
}

function create() {
	if (noMechanicsEnabled()) return;

	for (event in events) {
		switch(event.name) {
			case "Punch" | "Slash":
				onPunchLoaded(event.time, event.params[0], event.params[1], event.name.toLowerCase());
		}
	}
}

function onPunchLoaded(time, count, beats, type) {
	if (noMechanicsEnabled()) return;

	if (!songHasPunches) {
		songHasPunches = true;
		setupPunches();
	}
	
	punches.push({
		time: time,
		count: count,
		beatTiming: beats,
		started: false,
		punchesLeft: count,
		punchesHit: 0,
		punchTime: time,
		type: type
	});

	for (i in 0...count) {

		var bpmChange = {
			stepTime: 0,
			songTime: 0,
			bpm: Conductor.bpm
		};

		for(change in Conductor.bpmChangeMap)
			if (change.songTime < time && change.songTime >= bpmChange.songTime)
				bpmChange = change;

		var croch = ((60 / bpmChange.bpm) * 1000);

		var t = time + (i * beats * croch);

		scripts.call("onEchoCreate", [t, "Wiik3White"]);
	}
}
var firstFrame = true;
function postUpdate(elapsed) {
	if (noMechanicsEnabled()) {
		canBeDodged = false;
		if (songHasPunches) {
			for (i in 0...3) punchAlphas[i] = 0;
			for (spr in punchSprites)
				if (spr != null) spr.alpha = 0;
			if (msText != null) msText.alpha = 0;
			if (punchesLeftText != null) punchesLeftText.text = "";
		}
		return;
	}

	if (songHasPunches) {
		if (firstFrame) {
			firstFrame = false;
			punches.sort(function(a, b) {
				if(a.time < b.time) return -1;
				else if(a.time > b.time) return 1;
				else return 0;
			 });
		}
		updateLogic(elapsed);
		updatePosition();
	}
}
function getIndex(count) {if (count > 3) count = 3; return count-1;}

function isBotplayActive():Bool {
	try {
		if (strumLines != null && strumLines.members != null && strumLines.members[1] != null && strumLines.members[1].cpu)
			return true;
	} catch(e:Dynamic) {}

	try {
		if (playerStrums != null) {
			var anyCPU = false;
			playerStrums.forEach(function(strum) {
				if (strum != null && strum.cpu) anyCPU = true;
			});
			if (anyCPU) return true;
		}
	} catch(e:Dynamic) {}

	try {
		var bot = scripts.get("botplay");
		if (bot == true) return true;
	} catch(e:Dynamic) {}

	return false;
}

function updateLogic(elapsed) {
	if (noMechanicsEnabled()) return;

	canBeDodged = false;

	if (punches.length > 0) {
		var p = punches[0];
		var beatTiming = p.beatTiming * Conductor.crochet;

        if (p.time-800 < Conductor.songPosition) {
			punchAlphas[getIndex(p.count)] = 1;
		}
		if (p.time - beatTiming < Conductor.songPosition) {
			punchAlphas[getIndex(p.count)] = 1;
			punchAlphaLerpSpeed = 0.1;
			fadeOutDelay = 0;
            p.punchTime = p.time + (p.punchesHit*beatTiming);

			punchesLeftText.text = p.punchesLeft;
			punchesLeftText.color = 0xFFFFFFFF;

			if (p.punchTime - punchEarlyHitTiming < Conductor.songPosition && Conductor.songPosition < p.punchTime + punchLateHitTiming) {
				punchesLeftText.color = 0xFFFF0000;
				canBeDodged = true;

				if (!p.started && p.punchTime-100 <= Conductor.songPosition) {
					p.started = true;
					punchSprites[getIndex(p.count)].animation.play("punch", true);
				}

				if (p.punchTime <= Conductor.songPosition) {
					if (isBotplayActive()) {
						tryDodge(true);
					}
				}
			}

			if (Conductor.songPosition > p.punchTime+punchLateHitTiming) {
				onMissPunch();
			}
		}
	}

	if (!dodging) {
		if (FlxG.keys.justPressed.SPACE && !isBotplayActive()) {
			tryDodge(false);
		}
	} else {
		dodgeCooldown -= 1000*elapsed;
		if (dodgeCooldown <= 0) {
			dodgeCooldown = 0;
			dodging = false;
		}
	}

    if (fadeOutDelay > 0) {
		fadeOutDelay -= 1000*elapsed;
	} else {
		for (i in 0...3) {
			punchSprites[i].alpha = CoolUtil.fpsLerp(punchSprites[i].alpha, punchAlphas[i], punchAlphaLerpSpeed);
		}
	}
    
	msText.alpha = CoolUtil.fpsLerp(msText.alpha, 0, 0.1);
}
function onMissPunch() {
	switch(punches[0].type) {
		case "punch":
			health -= 1.0;
			applyEffect("blur");
		case "slash":
			health -= 0.35;
			applyEffect("maxHealth");
	}
	
	msText.text = "miss";
	msText.color = 0xFFFF0000;
	punchRemove();
}
function tryDodge(cpu) {
	dodging = true;
    dodgeCooldown = 500;
    playDodge();
    if (canBeDodged) {
		dodging = false;
        dodgeCooldown = 0;

		var ms = -Math.floor(punches[0].punchTime-Conductor.songPosition);
		msText.text = cpu ? "BOT" : ms + "ms";

		msText.alpha = 1;
		msText.color = 0xFFFFFFFF;

		punchRemove();
	}
}
function playDodge() {
	boyfriend.playSingAnim(FlxG.random.int(0, 3), "-dodge");
}
function punchRemove() {
	punches[0].punchesLeft -= 1;
	punches[0].punchesHit += 1;
    
    if (punches[0].punchesLeft <= 0) { 
        punchesLeftText.text = "";
        fadeOutDelay = 500;
        punchAlphas[getIndex(punches[0].count)] = 0;
        punches.remove(punches[0]);
        return true;
	} else {
		punches[0].started = false;
	}
    return false;
}
function onNoteHit(e) {
	if (e.note.strumLine.ID == 1) dodgeCooldown = 0;
}
