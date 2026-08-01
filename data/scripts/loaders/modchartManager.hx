//

import haxe.Timer;
import haxe.ds.ObjectMap;


///////////3D Matrix stuff//////////////////////////////
var fov = 90 * (Math.PI/180);
//https://github.com/openfl/openfl/blob/develop/src/openfl/geom/PerspectiveProjection.hx
var focalLength = 1.0 * (1.0 / Math.tan(fov * 0.5));
var perspectiveMatrix:Array<Float> = 
[
    focalLength, 0, 0, 0,
	0, focalLength, 0, 0,
	0, 0, 1.0, 1.0,
	0, 0, 0, 0
];
// Keep this array alive for the whole song. Every perspective shader points to
// it, so updating its values is enough and does not allocate one matrix per
// shader (or per frame).
var viewMatrix:Array<Float> = [
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, 1, 0,
	0, 0, 0, 1
];

public var eye:Array<Float> = [0, 0, -0.71, 0];
public var lookAt:Array<Float> = [0, 0, 0, 0];
public var up:Array<Float> = [0, 1, 0, 0];

var right:Array<Float> = [1, 0, 0, 0];
var upv:Array<Float> = [0, 1, 0, 0];
var forward:Array<Float> = [0, 0, 1, 0];

function updateViewMatrix()
{
	var fx:Float = lookAt[0] - eye[0];
	var fy:Float = eye[1] - lookAt[1];
	var fz:Float = lookAt[2] - eye[2];
	var mag:Float = Math.sqrt((fx * fx) + (fy * fy) + (fz * fz));
	if (mag <= 0) return;

	fx /= mag;
	fy /= mag;
	fz /= mag;
	forward[0] = fx;
	forward[1] = fy;
	forward[2] = fz;
	forward[3] = 0;

	var rx:Float = (up[1] * fz) - (up[2] * fy);
	var ry:Float = (up[2] * fx) - (up[0] * fz);
	var rz:Float = (up[0] * fy) - (up[1] * fx);
	// Preserve the legacy cross()/normalize() result: cross() used w = 1 and
	// normalize() included it in the magnitude.
	mag = Math.sqrt((rx * rx) + (ry * ry) + (rz * rz) + 1);
	if (mag <= 0) return;

	rx /= mag;
	ry /= mag;
	rz /= mag;
	right[0] = rx;
	right[1] = ry;
	right[2] = rz;
	right[3] = 1 / mag;

	var ux:Float = (fy * rz) - (fz * ry);
	var uy:Float = (fz * rx) - (fx * rz);
	var uz:Float = (fx * ry) - (fy * rx);
	upv[0] = ux;
	upv[1] = uy;
	upv[2] = uz;
	upv[3] = 1;

	var negX:Float = -eye[0];
	var negY:Float = eye[1];
	var negZ:Float = -eye[2];
	viewMatrix[0] = rx;
	viewMatrix[1] = ux;
	viewMatrix[2] = fx;
	viewMatrix[3] = 0;
	viewMatrix[4] = ry;
	viewMatrix[5] = uy;
	viewMatrix[6] = fy;
	viewMatrix[7] = 0;
	viewMatrix[8] = rz;
	viewMatrix[9] = uz;
	viewMatrix[10] = fz;
	viewMatrix[11] = 0;
	viewMatrix[12] = (rx * negX) + (ry * negY) + (rz * negZ);
	viewMatrix[13] = (ux * negX) + (uy * negY) + (uz * negZ);
	viewMatrix[14] = (fx * negX) + (fy * negY) + (fz * negZ);
	viewMatrix[15] = 1;
}
function normalize(vec:Array<Float>)
{
	var mag:Float = Math.sqrt((vec[0] * vec[0]) + (vec[1] * vec[1]) + (vec[2] * vec[2]) + (vec[3] * vec[3]) );
	vec[0] = vec[0] / mag;
	vec[1] = vec[1] / mag;
	vec[2] = vec[2] / mag;
	vec[3] = vec[3] / mag;
	return vec;
}
function cross(vec1:Array<Float>, vec2:Array<Float>)
{
	var vec:Array<Float> = [0, 0, 0, 1];
	vec[0] = vec1[1] * vec2[2] - vec1[2] * vec2[1];
	vec[1] = vec1[2] * vec2[0] - vec1[0] * vec2[2];
	vec[2] = vec1[0] * vec2[1] - vec1[1] * vec2[0];
	return vec;
}
function dot(vec1:Array<Float>, vec2:Array<Float>)
{
	return vec1[0] * vec2[0] + vec1[1] * vec2[1] + vec1[2] * vec2[2];
}

/////////////////////////////////

//different shader code for each strum (for specific mods)
var modShaderVertTable:Array<Dynamic> = [];
var modShaderFragTable:Array<Dynamic> = [];

var shaderPool:Array<Dynamic> = [];
var shaderRuntimeData:ObjectMap<Dynamic, Dynamic> = new ObjectMap();
var MAX_PREWARM_SHADERS_PER_LANE:Int = 32;

function getShaderParameter(shader, name:String) {
	if (shader == null || shader.data == null) return null;
	return Reflect.field(shader.data, name);
}

function initShaderScalar(parameter, value) {
	if (parameter != null) parameter.value = [value];
}

function initShaderVec4(parameter, x:Float, y:Float, z:Float, w:Float) {
	if (parameter != null) parameter.value = [x, y, z, w];
}

function setShaderScalar(parameter, value) {
	if (parameter != null && parameter.value != null && parameter.value.length > 0)
		parameter.value[0] = value;
}

function setShaderVec4(parameter, x:Float, y:Float, z:Float, w:Float) {
	if (parameter == null || parameter.value == null || parameter.value.length < 4) return;
	parameter.value[0] = x;
	parameter.value[1] = y;
	parameter.value[2] = z;
	parameter.value[3] = w;
}

// FunkinShader.hset creates a fresh one-element Array for every scalar write.
// The legacy manager used to do that hundreds of times per frame. Cache the
// ShaderParameter objects once and mutate their existing value arrays instead.
function cachePerspectiveShader(shader, strumLineID:Int, strumID:Int) {
	if (shader == null) return null;

	var cached = shaderRuntimeData.get(shader);
	if (cached != null) return cached;

	var data = {
		downscroll: getShaderParameter(shader, "downscroll"),
		isSustainNote: getShaderParameter(shader, "isSustainNote"),
		screenX: getShaderParameter(shader, "screenX"),
		screenY: getShaderParameter(shader, "screenY"),
		songPosition: getShaderParameter(shader, "songPosition"),
		curBeat: getShaderParameter(shader, "curBeat"),
		scrollSpeed: getShaderParameter(shader, "scrollSpeed"),
		strumID: getShaderParameter(shader, "strumID"),
		strumLineID: getShaderParameter(shader, "strumLineID"),
		noteCurPos: getShaderParameter(shader, "noteCurPos"),
		frameUV: getShaderParameter(shader, "frameUV"),
		modifierParams: []
	};

	initShaderVec4(getShaderParameter(shader, "vertexID"), 0, 1, 2, 3);
	initShaderVec4(data.noteCurPos, 0, 0, 0, 0);
	initShaderVec4(data.frameUV, 0, 0, 1, 1);
	initShaderScalar(data.downscroll, false);
	initShaderScalar(data.isSustainNote, false);
	initShaderScalar(data.screenX, 0.0);
	initShaderScalar(data.screenY, 0.0);
	initShaderScalar(data.songPosition, 0.0);
	initShaderScalar(data.curBeat, 0.0);
	initShaderScalar(data.scrollSpeed, 0.0);
	initShaderScalar(data.strumID, strumID + 0.0);
	initShaderScalar(data.strumLineID, strumLineID + 0.0);

	var perspectiveParam = getShaderParameter(shader, "perspectiveMatrix");
	if (perspectiveParam != null) perspectiveParam.value = perspectiveMatrix;
	var viewParam = getShaderParameter(shader, "viewMatrix");
	if (viewParam != null) viewParam.value = viewMatrix;

	if (modTable[strumLineID] != null && modTable[strumLineID][strumID] != null) {
		for (mod in modTable[strumLineID][strumID]) {
			var parameter = getShaderParameter(shader, mod[MOD_NAME] + "_value");
			if (parameter == null) continue;
			initShaderScalar(parameter, mod[MOD_VALUE]);
			data.modifierParams.push({parameter: parameter, modifier: mod});
		}
	}

	shaderRuntimeData.set(shader, data);
	return data;
}

function newPerspectiveShader(strumLineID:Int, strumID:Int) {
	var shader = new FunkinShader(modShaderFragTable[strumLineID][strumID], modShaderVertTable[strumLineID][strumID]);
	cachePerspectiveShader(shader, strumLineID, strumID);
	return shader;
}

function prewarmPerspectiveShaderLane(strumLineID:Int, strumID:Int) {
	if (PlayState.instance == null || !hasPerspectiveShaderLane(strumLineID, strumID)) return;
	var strumLine = strumLines.members[strumLineID];
	if (strumLine == null || strumLine.notes == null || strumLine.notes.members == null) return;

	var noteTimes:Array<Float> = [];
	for (note in strumLine.notes.members) {
		if (note != null && note.strumID == strumID)
			noteTimes.push(note.strumTime);
	}
	if (noteTimes.length < 1) return;

	noteTimes.sort(function(a:Float, b:Float) {
		return a < b ? -1 : (a > b ? 1 : 0);
	});

	var speed:Float = scrollSpeed;
	if (speed <= 0) speed = 1;
	var lateWindow:Float = Conductor.stepCrochet;
	if (Options.hitWindow > lateWindow)
		lateWindow = Options.hitWindow;
	var activeWindow:Float = (1750 / speed) + lateWindow;

	var left:Int = 0;
	var peak:Int = 0;
	for (right in 0...noteTimes.length) {
		while (left < right && noteTimes[right] - noteTimes[left] > activeWindow)
			left++;
		var count:Int = right - left + 1;
		if (count > peak) peak = count;
	}

	if (peak > MAX_PREWARM_SHADERS_PER_LANE)
		peak = MAX_PREWARM_SHADERS_PER_LANE;
	var pool = shaderPool[strumLineID][strumID];
	while (pool.length < peak)
		pool.push(newPerspectiveShader(strumLineID, strumID));
}

function isPerspectiveShader(shader) {
	return shader != null && shader.data != null && Reflect.field(shader.data, "noteCurPos") != null;
}

function hasPerspectiveShaderLane(strumLineID, strumID) {
	if (strumLineID < 0 || strumID < 0) return false;
	if (shaderPool == null || modShaderFragTable == null || modShaderVertTable == null) return false;
	if (shaderPool[strumLineID] == null || modShaderFragTable[strumLineID] == null || modShaderVertTable[strumLineID] == null) return false;
	return shaderPool[strumLineID][strumID] != null && modShaderFragTable[strumLineID][strumID] != null && modShaderVertTable[strumLineID][strumID] != null;
}

function getPerspectiveShader(strumLineID, strumID) {
	if (!hasPerspectiveShaderLane(strumLineID, strumID)) return null;

	var pool = shaderPool[strumLineID][strumID];

	if (pool.length < 1) {
		return newPerspectiveShader(strumLineID, strumID);
	} else {
		var shader = pool.pop();
		cachePerspectiveShader(shader, strumLineID, strumID);
		return shader;
	}
}
function putPerspectiveShader(shader, strumLineID, strumID) {
	if (shader == null || !hasPerspectiveShaderLane(strumLineID, strumID)) return;

	var pool = shaderPool[strumLineID][strumID];
	pool.push(shader);
}

function createPerspectiveShader(obj, strumLineID, strumID)
{
	if (obj == null || !hasPerspectiveShaderLane(strumLineID, strumID)) return;

	obj.shader = newPerspectiveShader(strumLineID, strumID);
}
/////////////////////////////////////

public var modifiers:Array<Dynamic> = [];
//modtable that precalculates which mods are used for which strum note
public var modTable:Array<Dynamic> = [];

//indexing variables (used kinda like an enum)
public var MOD_NAME = 0;
public var MOD_VALUE = 1;
public var MOD_FUNC = 2;
public var MOD_DEFAULTVALUE = 3;
public var MOD_AUTODISABLE = 4;
public var MOD_ENABLED = 5;
public var MOD_STRUMLINEID = 6;
public var MOD_STRUMID = 7;
public var MOD_TYPE = 8;

public var MOD_TYPE_NOTE = 0; //updates for each note/strum
public var MOD_TYPE_CUSTOM = 1; //updates once per frame
public var MOD_TYPE_FRAG = 2;

public var modEvents:Array<Dynamic> = [];
public var EVENT_TIME = 0;
public var EVENT_TYPE = 1;
public var EVENT_MODNAME = 2;
public var EVENT_VALUE = 3;
public var EVENT_EASENAME = 4;
public var EVENT_EASETIME = 5;

public var EVENT_TYPE_EASE = 0;
public var EVENT_TYPE_SET = 1;


var initialized = false;

public var modchartManagerKeyCount:Int = 4;
public var modchartManagerKeyCounts:Array<Int> = [];
var debugShaderAppliedCount:Int = 0;
var debugShaderTraceDone:Bool = false;

function postUpdate(elapsed)
{
	if (!initialized)
		return;

	//check events
	/*while(modEvents.length > 0 && modEvents[0][EVENT_TIME] <= Conductor.songPosition)
	{
		if (modEvents[0][EVENT_TYPE] == EVENT_TYPE_EASE)
		{
			var easeFunc = CoolUtil.flxeaseFromString(modEvents[0][EVENT_EASENAME], "");
			tweenModifierValue(modEvents[0][EVENT_MODNAME], modEvents[0][EVENT_VALUE], modEvents[0][EVENT_EASETIME] * Conductor.crochet*0.001, easeFunc);
		}
		else if (modEvents[0][EVENT_TYPE] == EVENT_TYPE_SET)
		{
			setModifierValue(modEvents[0][EVENT_MODNAME], modEvents[0][EVENT_VALUE]);
		}

		modEvents.remove(modEvents[0]);
	}*/




	//updateModifers();
	updateViewMatrix();
	//shader updates
	for(p in 0...strumLines.length)
	{
		if (PlayState.instance != null) {
			for (strum in strumLines.members[p]) {
				updateStrum(strum, p);
			}
		} else {
			for (strum in strumLines[p]) {
				updateStrum(strum, p);
			}
		}

		if (PlayState.instance != null)
		{
			strumLines.members[p].notes.limit = 1750 / scrollSpeed;
			strumLines.members[p].notes.forEach(function(n)
			{
				if (!isPerspectiveShader(n.shader)) {
					n.shader = getPerspectiveShader(p, n.strumID);
					debugShaderAppliedCount++;
				}
				if (n.shader == null) return;
				var shaderData = cachePerspectiveShader(n.shader, p, n.strumID);
				if (shaderData == null) return;
				n.forceIsOnScreen = true;
				setShaderScalar(shaderData.songPosition, Conductor.songPosition);
				setShaderScalar(shaderData.curBeat, Conductor.curBeatFloat);
				setShaderScalar(shaderData.downscroll, downscroll);
				setShaderScalar(shaderData.isSustainNote, n.isSustainNote);
				//if (n.isSustainNote)
	
				if (n.frame != null)
					setShaderVec4(shaderData.frameUV, n.frame.uv.x, n.frame.uv.y, n.frame.uv.width, n.frame.uv.height);
	
				var curPos = Conductor.songPosition - n.strumTime;
				var nextCurPos = curPos;
	
				//curpos for next sustain to match
				if (n.isSustainNote && n.nextNote != null && n.nextNote.isSustainNote) 
					nextCurPos = Conductor.songPosition - n.nextNote.strumTime;
	
				//sustain ends
				if (n.isSustainNote && n.nextSustain == null) 
					nextCurPos = Conductor.songPosition - (n.strumTime + (Conductor.stepCrochet*0.5));
	
				//clip to strum
				if (n.isSustainNote && n.wasGoodHit && curPos >= 0) 
					curPos = 0;
	
	
				//calculate screen position for rotation and scaling inside shader
				var point = FlxPoint.weak();
				n.getScreenPosition(point, camHUD);
				setShaderScalar(shaderData.screenX, (n.origin.x + point.x - n.offset.x) + n.__strum.x);
				if (downscroll)
					setShaderScalar(shaderData.screenY, (n.origin.y + point.y - n.offset.y) - n.__strum.y);
				else
					setShaderScalar(shaderData.screenY, (n.origin.y + point.y - n.offset.y) + n.__strum.y);
				point.put();
	
				
				setShaderScalar(shaderData.strumID, n.strumID + 0.0);
				setShaderScalar(shaderData.strumLineID, p + 0.0);
				setShaderVec4(shaderData.noteCurPos, curPos, curPos, nextCurPos, nextCurPos);
				var targetStrum = strumLines.members[p].members[n.strumID];
				if (targetStrum != null)
					setShaderScalar(shaderData.scrollSpeed, targetStrum.getScrollSpeed(n));
				applyModifierValuesToShader(n.shader, p, n.strumID);
			});
		}
	}
}
function updateStrum(strum, p) {
	if (!isPerspectiveShader(strum.shader)) {
		strum.shader = getPerspectiveShader(p, strum.ID);
	}
	if (strum.shader == null) return;
	var shaderData = cachePerspectiveShader(strum.shader, p, strum.ID);
	if (shaderData == null) return;

	setShaderScalar(shaderData.songPosition, Conductor.songPosition);
	setShaderScalar(shaderData.curBeat, Conductor.curBeatFloat);

	setShaderScalar(shaderData.strumID, strum.ID + 0.0);
	setShaderScalar(shaderData.strumLineID, p + 0.0);
	setShaderVec4(shaderData.noteCurPos, 0.0, 0.0, 0.0, 0.0);
	setShaderScalar(shaderData.scrollSpeed, 0.0);

	if (strum.frame != null)
		setShaderVec4(shaderData.frameUV, strum.frame.uv.x, strum.frame.uv.y, strum.frame.uv.width, strum.frame.uv.height);


	//calculate screen position for rotation and scaling inside shader
	var point = FlxPoint.weak();
	strum.getScreenPosition(point, camHUD);
	setShaderScalar(shaderData.screenX, strum.origin.x + point.x - strum.offset.x);
	setShaderScalar(shaderData.screenY, strum.origin.y + point.y - strum.offset.y);
	point.put();

	setShaderScalar(shaderData.downscroll, downscroll);
	setShaderScalar(shaderData.isSustainNote, false);

	
	//honestly i have no idea how these are updating the notes as well
	//they should have completely seperate shaders???
	//maybe something with cne runtime shaders idk
	applyModifierValuesToShader(strum.shader, p, strum.ID);
}

function applyModifierValuesToShader(shader, p, strumID) {
	if (shader == null) return;
	var shaderData = cachePerspectiveShader(shader, p, strumID);
	if (shaderData == null) return;

	for (entry in shaderData.modifierParams)
	{
		setShaderScalar(entry.parameter, entry.modifier[MOD_VALUE]);
	}
}

function onDeleteNote(e) {
	if (e == null || e.note == null || e.note.shader == null || e.note.strumLine == null) return;
	putPerspectiveShader(e.note.shader, e.note.strumLine.ID, e.note.strumID);
}

function getRuntimeStrumCount(p) {
	var count = 0;

	try {
		if (PlayState.instance != null) {
			if (strumLines.members[p] != null && strumLines.members[p].members != null)
				count = strumLines.members[p].members.length;
		} else if (strumLines[p] != null) {
			count = strumLines[p].length;
		}
	} catch(e:Dynamic) {}

	return count;
}

function getModTargetKeyCount(p) {
	var count = 0;

	for (mod in modifiers) {
		if ((mod[MOD_STRUMLINEID] == -1 || mod[MOD_STRUMLINEID] == p) && mod[MOD_STRUMID] >= count)
			count = mod[MOD_STRUMID] + 1;
	}

	return count;
}

function getModchartKeyCount(p, fallbackKeyCount:Int = 4) {
	var count = fallbackKeyCount > 0 ? fallbackKeyCount : 4;

	try {
		if (PlayState.instance != null && strumLineKeyCounts != null && p >= 0 && p < strumLineKeyCounts.length)
			count = strumLineKeyCounts[p];
	} catch(e:Dynamic) {}

	var runtimeCount = getRuntimeStrumCount(p);
	if (runtimeCount > count) count = runtimeCount;

	var targetCount = getModTargetKeyCount(p);
	if (targetCount > count) count = targetCount;

	return count < 1 ? 1 : count;
}

function reconstructModTable()
{
	var fallbackKeyCount = modchartManagerKeyCount > 0 ? modchartManagerKeyCount : 4;
	modTable = [];
	modchartManagerKeyCounts = [];
	modchartManagerKeyCount = 0;

	for(p in 0...PlayState.SONG.strumLines.length)
	{
		modTable.push([]);
		var keyCount = getModchartKeyCount(p, fallbackKeyCount);
		modchartManagerKeyCounts.push(keyCount);
		if (keyCount > modchartManagerKeyCount)
			modchartManagerKeyCount = keyCount;

		for (i in 0...keyCount)
		{
			modTable[p].push([]);
			for (mod in modifiers)
			{
				if ((mod[MOD_STRUMLINEID] == -1 || mod[MOD_STRUMLINEID] == p) && (mod[MOD_STRUMID] == -1 || mod[MOD_STRUMID] == i))
				{
					modTable[p][i].push(mod); //add modifier to table so it knows which modifiers are gonna be used for each individual strum
				}
			}
		}
	}
}

function clearLegacyModchartShaders()
{
	for(p in 0...strumLines.length)
	{
		if (PlayState.instance != null) {
			if (strumLines.members[p] == null) continue;

			for (strum in strumLines.members[p].members)
				if (strum != null && isPerspectiveShader(strum.shader)) strum.shader = null;

			strumLines.members[p].notes.forEach(function(n) {
				if (n != null && isPerspectiveShader(n.shader)) n.shader = null;
			});
		} else {
			for (strum in strumLines[p])
				if (strum != null && isPerspectiveShader(strum.shader)) strum.shader = null;
		}
	}
}

function rebuildLegacyModchartShaders()
{
	reconstructModTable();
	generateShaderCode();
	clearLegacyModchartShaders();
}

function onPostManiaChange(strumlineID)
{
	if (!initialized)
		return;

	rebuildLegacyModchartShaders();
}

function updateModifers()
{
	for (mod in modifiers)
	{
		if (mod[MOD_AUTODISABLE])
		{
			mod[MOD_ENABLED] = mod[MOD_VALUE] != mod[MOD_DEFAULTVALUE];				
		}

		if (mod[MOD_ENABLED] && mod[MOD_TYPE] == MOD_TYPE_CUSTOM)
		{
			mod[MOD_FUNC](mod); //call modifier function
		}
	}
}




public function initModchart()
{
	initialized = true;
	
	//sortModEvents();
	reconstructModTable();
	//trace("legacy modchartManager: init strumLines=" + strumLines.length + " modifiers=" + modifiers.length + " keyCount=" + modchartManagerKeyCount);


	generateShaderCode();

	for(p in 0...strumLines.length)
	{
		if (PlayState.instance != null) {
			strumLines.members[p].onNoteDelete.add(onDeleteNote);
			for (strum in strumLines.members[p].members) {
				strum.shader = getPerspectiveShader(p, strum.ID);
			}
			for (strum in strumLines.members[p].members) {
				prewarmPerspectiveShaderLane(p, strum.ID);
			}
		} else {
			for (strum in strumLines[p]) {
				strum.shader = getPerspectiveShader(p, strum.ID);
			}
		}


		/*if (PlayState.instance != null) {
			for (i in 0...strumLines.members[p].notes.members.length) {
					createPerspectiveShader(strumLines.members[p].notes.members[i], p, strumLines.members[p].notes.members[i].strumID);
				}
		}*/
	}
	//trace("legacy modchartManager: shader tables=" + modShaderVertTable.length + "x" + (modShaderVertTable.length > 0 ? modShaderVertTable[0].length : 0));

	


	/*createModifier("drunk", 2.0, "
		x += cos(((songPosition*0.001) + (strumID*0.2) + 
			(curPos*0.45)*0.013) * (5.0*0.2)) * 112*0.5 * drunk_value;
	", 0);*/

	/*
	if(debugStuff)
	{
		debugText = new FlxText(0, 0, 0, "Test");
		debugText.size = 48;
		debugText.cameras = [camHUD];
		add(debugText);
	}
	*/


	
}

public function generateShaderCode()
{
	var name = "notePerspective";
	var fragShaderPath = Paths.fragShader(name);
	var vertShaderPath = Paths.vertShader(name);
	var fragCode = Assets.exists(fragShaderPath) ? Assets.getText(fragShaderPath) : null;
	var vertCode = Assets.exists(vertShaderPath) ? Assets.getText(vertShaderPath) : null;

	modShaderVertTable = [];
	modShaderFragTable = [];
	shaderPool = [];
	shaderRuntimeData = new ObjectMap();

	/*
	var numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
	var operators = ["+", "-", "*", "/", "(", ")", "="];
	var warnings = "";
	for (mod in modifiers)
	{
		if (mod[MOD_TYPE] == MOD_TYPE_NOTE || mod[MOD_TYPE] == MOD_TYPE_FRAG)
		{
			var foundBadNumber = false;
			var searching = false;

			var data:String = mod[MOD_FUNC];
			for (i in 0...data.length) //loop through every character
			{
				if (operators.contains(data.charAt(i))) //if its an operator then there could be a number afterwards
				{
					searching = true;
				}

				var number = data.charAt(i);
					
				if (numbers.contains(data.charAt(i)) && searching) //there is a number so lets check
				{
					var bad = true;
					while(true)
					{
						i++; //check next number
						if (numbers.contains(data.charAt(i)) || data.charAt(i) == ".") //if its a number or . then continue
						{
							number += data.charAt(i);
							if (data.charAt(i) == ".")
							{
								bad = false; //if the number contains a . then its all good
							}
						}
						else //break if not a number or .
						{
							searching = false;
							break;
						}
					}

					if (bad) //add to warnings since its bad
					{
						warnings += "\nWARNING: found bad number '" + number + "' in Modifier '" + mod[MOD_NAME] + "'\nIf this is intentional then ignore, otherwise add .0!\n";
					}
				}
				else if (!operators.contains(data.charAt(i)) && data.charAt(i) != " ") //not a number or operator so reset, but ignore spaces
					searching = false;
			}
		}
	}

	if (warnings != "")
		trace(warnings);
	*/

	for(p in 0...PlayState.SONG.strumLines.length) //generate shader code for each strum lane
	{
		modShaderVertTable.push([]);
		modShaderFragTable.push([]);
		shaderPool.push([]);
		var keyCount = p < modchartManagerKeyCounts.length ? modchartManagerKeyCounts[p] : getModchartKeyCount(p);
		for (i in 0...keyCount)
		{
			var modifierUniformsVertCode = "";
			var modifierFunctionsVertCode = "";

			var modifierUniformsFragCode = "";
			var modifierFunctionsFragCode = "";

			modShaderVertTable[p].push(vertCode);
			modShaderFragTable[p].push(fragCode);
			shaderPool[p].push([]);
			for (mod in modTable[p][i]) //loop through each mod
			{
				if (mod[MOD_TYPE] == MOD_TYPE_NOTE)
				{
					//declare uniform
					modifierUniformsVertCode += "uniform float " + mod[MOD_NAME] + "_value;\n";

					//add modifier code
					if (mod[MOD_AUTODISABLE])
					{
						var defaultValue = mod[MOD_DEFAULTVALUE];
						if (!StringTools.contains(defaultValue, "."))
							defaultValue += ".0"; //make sure it has a decimal so the shader knows its a float
			
						modifierFunctionsVertCode += "if (" + mod[MOD_NAME] + "_value != " + (defaultValue) + ")";
						modifierFunctionsVertCode += "{";
						modifierFunctionsVertCode += mod[MOD_FUNC];
						modifierFunctionsVertCode += "}";
					}
					else
					{
						modifierFunctionsVertCode += mod[MOD_FUNC];
					}
				}
				else if (mod[MOD_TYPE] == MOD_TYPE_FRAG)
				{
					//declare uniform
					modifierUniformsFragCode += "uniform float " + mod[MOD_NAME] + "_value;\n";

					//add modifier code
					if (mod[MOD_AUTODISABLE])
					{
						var defaultValue = mod[MOD_DEFAULTVALUE];
						if (!StringTools.contains(defaultValue, "."))
							defaultValue += ".0"; //make sure it has a decimal so the shader knows its a float
			
						modifierFunctionsFragCode += "if (" + mod[MOD_NAME] + "_value != " + (defaultValue) + ")";
						modifierFunctionsFragCode += "{";
						modifierFunctionsFragCode += mod[MOD_FUNC];
						modifierFunctionsFragCode += "}";
					}
					else
					{
						modifierFunctionsFragCode += mod[MOD_FUNC];
					}
				}
			}
			//add modifier code into shader
			modShaderVertTable[p][i] = StringTools.replace(modShaderVertTable[p][i], "#pragma modifierUniforms", modifierUniformsVertCode);
			modShaderVertTable[p][i] = StringTools.replace(modShaderVertTable[p][i], "#pragma modifierFunctions", modifierFunctionsVertCode);

			modShaderFragTable[p][i] = StringTools.replace(modShaderFragTable[p][i], "#pragma modifierUniforms", modifierUniformsFragCode);
			modShaderFragTable[p][i] = StringTools.replace(modShaderFragTable[p][i], "#pragma modifierFunctions", modifierFunctionsFragCode);
		}
	}
}

function postDraw() {
	if (!debugShaderTraceDone && initialized) {
		debugShaderTraceDone = true;
		trace("legacy modchartManager: notePerspective assigned to notes=" + debugShaderAppliedCount);
	}
}

////Modifier Functions/////
public function createModifier(name:String, value:Float, func:Dynamic, strumLineID:Int = -1, strumID = -1, defaultValue:Float = 0.0, autoDisable = true, modType:Int = 0)
{
	if (defaultValue == null)
		defaultValue = 0.0;
	if (autoDisable == null)
		autoDisable = true;
	if (strumLineID == null)
		strumLineID = -1;
	if (strumID == null)
		strumID = -1;
	if (modType == null)
		modType = MOD_TYPE_NOTE;

	var modData = [name, value, func, defaultValue, autoDisable, true, strumLineID, strumID, modType];
	modifiers.push(modData);

	reconstructModTable();
}
/*
public function tweenModifierValue(name:String, newValue:Float, time:Float, easeFunc:Float->Float)
{
	var mod = null;
	for (m in modifiers)
		if (m[MOD_NAME] == name)
			mod = m;

	if (mod == null)
		return; //cant find

	var startValue = mod[MOD_VALUE];
	FlxTween.num(startValue, newValue, time, {onUpdate: function(tween:FlxTween){
		var ting = FlxMath.lerp(startValue, newValue, easeFunc(tween.percent)); //ease properly with lerp
		mod[MOD_VALUE] = ting;
	}, ease: easeFunc, onComplete: function(tween:FlxTween) {
		mod[MOD_VALUE] = newValue;
	}});
}

public function setModifierValue(name:String, newValue:Float)
{
	var mod = null;
	for (m in modifiers)
		if (m[MOD_NAME] == name)
			mod = m;

	if (mod == null)
		return; //cant find

	mod[MOD_VALUE] = newValue;
}

public function ease(beat:Float, timeInBeats:Float, easeName:String, data:String)
{
	var arguments = StringTools.replace(StringTools.trim(data), ' ', '').split(',');

	var time = Conductor.getTimeForStep(beat*4);

	for (i in 0...Math.floor(arguments.length/2))
	{
		var name:String = Std.string(arguments[1 + (i*2)]);
		var value:Float = Std.parseFloat(arguments[0 + (i*2)]);
		if(Math.isNaN(value))
			value = 0;

		modEvents.push([time, EVENT_TYPE_EASE, name, value, easeName, timeInBeats]);
	}
}

public function set(beat:Float, data:String)
{
	var arguments = StringTools.replace(StringTools.trim(data), ' ', '').split(',');

	var time = Conductor.getTimeForStep(beat*4);

	for (i in 0...Math.floor(arguments.length/2))
	{
		var name:String = Std.string(arguments[1 + (i*2)]);
		var value:Float = Std.parseFloat(arguments[0 + (i*2)]);
		if(Math.isNaN(value))
			value = 0;

		modEvents.push([time, EVENT_TYPE_SET, name, value]);
	}
}

public function sortModEvents()
{
	modEvents.sort(function(a, b) {
		if(a[EVENT_TIME] < b[EVENT_TIME]) return -1;
		else if(a[EVENT_TIME] > b[EVENT_TIME]) return 1;
		else return 0;
	 });
}
*/

//fixes for splashes
/*function onNoteHit(event)
{
	if (event.showSplash)
	{
		event.showSplash = false;
		
		//show splash func (but we need to keep the splash sprite for after)
		splashHandler.__grp = splashHandler.getSplashGroup(event.note.splash);
		var splash = splashHandler.__grp.showOnStrum(event.note.__strum);
		splash.shader = event.note.__strum.shader;
		splashHandler.add(splash);
		// max 8 rendered splashes
		while(splashHandler.members.length > 8)
			splashHandler.remove(splashHandler.members[0], true);
	}
}*/
