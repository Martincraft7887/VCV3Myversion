

import haxe.Timer;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;



var fov = 90 * (Math.PI/180);

var focalLength = 1.0 * (1.0 / Math.tan(fov * 0.5));
var perspectiveMatrix:Array<Float> = 
[
    focalLength, 0, 0, 0,
	0, focalLength, 0, 0,
	0, 0, 1.0, 1.0,
	0, 0, 0, 0
];
var viewMatrix:Array<Float> = [];
var shaderFrameUVCache:ObjectMap<Dynamic, Dynamic> = new ObjectMap();

public var eye:Array<Float> = [0, 0, -0.71, 0];
public var lookAt:Array<Float> = [0, 0, 0, 0];
public var up:Array<Float> = [0, 1, 0, 0];

var right:Array<Float> = [1, 0, 0, 0];
var upv:Array<Float> = [0, 1, 0, 0];
var forward:Array<Float> = [0, 0, 1, 0];

function updateViewMatrix()
{
	forward = [(lookAt[0] - eye[0]), (-lookAt[1] - -eye[1]), (lookAt[2] - eye[2]), 0];
	forward = normalize(forward);

	right = cross(up, forward);
	right = normalize(right);
	upv = cross(forward, right);
	var negEye = [-eye[0], eye[1], -eye[2], -eye[3]];
	viewMatrix = 
	[
		right[0], upv[0], forward[0], 0,
		right[1], upv[1], forward[1], 0,
		right[2], upv[2], forward[2], 0,
		dot(right, negEye), dot(upv, negEye), dot(forward, negEye), 1
	];
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




var modShaderVertTable:Array<Dynamic> = [];
var modShaderFragTable:Array<Dynamic> = [];

var shaderPool:Array<Dynamic> = [];
var shaderModValueCache:ObjectMap<Dynamic, StringMap<Float>> = new ObjectMap();

function isPerspectiveShader(shader) {
	return shader != null
		&& shader.data != null
		&& Reflect.field(shader.data, "noteCurPos") != null;
}

function getPerspectiveShader(strumLineID, strumID) {
	var pool = shaderPool[strumLineID][strumID];

	if (pool.length < 1) {
		var shader = new FunkinShader(modShaderFragTable[strumLineID][strumID], modShaderVertTable[strumLineID][strumID]);
		shader.data.vertexID.value = [0, 1, 2, 3];
		return shader;
	} else {
		var shader = pool.pop();
		return shader;
	}
}
function putPerspectiveShader(shader, strumLineID, strumID) {
	var pool = shaderPool[strumLineID][strumID];
	pool.push(shader);
}

function createPerspectiveShader(obj, strumLineID, strumID)
{
	var shader = new FunkinShader(modShaderFragTable[strumLineID][strumID], modShaderVertTable[strumLineID][strumID]);
	
	
	
	shader.data.vertexID.value = [0, 1, 2, 3];
	applyPerspectiveMatrices(shader);
	obj.shader = shader;
}

function applyPerspectiveMatrices(shader):Bool {
	if (shader == null) return false;
	try {
		shader.viewMatrix = viewMatrix;
		shader.perspectiveMatrix = perspectiveMatrix;
		return true;
	} catch(e:Dynamic) {}
	return false;
}


public var modifiers:Array<Dynamic> = [];

public var modTable:Array<Dynamic> = [];


public var MOD_NAME = 0;
public var MOD_VALUE = 1;
public var MOD_FUNC = 2;
public var MOD_DEFAULTVALUE = 3;
public var MOD_AUTODISABLE = 4;
public var MOD_ENABLED = 5;
public var MOD_STRUMLINEID = 6;
public var MOD_STRUMID = 7;
public var MOD_TYPE = 8;

public var MOD_TYPE_NOTE = 0; 
public var MOD_TYPE_CUSTOM = 1; 
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
var debugShaderAppliedCount:Int = 0;
var debugShaderTraceDone:Bool = false;

function voiidDebugTrace(message:String) {
	if (Reflect.field(FlxG.save.data, "voiidDebugLogs") == true)
		trace(message);
}

function postUpdate(elapsed)
{
	if (!initialized)
		return;

	
	

















	
	updateViewMatrix();
	
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
				if (n == null) return;

				if (!isPerspectiveShader(n.shader)) {
					n.shader = getPerspectiveShader(p, n.strumID);
					debugShaderAppliedCount++;
				}
				if (!applyPerspectiveMatrices(n.shader)) {
					n.shader = getPerspectiveShader(p, n.strumID);
					applyPerspectiveMatrices(n.shader);
					debugShaderAppliedCount++;
				}
				n.forceIsOnScreen = true;
				n.shader.songPosition = Conductor.songPosition;
				n.shader.curBeat = Conductor.curBeatFloat;
				n.shader.downscroll = downscroll;
				n.shader.isSustainNote = n.isSustainNote;
				
	
				updateShaderFrameUV(n, n.shader);
	
				var curPos = Conductor.songPosition - n.strumTime;
				var nextCurPos = curPos;
	
				
				if (n.isSustainNote && n.nextNote != null && n.nextNote.isSustainNote) 
					nextCurPos = Conductor.songPosition - n.nextNote.strumTime;
	
				
				if (n.isSustainNote && n.nextSustain == null) 
					nextCurPos = Conductor.songPosition - (n.strumTime + (Conductor.stepCrochet*0.5));
	
				
				if (n.isSustainNote && n.wasGoodHit && curPos >= 0) 
					curPos = 0;
	
	
				
				var noteStrum = getSafeNoteStrum(n, p);
				if (noteStrum == null) return;

				var point = FlxPoint.weak();
				n.getScreenPosition(point, camHUD);
				var strumX = getDynamicFloat(noteStrum, "x", 0);
				var strumY = getDynamicFloat(noteStrum, "y", 0);
				var origin = Reflect.field(n, "origin");
				var offset = Reflect.field(n, "offset");
				var originX = getDynamicFloat(origin, "x", 0);
				var originY = getDynamicFloat(origin, "y", 0);
				var offsetX = getDynamicFloat(offset, "x", 0);
				var offsetY = getDynamicFloat(offset, "y", 0);
				n.shader.screenX = (originX + point.x - offsetX) + strumX;
				if (downscroll)
					n.shader.screenY = (originY + point.y - offsetY) - strumY;
				else
					n.shader.screenY = (originY + point.y - offsetY) + strumY;
				point.put();
	
				
				n.shader.strumID = n.strumID;
				n.shader.strumLineID = p;
				setNoteCurPosUniform(n.shader, curPos, curPos, nextCurPos, nextCurPos);
				n.shader.scrollSpeed = getSafeNoteScrollSpeed(n, p, noteStrum);
				applyModifierValuesToShader(n.shader, p, n.strumID);
			});
		}
	}
}

function getSafeNoteStrum(note, strumLineID) {
	var noteStrum = Reflect.field(note, "__strum");
	if (isValidStrumObject(noteStrum))
		return noteStrum;

	try {
		var line = strumLines.members[strumLineID];
		if (line != null && line.members != null && note.strumID >= 0 && note.strumID < line.members.length) {
			noteStrum = line.members[note.strumID];
			if (isValidStrumObject(noteStrum))
				return noteStrum;
		}
	} catch(e:Dynamic) {}

	return null;
}

function isValidStrumObject(strum):Bool {
	if (strum == null) return false;
	return Reflect.field(strum, "x") != null && Reflect.field(strum, "y") != null;
}

function getSafeNoteScrollSpeed(note, strumLineID, noteStrum):Float {
	try {
		if (noteStrum != null)
			return noteStrum.getScrollSpeed(note);
	} catch(e:Dynamic) {}
	try {
		return strumLines.members[strumLineID].members[note.strumID].getScrollSpeed(note);
	} catch(e2:Dynamic) {}
	return scrollSpeed;
}

function getDynamicFloat(obj, field:String, fallback:Float):Float {
	var value = obj == null ? null : Reflect.field(obj, field);
	if (value == null) return fallback;
	var parsed = Std.parseFloat(Std.string(value));
	return Math.isNaN(parsed) ? fallback : parsed;
}

function updateShaderFrameUV(obj:Dynamic, shader:Dynamic) {
	if (obj == null || shader == null || obj.frame == null) return;
	if (shaderFrameUVCache.exists(obj) && shaderFrameUVCache.get(obj) == obj.frame) return;
	shaderFrameUVCache.set(obj, obj.frame);
	shader.frameUV = [obj.frame.uv.x, obj.frame.uv.y, obj.frame.uv.width, obj.frame.uv.height];
}

function setNoteCurPosUniform(shader:Dynamic, a:Float, b:Float, c:Float, d:Float) {
	if (shader == null || shader.data == null || shader.data.noteCurPos == null) return;
	var values = shader.data.noteCurPos.value;
	if (values == null || values.length < 4) {
		shader.data.noteCurPos.value = [a, b, c, d];
		return;
	}
	values[0] = a;
	values[1] = b;
	values[2] = c;
	values[3] = d;
}

function updateStrum(strum, p) {
	if (!isPerspectiveShader(strum.shader)) {
		strum.shader = getPerspectiveShader(p, strum.ID);
	}
	if (!applyPerspectiveMatrices(strum.shader)) {
		strum.shader = getPerspectiveShader(p, strum.ID);
		applyPerspectiveMatrices(strum.shader);
	}
	strum.shader.songPosition = Conductor.songPosition;
	strum.shader.curBeat = Conductor.curBeatFloat;

	strum.shader.strumID = strum.ID;
	strum.shader.strumLineID = p;
	setNoteCurPosUniform(strum.shader, 0.0, 0.0, 0.0, 0.0);
	strum.shader.scrollSpeed = 0.0;

	updateShaderFrameUV(strum, strum.shader);


	
	var point = FlxPoint.weak();
	strum.getScreenPosition(point, camHUD);
	strum.shader.screenX = strum.origin.x + point.x - strum.offset.x;
	strum.shader.screenY = strum.origin.y + point.y - strum.offset.y;
	point.put();

	strum.shader.downscroll = downscroll;
	strum.shader.isSustainNote = false;

	
	
	
	
	applyModifierValuesToShader(strum.shader, p, strum.ID);
}

function applyModifierValuesToShader(shader, p, strumID) {
	if (shader == null || modTable[p] == null || modTable[p][strumID] == null) return;

	var cache = shaderModValueCache.get(shader);
	if (cache == null) {
		cache = new StringMap();
		shaderModValueCache.set(shader, cache);
	}

	for (mod in modTable[p][strumID])
	{
		var key = mod[MOD_NAME] + "_value";
		var value:Float = mod[MOD_VALUE];
		if (!cache.exists(key) || cache.get(key) != value) {
			shader.hset(key, value);
			cache.set(key, value);
		}
		
		
	}
}

function onDeleteNote(e) {
	putPerspectiveShader(e.note.shader, e.note.strumLine.ID, e.note.strumID);
}

function reconstructModTable()
{
	modTable = [];

	for(p in 0...PlayState.SONG.strumLines.length)
	{
		modTable.push([]);
		if (PlayState.instance != null) {
			modchartManagerKeyCount = strumLineKeyCounts[p];
		}
		for (i in 0...modchartManagerKeyCount)
		{
			modTable[p].push([]);
			for (mod in modifiers)
			{
				if ((mod[MOD_STRUMLINEID] == -1 || mod[MOD_STRUMLINEID] == p) && (mod[MOD_STRUMID] == -1 || mod[MOD_STRUMID] == i))
				{
					modTable[p][i].push(mod); 
				}
			}
		}
	}
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
			mod[MOD_FUNC](mod); 
		}
	}
}




public function initModchart()
{
	initialized = true;
	
	
	reconstructModTable();
	


	generateShaderCode();

	for(p in 0...strumLines.length)
	{
		if (PlayState.instance != null) {
			strumLines.members[p].onNoteDelete.add(onDeleteNote);
			for (strum in strumLines.members[p].members) {
				strum.shader = getPerspectiveShader(p, strum.ID);
			}
		} else {
			for (strum in strumLines[p]) {
				strum.shader = getPerspectiveShader(p, strum.ID);
			}
		}


		




	}
	

	


	




	










	
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

	
























































	for(p in 0...PlayState.SONG.strumLines.length) 
	{
		modShaderVertTable.push([]);
		modShaderFragTable.push([]);
		shaderPool.push([]);
		for (i in 0...modchartManagerKeyCount)
		{
			var modifierUniformsVertCode = "";
			var modifierFunctionsVertCode = "";

			var modifierUniformsFragCode = "";
			var modifierFunctionsFragCode = "";

			modShaderVertTable[p].push(vertCode);
			modShaderFragTable[p].push(fragCode);
			shaderPool[p].push([]);
			for (mod in modTable[p][i]) 
			{
				if (mod[MOD_TYPE] == MOD_TYPE_NOTE)
				{
					
					modifierUniformsVertCode += "uniform float " + mod[MOD_NAME] + "_value;\n";

					
					if (mod[MOD_AUTODISABLE])
					{
						var defaultValue = mod[MOD_DEFAULTVALUE];
						if (!StringTools.contains(defaultValue, "."))
							defaultValue += ".0"; 
			
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
					
					modifierUniformsFragCode += "uniform float " + mod[MOD_NAME] + "_value;\n";

					
					if (mod[MOD_AUTODISABLE])
					{
						var defaultValue = mod[MOD_DEFAULTVALUE];
						if (!StringTools.contains(defaultValue, "."))
							defaultValue += ".0"; 
			
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
		voiidDebugTrace("legacy modchartManager: notePerspective assigned to notes=" + debugShaderAppliedCount);
	}
}


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






























































































