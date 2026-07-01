var doNoteTrail = false;
var black = null;
function postCreate() {

	







































    
	black = new FlxSprite();
	black.cameras = [camHUD];
	black.makeGraphic(1,1,0xFF000000);
	black.setGraphicSize(4000,2000);
	black.updateHitbox();
	black.screenCenter();
	add(black);


	




































	

}
var bursts = [
    128,
    256,
    512,
    656,
    662,
    704,
    768,
    896,
    1024,
    1280,
    1408,
    1424,
    1430,
    1472,
    1520,
    1664
];
var tilts = [
    [656, 20],
    [662, -20],
    [1424, 20],
    [1430, -20]
];

var arrowSpins = [
    [128, 360],
    [192, -360],
    [256, 360, 'y'],
    [320, -360],
	[384, -360, 'y'],
	[448, 360],
    [512, 360, 'x'],
    [544, -360],
    [640, -360, 'x'],
    [672, -360],
    [896, 360],
    [960, -360],
    [1024, 360, 'y'],
    [1088, -360],
	[1120, 360, 'x'],
	[1152, -360, 'y'],
	[1216, -360],
    [1280, 360],
    [1312, -360],
    [1408, -360, 'x'],
    [1440, -360],
	[1472, 360, 'x'],
	[1488, 360, 'x'],
	[1504, 360, 'x'],
    [1536, 360],
    [1568, -360],
    [1600, 360],
	[1616, -360],
    [1632, -360],
    [1664, 360],
];
var shakes = [
    616,744,1384
];

var originalNotePositions = [];

function stepHit() {

   doNoteTrail = false;
    if ( modcharts ) { 
        if ( (curStep >= 614 && curStep < 638) || (curStep >= 655 && curStep < 657) || (curStep >= 661 && curStep < 663) 
        || (curStep >= 743 && curStep < 769) || (curStep >= 1383 && curStep < 1406) 
        || (curStep >= 1423 && curStep < 1425) || (curStep >= 1429 && curStep < 1431) || (curStep >= 1520) ) { 
			doNoteTrail = true;
        }
    }


    var section = Math.floor(curStep/16);
	






























































    if ( modcharts ) { 
		if (curStep == 768 || curStep == 1664) {
			for (s in strumLines) {
				var pos = [];
				for (strum in s.members) {
					strum.moves = true;
					strum.velocity.x = FlxG.random.float(-100, 100);
					strum.velocity.y = FlxG.random.float(0.3, 1) * -500 * (downscroll ? -1 : 1);
					strum.acceleration.y = 800 * (downscroll ? -1 : 1);
					pos.push([strum.x, strum.y]);
				}
				originalNotePositions.push(pos);
			}
		} else if ( curStep == 864 ) {
			var sID = 0;
			for (s in strumLines) {
				var i = 0;
				for (strum in s.members) {
					strum.moves = false;
					strum.velocity.x = 0;
					strum.velocity.y = 0;
					strum.acceleration.y = 0;
					FlxTween.tween(strum, {x: originalNotePositions[sID][i][0],
						y: originalNotePositions[sID][i][1]}, crochet*0.001*32, {ease:FlxEase.expoOut});

					i++;
				}
				sID++;
			}
		}

		
























































    }
}




function onSongStart() {
    black.alpha = 0;
    
    

    
}

var noteTrailCount = 0;
var noteTrailCap = 50;
var trails = [];
function onNoteHit(e) {
	if (!e.note.isSustainNote && doNoteTrail) {
		if (trails[noteTrailCount] == null) {
			trails[noteTrailCount] = new FlxSprite();
			add(trails[noteTrailCount]);
		}
		var spr = trails[noteTrailCount];
		var source = e.note;


		spr.setPosition(e.note.__strum.x, e.note.__strum.y);
		spr.frames = source.frames;
		spr.animation.copyFrom(source.animation);
		spr.visible = source.visible;
		spr.alpha = source.alpha;
		spr.antialiasing = source.antialiasing;
		spr.scale.set(source.scale.x, source.scale.y);
		spr.updateHitbox();
		spr.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);
		spr.cameras = [camHUD];
		spr.shader = source.shader;
		
		spr.alpha = 0.6;
		FlxTween.tween(spr, {y: spr.y - 250}, crochet*0.001*16);
		FlxTween.tween(spr, {alpha: 0}, crochet*0.001*16, {ease:FlxEase.expoInOut});

		noteTrailCount++;
		if (noteTrailCount > noteTrailCap) noteTrailCount = 0;
	}
}





































