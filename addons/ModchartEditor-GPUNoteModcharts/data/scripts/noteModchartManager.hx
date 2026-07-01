//

import Camera3D;
import ModifierTable;
import haxe.ds.ObjectMap;
public var modchartCamera = new Camera3D();
public var modTable:ModifierTable = new ModifierTable();
var shaderFrameUVCache:ObjectMap<Dynamic, Dynamic> = new ObjectMap();

var modchartInitialized = false;

public var modchartManagerKeyCount:Int = 4;
public var useNotePaths = false;
public var notePathGroup = [];
function postUpdate(elapsed)
{
	if (!modchartInitialized)
		return;

	//modchartCamera.position.x = Math.sin(Conductor.songPosition * 0.001);
	//modchartCamera.position.z = Math.cos(Conductor.songPosition * 0.001);

	//updateModifers();
	modchartCamera.updateViewMatrix();
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
				if (n.shader == null) {
					n.shader = modTable.getShader(p, n.strumID);
				}
				n.forceIsOnScreen = true;
				//n.shader.viewMatrix = modchartCamera.viewMatrix;
				//n.shader.songPosition = Conductor.songPosition;
				//n.shader.curBeat = Conductor.curBeatFloat;
				//n.shader.downscroll = downscroll;
				n.shader.isSustainNote = n.isSustainNote;
				//if (n.isSustainNote)
	
				updateShaderFrameUV(n, n.shader);
	
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
				n.shader.screenX = (n.origin.x + point.x - n.offset.x) + n.__strum.x;
				if (downscroll)
					n.shader.screenY = (n.origin.y + point.y - n.offset.y) - n.__strum.y;
				else
					n.shader.screenY = (n.origin.y + point.y - n.offset.y) + n.__strum.y;
				point.put();
	
				
				n.shader.strumID = n.strumID;
				n.shader.strumLineID = p;
				setNoteCurPosUniform(n.shader, curPos, curPos, nextCurPos, nextCurPos);
				n.shader.scrollSpeed = strumLines.members[p].members[n.strumID].getScrollSpeed(n);
			});
		}
	}
}
function updateStrum(strum, p) {
	if (strum.shader == null) {
		strum.shader = modTable.getShader(p, strum.ID);
	}
	
	strum.shader.viewMatrix = modchartCamera.viewMatrix;
	strum.shader.perspectiveMatrix = modchartCamera.perspectiveMatrix;
	strum.shader.songPosition = Conductor.songPosition;
	strum.shader.curBeat = Conductor.curBeatFloat;

	strum.shader.strumID = strum.ID;
	strum.shader.strumLineID = p;
	setNoteCurPosUniform(strum.shader, 0.0, 0.0, 0.0, 0.0);
	strum.shader.scrollSpeed = 0.0;

	updateShaderFrameUV(strum, strum.shader);


	//calculate screen position for rotation and scaling inside shader
	var point = FlxPoint.weak();
	strum.getScreenPosition(point, camHUD);
	strum.shader.screenX = strum.origin.x + point.x - strum.offset.x;
	strum.shader.screenY = strum.origin.y + point.y - strum.offset.y;
	point.put();

	strum.shader.downscroll = downscroll;
	strum.shader.isSustainNote = false;

	modTable.applyValuesToShader(strum.shader, p, strum.ID);
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

function onDeleteNote(e) {
	modTable.putShader(e.note.shader, e.note.strumLine.ID, e.note.strumID);
}

public function initModchart()
{
	modchartManagerKeyCount = 0;

for (p in 0...strumLines.length)
{
    var count = 0;

    if (PlayState.instance != null)
        count = strumLines.members[p].members.length;
    else
        count = strumLines[p].length;

    if (count > modchartManagerKeyCount)
        modchartManagerKeyCount = count;
}
	modTable.init();
	if (!modchartInitialized) {
		var segmentsToMake = Math.ceil((3500 / PlayState.SONG.scrollSpeed) / (Conductor.stepCrochet));

		for(p in 0...strumLines.length) {
			if (PlayState.instance != null) {
				strumLines.members[p].onNoteDelete.add(onDeleteNote);
			}

			if (useNotePaths) {
				notePathGroup.push([]);
				if (PlayState.instance != null) {
					shitarray = strumLines.members[p].members;
				} else {
					shitarray = strumLines[p];
				}
				for (i => strum in shitarray) {
					notePathGroup[p].push([]);

					var curTime = 0;
					for (l in 0...segmentsToMake) {
						var lineSpr = new FlxSprite(strum.x + 50, 56 + strum.y + (curTime * 0.45 * PlayState.SONG.scrollSpeed));
						lineSpr.makeGraphic(1,1);
						lineSpr.setGraphicSize(10, Math.ceil(Conductor.stepCrochet * 0.45 * PlayState.SONG.scrollSpeed));
						lineSpr.updateHitbox();
						lineSpr.cameras = [camHUD];
						lineSpr.forceIsOnScreen = true;
						notePathGroup[p][i].push(lineSpr);
						insert(0, lineSpr);
						curTime += Conductor.stepCrochet;
					}
				}
			}
		}
		modchartInitialized = true;
	}
	if (useNotePaths) updateNotePaths();
}

public function updateNotePaths() {
	for(p in 0...strumLines.length) {
		var shitarray = [];
		if (PlayState.instance != null) {
			shitarray = strumLines.members[p].members;
		} else {
			shitarray = strumLines[p];
		}
		for (i => strum in shitarray) {

			var curTime = 0;
			for (lineSpr in notePathGroup[p][i]) {
				var n = lineSpr;
				n.shader = modTable.getShader(p, i);
				n.shader.isSustainNote = true;

				updateShaderFrameUV(n, n.shader);
				var point = FlxPoint.weak();
				n.getScreenPosition(point, camHUD);
				n.shader.screenX = (n.origin.x + point.x - n.offset.x);
				if (downscroll)
					n.shader.screenY = (n.origin.y + point.y - n.offset.y);// - strum.y;
				else
					n.shader.screenY = (n.origin.y + point.y - n.offset.y);// + strum.y;
				point.put();

				var time = -curTime;
				var nextTime = -(curTime + Conductor.stepCrochet);

				n.shader.strumID = i;
				n.shader.strumLineID = p;
				if (downscroll) {
					setNoteCurPosUniform(n.shader, nextTime, nextTime, time, time);
				} else {
					setNoteCurPosUniform(n.shader, time, time, nextTime, nextTime);
				}
				
				n.shader.scrollSpeed = PlayState.SONG.scrollSpeed;

				curTime += Conductor.stepCrochet;
			}

		}
	}
}

//fixes for splashes
function getSplashShaderFloat(shader:Dynamic, name:String, fallback:Float = 0):Float {
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

function getSplashVisualCenterX(strum:Dynamic):Float {
	if (strum == null) return FlxG.width * 0.5;

	var center = strum.x + (strum.width * 0.5);
	var shader = Reflect.field(strum, "shader");
	if (shader != null) {
		var shaderCenter = getSplashShaderFloat(shader, "screenX", Math.NaN);
		if (!Math.isNaN(shaderCenter))
			center = shaderCenter;
	}
	return center;
}

function getSplashVisualCenterY(strum:Dynamic):Float {
	if (strum == null) return FlxG.height * 0.5;

	var center = strum.y + (strum.height * 0.5);
	var shader = Reflect.field(strum, "shader");
	if (shader != null) {
		var shaderCenter = getSplashShaderFloat(shader, "screenY", Math.NaN);
		if (!Math.isNaN(shaderCenter))
			center = shaderCenter;
	}
	return center;
}

function onNoteHit(event)
{
	if (event.showSplash)
	{
		event.showSplash = false;
		
		//show splash func (but we need to keep the splash sprite for after)
		splashHandler.__grp = splashHandler.getSplashGroup(event.note.splash);
		var splash = splashHandler.__grp.showOnStrum(event.note.__strum);
		if (splash == null) return;
		splash.shader = event.note.__strum.shader;
		splash.setPosition(
			getSplashVisualCenterX(event.note.__strum) - (splash.width / 2),
			getSplashVisualCenterY(event.note.__strum) - (splash.height / 2));
		splashHandler.add(splash);
		// max 8 rendered splashes
		while(splashHandler.members.length > 8)
			splashHandler.remove(splashHandler.members[0], true);
	}
}
